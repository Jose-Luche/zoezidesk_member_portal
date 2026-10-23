import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// Raises the app's screen brightness while a QR code is shown, so the
/// front-desk scanner reads it reliably. Only the app window changes; the
/// system setting is untouched and restored on exit.
abstract interface class BrightnessControl {
  Future<void> boost();
  Future<void> restore();
}

class ScreenBrightnessControl implements BrightnessControl {
  const ScreenBrightnessControl();

  @override
  Future<void> boost() async {
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(1.0);
    } catch (_) {
      // Not supported on this device: the QR still shows, just dimmer.
    }
  }

  @override
  Future<void> restore() async {
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (_) {}
  }
}

final brightnessControlProvider =
    Provider<BrightnessControl>((_) => const ScreenBrightnessControl());

/// Full brightness while [child] is on screen; restored when it leaves or
/// the app goes to the background.
class BrightnessBoost extends ConsumerStatefulWidget {
  const BrightnessBoost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BrightnessBoost> createState() => _BrightnessBoostState();
}

class _BrightnessBoostState extends ConsumerState<BrightnessBoost> with WidgetsBindingObserver {
  late final BrightnessControl _control = ref.read(brightnessControlProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _control.boost();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _control.boost();
    } else if (state == AppLifecycleState.paused) {
      _control.restore();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _control.restore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
