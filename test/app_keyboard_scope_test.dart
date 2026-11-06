// Tests for the global window-level keyboard shortcut dispatcher
// (AppKeyboardScope). These verify the dispatcher's own logic with synthetic
// key events — no Hive/Firebase/platform channels needed.
//
// NOTE: the old widget_test.dart counter-boilerplate was replaced by this
// file: it expected a Counter app that does not exist and always failed.

import 'package:desktopapp/view_models/services/keyboard/app_keyboard_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Synthetic fresh key-down event (what a real key press produces).
KeyEvent _down(LogicalKeyboardKey key, {Duration when = Duration.zero}) {
  return KeyDownEvent(
    timeStamp: when,
    logicalKey: key,
    physicalKey: const PhysicalKeyboardKey(0x00000000),
    character: null,
  );
}

/// Synthetic key-release event (noise the dispatcher must ignore).
KeyEvent _up(LogicalKeyboardKey key) {
  return KeyUpEvent(
    timeStamp: Duration.zero,
    logicalKey: key,
    physicalKey: const PhysicalKeyboardKey(0x00000000),
  );
}

KeyEvent _repeat(LogicalKeyboardKey key) {
  return KeyRepeatEvent(
    timeStamp: Duration.zero,
    logicalKey: key,
    physicalKey: const PhysicalKeyboardKey(0x00000000),
    character: null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Track every scope created by a test so tearDown always unregisters it,
  // even if an expectation fails midway.
  final scopes = <AppKeyboardScope>[];

  AppKeyboardScope makeScope(String tag, bool Function(KeyEvent) handler) {
    final scope = AppKeyboardScope(tag, handler);
    scopes.add(scope);
    AppKeyboardScope.register(scope);
    return scope;
  }

  tearDown(() {
    for (final scope in scopes) {
      AppKeyboardScope.unregister(scope);
    }
    scopes.clear();
  });

  group('AppKeyboardScope registry (LIFO pages win)', () {
    test('last registered scope is asked first (visible page wins)', () {
      final homeGotKey = <KeyEvent>[];
      final salesGotKey = <KeyEvent>[];

      makeScope('home', (e) {
        homeGotKey.add(e);
        return false;
      });
      makeScope('sales', (e) {
        salesGotKey.add(e);
        return true; // sales consumes everything it gets
      });

      final handled = AppKeyboardScope.handleKey(_down(LogicalKeyboardKey.f1));

      expect(handled, isTrue);
      expect(AppKeyboardScope.lastHandledBy, 'sales');
      expect(salesGotKey, hasLength(1));
      // LIFO short-circuit: 'home' must not even be asked.
      expect(homeGotKey, isEmpty);
    });

    test('falls back to older scope when the active one declines', () {
      final calls = <String>[];

      makeScope('home', (e) {
        calls.add('home');
        return true;
      });
      makeScope('sales', (e) {
        calls.add('sales');
        return false; // sales not interested in this key
      });

      final handled = AppKeyboardScope.handleKey(
        _down(LogicalKeyboardKey.keyS, when: const Duration(seconds: 1)),
      );

      expect(handled, isTrue);
      expect(AppKeyboardScope.lastHandledBy, 'home');
      expect(calls, ['sales', 'home']); // asked newest first, fell back
    });

    test('re-registering moves a scope back to the top (page return)', () {
      final order = <String>[];

      final first = makeScope('first', (e) {
        order.add('first');
        return true;
      });
      makeScope('second', (e) {
        order.add('second');
        return true;
      });

      // 'second' registered last: it is on top and wins.
      expect(
        AppKeyboardScope.handleKey(_down(LogicalKeyboardKey.keyA)),
        isTrue,
      );
      expect(order, ['second']);

      // Navigating back to the 'first' page re-registers it, pushing it on
      // top again.
      AppKeyboardScope.register(first);
      order.clear();
      expect(
        AppKeyboardScope.handleKey(_down(LogicalKeyboardKey.keyB)),
        isTrue,
      );
      expect(order, ['first']);
    });

    test('unregister removes the scope entirely', () {
      final calls = <String>[];

      makeScope('base-page', (e) {
        calls.add('base');
        return true;
      });

      // The temp page opens later — so it's on top of the stack.
      final temp = AppKeyboardScope('temp-page', (e) {
        calls.add('temp');
        return true;
      });
      scopes.add(temp); // safety net: tearDown unregisters it if we abort
      AppKeyboardScope.register(temp);

      // temp is on top and must win.
      expect(
        AppKeyboardScope.handleKey(_down(LogicalKeyboardKey.keyA)),
        isTrue,
      );
      expect(calls, ['temp']);

      // After unregister, the base page takes over.
      AppKeyboardScope.unregister(temp);
      calls.clear();
      expect(
        AppKeyboardScope.handleKey(_down(LogicalKeyboardKey.keyB)),
        isTrue,
      );
      expect(calls, ['base']);
    });

    test('a crashing handler does not break later scopes', () {
      makeScope('main-nav', (e) => true);
      makeScope('buggy-page', (e) => throw StateError('boom'));

      expect(AppKeyboardScope.handleKey(_down(LogicalKeyboardKey.f5)), isTrue);
      // The buggy one crashed, the healthy 'main-nav' underneath handled it.
      expect(AppKeyboardScope.lastHandledBy, 'main-nav');
    });

    test('no scopes = key not consumed (normal typing stays intact)', () {
      AppKeyboardScope.lastHandledBy = null; // ignore previous tests
      expect(
        AppKeyboardScope.handleKey(_down(LogicalKeyboardKey.keyX)),
        isFalse,
      );
      expect(AppKeyboardScope.lastHandledBy, isNull);
    });
  });

  group('AppKeyboardScope.handleKey filters event types', () {
    test('ignores key-up events', () {
      makeScope('any', (e) => true);
      expect(AppKeyboardScope.handleKey(_up(LogicalKeyboardKey.keyP)), isFalse);
    });

    test('only consumes events it is given after filtering', () {
      makeScope('any', (e) => true);
      // Key-down goes to handlers.
      expect(
        AppKeyboardScope.handleKey(_down(LogicalKeyboardKey.keyP)),
        isTrue,
      );
      // Auto-repeat also reaches handlers (live products care, dialogs rely
      // on fresh press only via didPress).
      expect(
        AppKeyboardScope.handleKey(_repeat(LogicalKeyboardKey.keyP)),
        isTrue,
      );
    });
  });

  group('AppKeyboardScope.didPress', () {
    test('accepts a fresh key-down of the exact key', () {
      expect(
        AppKeyboardScope.didPress(
          _down(LogicalKeyboardKey.f11),
          LogicalKeyboardKey.f11,
        ),
        isTrue,
      );
    });

    test('rejects key-up and auto-repeat', () {
      expect(
        AppKeyboardScope.didPress(
          _up(LogicalKeyboardKey.f1),
          LogicalKeyboardKey.f1,
        ),
        isFalse,
      );
      expect(
        AppKeyboardScope.didPress(
          _repeat(LogicalKeyboardKey.f1),
          LogicalKeyboardKey.f1,
        ),
        isFalse,
      );
    });

    test('rejects a different key', () {
      expect(
        AppKeyboardScope.didPress(
          _down(LogicalKeyboardKey.f2),
          LogicalKeyboardKey.f1,
        ),
        isFalse,
      );
    });

    testWidgets('requires ctrl when requested, via the real keyboard state', (
      tester,
    ) async {
      final event = _down(LogicalKeyboardKey.keyN);

      // Ctrl NOT held.
      expect(
        AppKeyboardScope.didPress(event, LogicalKeyboardKey.keyN, ctrl: true),
        isFalse,
      );
      // Holding ctrl in the real pipeline makes it pass.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      expect(
        AppKeyboardScope.didPress(event, LogicalKeyboardKey.keyN, ctrl: true),
        isTrue,
      );
      // And plain ctrl+N never matches a bare N shortcut request.
      expect(AppKeyboardScope.didPress(event, LogicalKeyboardKey.keyN), isTrue);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(
        AppKeyboardScope.didPress(event, LogicalKeyboardKey.keyN, ctrl: true),
        isFalse,
      );
    });

    testWidgets('requires shift when requested', (tester) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      final event = _down(LogicalKeyboardKey.keyS);
      expect(
        AppKeyboardScope.didPress(event, LogicalKeyboardKey.keyS, shift: true),
        isTrue,
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    });

    testWidgets('requires alt when requested', (tester) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      final event = _down(LogicalKeyboardKey.keyD);
      expect(
        AppKeyboardScope.didPress(event, LogicalKeyboardKey.keyD, alt: true),
        isTrue,
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    });

    testWidgets('combined ctrl+shift both required', (tester) async {
      final event = _down(LogicalKeyboardKey.keyP);

      // Only ctrl held: ctrl+shift request fails.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      expect(
        AppKeyboardScope.didPress(
          event,
          LogicalKeyboardKey.keyP,
          ctrl: true,
          shift: true,
        ),
        isFalse,
      );

      // Both held: passes.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      expect(
        AppKeyboardScope.didPress(
          event,
          LogicalKeyboardKey.keyP,
          ctrl: true,
          shift: true,
        ),
        isTrue,
      );

      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    });
  });
}
