import 'package:flutter/foundation.dart';

enum ShellTab { home, categories, cart, account }

/// Lets any screen switch the bottom-navigation tab
/// (e.g. "Buy now" → Cart tab, "Continue shopping" → Home tab).
class ShellController extends ChangeNotifier {
  ShellTab _tab = ShellTab.home;
  ShellTab get tab => _tab;

  void goTo(ShellTab tab) {
    if (_tab == tab) return;
    _tab = tab;
    notifyListeners();
  }
}
