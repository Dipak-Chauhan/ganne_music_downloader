import 'package:flutter/material.dart';

/// Centralized toast/snackbar helper for consistent, beautiful toast messages.
/// Always clears existing snackbars before showing a new one to prevent stacking.
class AppToast {
  AppToast._();

  /// Show a success toast (green accent, check icon)
  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message,
      _ToastType.success,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show an info toast (primary accent, info icon)
  static void info(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message,
      _ToastType.info,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show a warning toast (amber accent, warning icon)
  static void warning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message,
      _ToastType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show an error toast (red accent, error icon)
  static void error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message,
      _ToastType.error,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void _show(
    BuildContext context,
    String message,
    _ToastType type, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final cs = Theme.of(context).colorScheme;

    // Always clear previous snackbars to prevent stacking
    messenger.clearSnackBars();

    Color backgroundColor;
    Color foregroundColor;
    IconData icon;
    Duration duration;

    switch (type) {
      case _ToastType.success:
        backgroundColor = cs.tertiaryContainer;
        foregroundColor = cs.onTertiaryContainer;
        icon = Icons.check_circle_rounded;
        duration = const Duration(seconds: 2);
        break;
      case _ToastType.info:
        backgroundColor = cs.secondaryContainer;
        foregroundColor = cs.onSecondaryContainer;
        icon = Icons.info_rounded;
        duration = const Duration(seconds: 2);
        break;
      case _ToastType.warning:
        backgroundColor = cs.errorContainer;
        foregroundColor = cs.onErrorContainer;
        icon = Icons.warning_amber_rounded;
        duration = const Duration(seconds: 3);
        break;
      case _ToastType.error:
        backgroundColor = cs.error;
        foregroundColor = cs.onError;
        icon = Icons.error_rounded;
        duration = const Duration(seconds: 4);
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: foregroundColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: foregroundColor,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }
}

enum _ToastType { success, info, warning, error }
