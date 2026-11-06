import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Global keyboard-shortcut dispatcher.
///
/// Every shortcut in the app is routed through [handleKey], which is added to
/// `HardwareKeyboard` once in `main()`. Unlike `CallbackShortcuts` (which only
/// fires while its focus subtree happens to hold the primary focus), a
/// HardwareKeyboard handler receives every key event the app window receives —
/// so the shortcuts work from anywhere while the software is open, and the
/// window consumes them so they never trigger another app.
///
/// Order of dispatch (first handler to return `true` consumes the key):
///   1. The ACTIVE PAGE's [AppKeyboardScope] (registered in a page's
///      `initState`, removed in `dispose`) — LIFO, so the page visible on
///      screen wins.
///   2. Nothing else. Keys are not consumed unless a handler is active, so
///      normal focus behaviour (text typing, tab focus) is untouched.
///
/// Usage in a page:
/// ```dart
/// late final AppKeyboardScope _keys = AppKeyboardScope('bills', (e) {
///   if (AppKeyboardScope.didPress(e, LogicalKeyboardKey.keyP, ctrl: true)) {
///     _printSelectedBill(context);
///     return true; // consumed
///   }
///   return false;  // not ours — let the rest of the system handle it
/// });
///
/// @override
/// void initState() { super.initState(); AppKeyboardScope.register(_keys); }
/// @override
/// void dispose() { AppKeyboardScope.unregister(_keys); super.dispose(); }
/// ```
class AppKeyboardScope {
  /// Human-readable identifier for logs/("which page owns this").
  final String tag;

  /// Return `true` when the key event is handled by this scope.
  final bool Function(KeyEvent event) handler;

  AppKeyboardScope(this.tag, this.handler);

  static final List<AppKeyboardScope> _scopes = <AppKeyboardScope>[];

  /// Tracks which scope consumed the last key (for debugging via logging).
  static String? lastHandledBy;

  static void register(AppKeyboardScope scope) {
    _scopes.remove(scope);
    _scopes.add(scope);
  }

  static void unregister(AppKeyboardScope scope) {
    _scopes.remove(scope);
  }

  /// Window-level key handler. Installed once in `main()`:
  /// `HardwareKeyboard.instance.addHandler(AppKeyboardScope.handleKey);`
  static bool handleKey(KeyEvent event) {
    // Only key-down (and autorepeat) trigger actions — key-up is noise.
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    for (final scope in _scopes.reversed) {
      try {
        if (scope.handler(event)) {
          lastHandledBy = scope.tag;
          return true;
        }
      } catch (e, st) {
        debugPrint('Keyboard scope "${scope.tag}" error: $e\n$st');
      }
    }
    return false;
  }

  /// Convenience predicate: returns true if [event] is a fresh key-down of
  /// [key] (with optional modifiers). Only accepts a fresh key-down, so
  /// holding a key doesn't repeat actions (e.g. auto-repeat must not pop
  /// several print dialogs in a row).
  static bool didPress(
    KeyEvent event,
    LogicalKeyboardKey key, {
    bool ctrl = false,
    bool shift = false,
    bool alt = false,
  }) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != key) return false;
    final keyboard = HardwareKeyboard.instance;
    if (ctrl && !keyboard.isControlPressed) return false;
    if (shift && !keyboard.isShiftPressed) return false;
    if (alt && !keyboard.isAltPressed) return false;
    return true;
  }
}
