import 'package:flutter/widgets.dart';

/// Llama [fn] solo si el [State] sigue montado tras un frame.
extension AsyncSafety on State {
  void safePostFrame(VoidCallback fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      fn();
    });
  }
}