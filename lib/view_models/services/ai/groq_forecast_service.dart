import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../models/finance_forecast.dart';
import '../../../res/app_url/app_url.dart';

/// Produces a finance forecast from monthly history.
///
/// Primary path: calls Groq's OpenAI-compatible chat-completions API and asks
/// for the next few months of sales/expenses plus a written insight. If the
/// key isn't configured, the network fails, or the response can't be parsed,
/// it falls back to a deterministic local trend projection so the dashboard
/// always has something to show — online or off.
class GroqForecastService {
  /// True when a real Groq key has been supplied in the (gitignored) config.
  static bool get isConfigured {
    final k = AppUrl.groqApiKey.trim();
    return k.isNotEmpty && k != 'YOUR_GROQ_API_KEY';
  }

  /// Builds a forecast for [monthsAhead] months from [history] (oldest→newest).
  static Future<ForecastResult> forecast(
    List<MonthlyPoint> history, {
    int monthsAhead = 3,
  }) async {
    if (history.isEmpty) {
      return ForecastResult(
        history: history,
        forecast: const [],
        insights: 'Not enough sales history yet to forecast. Record a few '
            'months of bills and check back.',
        usedAi: false,
      );
    }

    if (isConfigured) {
      try {
        final ai = await _forecastWithGroq(history, monthsAhead);
        if (ai != null) return ai;
      } catch (e) {
        debugPrint('Groq forecast failed, using local fallback: $e');
      }
    }
    return _forecastLocally(history, monthsAhead);
  }

  // ------------------------------------------------------------------ Groq

  static Future<ForecastResult?> _forecastWithGroq(
    List<MonthlyPoint> history,
    int monthsAhead,
  ) async {
    final historyJson = history
        .map((p) => {
              'month': p.label,
              'sales': p.sales.round(),
              'expenses': p.expenses.round(),
            })
        .toList();

    final nextLabels = _futureMonths(history.last.month, monthsAhead)
        .map((d) => DateFormat('MMM yyyy').format(d))
        .toList();

    final systemPrompt =
        'You are a retail finance analyst. Given monthly sales and expenses '
        '(currency Rs.), project the next $monthsAhead months and give one '
        'short, practical insight. Respond ONLY with strict JSON of the form: '
        '{"forecast":[{"month":"<label>","sales":<number>,"expenses":<number>}],'
        '"insights":"<2-3 sentences>"}. Use exactly these month labels in order: '
        '${nextLabels.join(', ')}.';

    final userPrompt = 'Monthly history (oldest first): '
        '${jsonEncode(historyJson)}';

    final response = await http
        .post(
          Uri.parse(AppUrl.groqBaseUrl),
          headers: {
            'Authorization': 'Bearer ${AppUrl.groqApiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': AppUrl.groqModel,
            'temperature': 0.2,
            'response_format': {'type': 'json_object'},
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      debugPrint('Groq HTTP ${response.statusCode}: ${response.body}');
      return null;
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = decoded['choices']?[0]?['message']?['content'] as String?;
    if (content == null) return null;

    final parsed = jsonDecode(content) as Map<String, dynamic>;
    final rawForecast = parsed['forecast'];
    final insights = (parsed['insights'] as String?)?.trim() ?? '';
    if (rawForecast is! List || rawForecast.isEmpty) return null;

    final futureMonths = _futureMonths(history.last.month, monthsAhead);
    final forecast = <MonthlyPoint>[];
    for (var i = 0; i < rawForecast.length && i < futureMonths.length; i++) {
      final item = rawForecast[i];
      if (item is! Map) continue;
      final sales = (item['sales'] as num?)?.toDouble() ?? 0;
      final expenses = (item['expenses'] as num?)?.toDouble() ?? 0;
      forecast.add(MonthlyPoint(
        month: futureMonths[i],
        label: DateFormat('MMM yyyy').format(futureMonths[i]),
        sales: sales < 0 ? 0 : sales,
        expenses: expenses < 0 ? 0 : expenses,
      ));
    }
    if (forecast.isEmpty) return null;

    return ForecastResult(
      history: history,
      forecast: forecast,
      insights: insights.isEmpty
          ? 'AI projected the next $monthsAhead months from your recent trend.'
          : insights,
      usedAi: true,
    );
  }

  // ----------------------------------------------------------------- local

  /// Deterministic fallback: least-squares linear trend on sales and expenses,
  /// floored at zero, plus a rule-based insight. Runs entirely offline.
  static ForecastResult _forecastLocally(
    List<MonthlyPoint> history,
    int monthsAhead,
  ) {
    final sales = history.map((p) => p.sales).toList();
    final expenses = history.map((p) => p.expenses).toList();

    final salesTrend = _linearTrend(sales);
    final expenseTrend = _linearTrend(expenses);

    final futureMonths = _futureMonths(history.last.month, monthsAhead);
    final n = history.length;
    final forecast = <MonthlyPoint>[];
    for (var i = 0; i < futureMonths.length; i++) {
      final x = (n + i).toDouble();
      forecast.add(MonthlyPoint(
        month: futureMonths[i],
        label: DateFormat('MMM yyyy').format(futureMonths[i]),
        sales: _floor0(salesTrend.intercept + salesTrend.slope * x),
        expenses: _floor0(expenseTrend.intercept + expenseTrend.slope * x),
      ));
    }

    return ForecastResult(
      history: history,
      forecast: forecast,
      insights: _localInsight(history, forecast, salesTrend.slope),
      usedAi: false,
    );
  }

  static String _localInsight(
    List<MonthlyPoint> history,
    List<MonthlyPoint> forecast,
    double salesSlope,
  ) {
    final dir = salesSlope > 1
        ? 'trending up'
        : (salesSlope < -1 ? 'trending down' : 'roughly flat');
    final projected =
        forecast.fold(0.0, (s, p) => s + p.sales).round();
    final profit = forecast.fold(0.0, (s, p) => s + p.netProfit).round();
    return 'Based on your recent months, sales are $dir. Estimated sales over '
        'the next ${forecast.length} months are about Rs.$projected with a '
        'projected net profit near Rs.$profit. (Local estimate — add a Groq API '
        'key for AI-driven forecasting.)';
  }

  // --------------------------------------------------------------- helpers

  static List<DateTime> _futureMonths(DateTime last, int count) {
    return List.generate(
      count,
      (i) => DateTime(last.year, last.month + i + 1, 1),
    );
  }

  static double _floor0(double v) => v < 0 ? 0 : v;

  static _Trend _linearTrend(List<double> ys) {
    final n = ys.length;
    if (n == 1) return _Trend(intercept: ys.first, slope: 0);
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    for (var i = 0; i < n; i++) {
      final x = i.toDouble();
      sumX += x;
      sumY += ys[i];
      sumXY += x * ys[i];
      sumXX += x * x;
    }
    final denom = (n * sumXX) - (sumX * sumX);
    if (denom == 0) return _Trend(intercept: sumY / n, slope: 0);
    final slope = ((n * sumXY) - (sumX * sumY)) / denom;
    final intercept = (sumY - slope * sumX) / n;
    return _Trend(intercept: intercept, slope: slope);
  }
}

class _Trend {
  final double intercept;
  final double slope;
  const _Trend({required this.intercept, required this.slope});
}
