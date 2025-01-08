import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

/// This class is used to show toast without context for messages/errors
class Toaster {
  /*
  * Modify global config
  */
  static ToasterConfig _defaultConfig = ToasterConfig();
  static void setDefaultConfig(ToasterConfig config) {
    _defaultConfig = config;
  }

  static void show(String message, Color color, IconData icon, {ToasterConfig? config}) {
    BotToast.showCustomText(
      onlyOne: true,
      wrapToastAnimation: (controller, cancel, child) {
        // From top to bottom, from small to large
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: controller,
            curve: Curves.easeOut,
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, -0.5), // Start above the widget's initial position
              end: Offset(0, 0.2),      // End at its original position
            ).animate(CurvedAnimation(
              parent: controller,
              curve: Curves.easeOut,
            )),
            child: child,
          ),
        );
      },
      // animationDuration: const Duration(seconds: 3),
      // animationReverseDuration: const Duration(seconds: 3),
      duration: const Duration(seconds: 3),
      align: config?.alignment ?? _defaultConfig.alignment,
      clickClose: true,
      toastBuilder: (cancel) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: color.withOpacity(0.95),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void success(String message) async {
    show(message, Colors.green, CupertinoIcons.check_mark_circled);
    await Haptics.canVibrate()
        ? await Haptics.vibrate(HapticsType.success)
        : null;
  }

  static void error(String message) async {
    show(message, Colors.red, CupertinoIcons.xmark_circle);
    await Haptics.canVibrate()
        ? await Haptics.vibrate(HapticsType.error)
        : null;
  }

  static void warning(String message) async {
    show(message, Colors.orange, CupertinoIcons.exclamationmark_triangle);
    await Haptics.canVibrate()
        ? await Haptics.vibrate(HapticsType.warning)
        : null;
  }

  static void info(String message) async {
    show(message, Colors.blue, CupertinoIcons.info);
    await Haptics.canVibrate()
        ? await Haptics.vibrate(HapticsType.rigid)
        : null;
  }
}

class ToasterConfig{
  final Alignment alignment;

  const ToasterConfig({
    this.alignment = Alignment.topCenter,
  });
}