import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

enum ToastType { success, error, warning, info, cancel }

class ToastService {
  static const Duration _defaultDuration = Duration(seconds: 3);
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const ToastificationStyle _defaultStyle = ToastificationStyle.flat;
  static const Alignment _defaultAlignment = Alignment.topRight;

  static void show({
    required BuildContext context,
    required String title,
    String? description,
    ToastType type = ToastType.success,
    ToastificationStyle? style,
    Duration? autoCloseDuration,
    IconData? icon,
    Color? primaryColor,
    Color? backgroundColor,
    Color? foregroundColor,
    bool? showIcon,
    bool? showProgressBar,
    bool? dragToClose,
    VoidCallback? onTap,
    VoidCallback? onCloseButtonTap,
    VoidCallback? onAutoCompleteCompleted,
  }) {
    final config = _getConfigForType(type);

    toastification.show(
      context: context,
      type: _mapToToastificationType(type),
      style: style ?? _defaultStyle,
      autoCloseDuration: autoCloseDuration ?? _defaultDuration,
      title: Text(
        title,
        style: TextStyle(
          color: config.foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      description: description != null
          ? RichText(
              text: TextSpan(
                text: description,
                style: TextStyle(color: config.foregroundColor),
              ),
            )
          : null,
      animationDuration: _animationDuration,
      animationBuilder: (context, animation, alignment, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      icon: Icon(config.icon, color: config.foregroundColor),
      showIcon: showIcon ?? true,
      primaryColor: config.primaryColor,
      backgroundColor: config.backgroundColor,
      foregroundColor: config.foregroundColor,
      borderRadius: BorderRadius.circular(12),
      showProgressBar: showProgressBar ?? false,
      dragToClose: dragToClose ?? true,
      callbacks: ToastificationCallbacks(
        onTap: (toastItem) => onTap?.call(),
        onCloseButtonTap: (toastItem) => onCloseButtonTap?.call(),
        onAutoCompleteCompleted: (toastItem) => onAutoCompleteCompleted?.call(),
      ),
    );
  }

  static void success(
    BuildContext context,
    String title, {
    String? description,
    Duration? autoCloseDuration,
    VoidCallback? onTap,
  }) {
    show(
      context: context,
      title: title,
      description: description,
      type: ToastType.success,
      autoCloseDuration: autoCloseDuration,
      onTap: onTap,
    );
  }

  static void error(
    BuildContext context,
    String title, {
    String? description,
    Duration? autoCloseDuration,
    VoidCallback? onTap,
  }) {
    show(
      context: context,
      title: title,
      description: description,
      type: ToastType.error,
      autoCloseDuration: autoCloseDuration,
      onTap: onTap,
    );
  }

  static void warning(
    BuildContext context,
    String title, {
    String? description,
    Duration? autoCloseDuration,
    VoidCallback? onTap,
  }) {
    show(
      context: context,
      title: title,
      description: description,
      type: ToastType.warning,
      autoCloseDuration: autoCloseDuration,
      onTap: onTap,
    );
  }

  static void info(
    BuildContext context,
    String title, {
    String? description,
    Duration? autoCloseDuration,
    VoidCallback? onTap,
  }) {
    show(
      context: context,
      title: title,
      description: description,
      type: ToastType.info,
      autoCloseDuration: autoCloseDuration,
      onTap: onTap,
    );
  }

  static void cancel(
    BuildContext context,
    String title, {
    String? description,
    Duration? autoCloseDuration,
    VoidCallback? onTap,
  }) {
    show(
      context: context,
      title: title,
      description: description,
      type: ToastType.cancel,
      autoCloseDuration: autoCloseDuration ?? const Duration(seconds: 2),
      onTap: onTap,
    );
  }

  static _ToastConfig _getConfigForType(ToastType type) {
    switch (type) {
      case ToastType.cancel:
        return _ToastConfig(
          icon: Icons.cancel_outlined,
          primaryColor: Colors.black87,
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.black87,
        );
      default:
        return _ToastConfig(
          icon: _getDefaultIcon(type),
          primaryColor: _getDefaultPrimaryColor(type),
          backgroundColor: _getDefaultBackgroundColor(type),
          foregroundColor: _getDefaultForegroundColor(type),
        );
    }
  }

  static IconData _getDefaultIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.warning:
        return Icons.warning_amber_outlined;
      case ToastType.info:
        return Icons.info_outline;
      default:
        return Icons.info_outline;
    }
  }

  static Color _getDefaultPrimaryColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Colors.green;
      case ToastType.error:
        return Colors.red;
      case ToastType.warning:
        return Colors.orange;
      case ToastType.info:
        return Colors.blue;
      default:
        return Colors.blue;
    }
  }

  static Color _getDefaultBackgroundColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Colors.green;
      case ToastType.error:
        return Colors.red;
      case ToastType.warning:
        return Colors.orange;
      case ToastType.info:
        return Colors.blue;
      default:
        return Colors.blue;
    }
  }

  static Color _getDefaultForegroundColor(ToastType type) {
    return Colors.white;
  }

  static ToastificationType _mapToToastificationType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return ToastificationType.success;
      case ToastType.error:
        return ToastificationType.error;
      case ToastType.warning:
        return ToastificationType.warning;
      case ToastType.info:
        return ToastificationType.info;
      case ToastType.cancel:
        return ToastificationType.info;
    }
  }
}

class _ToastConfig {
  final IconData icon;
  final Color primaryColor;
  final Color backgroundColor;
  final Color foregroundColor;

  _ToastConfig({
    required this.icon,
    required this.primaryColor,
    required this.backgroundColor,
    required this.foregroundColor,
  });
}
