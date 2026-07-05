import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/rapper.dart';
import '../../view_models/providers/expense_provider.dart';
import 'responsive_views/expense_desktop_view.dart';
import 'responsive_views/expense_mobile_view.dart';

class ExpensesView extends ConsumerStatefulWidget {
  final VoidCallback? openDrawer;

  const ExpensesView({super.key, this.openDrawer});

  @override
  ConsumerState<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends ConsumerState<ExpensesView> {
  @override
  void initState() {
    super.initState();
    // Load expenses when view is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expenseProvider.notifier).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveWrapper(
        mobile: ExpenseMobileView(openDrawer: widget.openDrawer ?? () {}),
        tablet: ExpenseDesktopView(openDrawer: widget.openDrawer),
        desktop: ExpenseDesktopView(openDrawer: widget.openDrawer),
      ),
    );
  }
}
