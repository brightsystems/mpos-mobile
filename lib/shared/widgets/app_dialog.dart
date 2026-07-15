import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:mpos_mobile/app/app_navigator.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_progress_indicator.dart';

class AppDialog {
  static Future<dynamic> show({
    String? title,
    Widget? child,
    String? text,
    EdgeInsets? padding,
    String? leftButtonText,
    String? rightButtonText,
    Function(BuildContext)? onTapLeftButton,
    Function(BuildContext)? onTapRightButton,
    bool? dismissible,
    bool? enableRightButton,
    bool? enableLeftButton,
    Color? leftButtonColor,
    Color? leftButtonTextColor,
    Color? leftButtonBorderColor,
    Color? rightButtonColor,
    Color? rightButtonTextColor,
    Color? rightButtonBorderColor,
    double? elevation,
  }) async {
    final context = AppNavigator.rootNavigatorKey.currentContext;
    if (context == null) throw Exception('No context available for dialog');

    return showDialog(
      context: context,
      barrierDismissible: dismissible ?? true,
      builder: (context) {
        return PopScope(
          canPop: dismissible ?? true,
          child: AppDialogWidget(
            title: title,
            text: text,
            padding: padding,
            rightButtonText: rightButtonText,
            leftButtonText: leftButtonText,
            onTapLeftButton: onTapLeftButton,
            onTapRightButton: onTapRightButton,
            dismissible: dismissible ?? true,
            enableRightButton: enableRightButton ?? true,
            enableLeftButton: enableLeftButton ?? true,
            elevation: elevation,
            leftButtonColor: leftButtonColor,
            leftButtonTextColor: leftButtonTextColor,
            leftButtonBorderColor: leftButtonBorderColor,
            rightButtonColor: rightButtonColor,
            rightButtonTextColor: rightButtonTextColor,
            rightButtonBorderColor: rightButtonBorderColor,
            child: child,
          ),
        );
      },
    );
  }

  static Future<void> showError({
    String? title,
    String? message,
    String? error,
    String buttonText = 'Close',
    Function(BuildContext)? onTapButton,
  }) async {
    final context = AppNavigator.rootNavigatorKey.currentContext;
    if (context == null) throw Exception('No context available for dialog');

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AppDialogWidget(
            title: title ?? 'Oops!',
            leftButtonText: buttonText,
            onTapLeftButton: onTapButton,
            child: Column(
              children: [
                Text(
                  message ?? 'Something went wrong, please contact your system administrator or try restart the app',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.padding),
                    child: Text(
                      error.toString().length > 200 ? error.toString().substring(0, 200) : error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<T> showProgress<T>(Future<T> Function() process, {bool dismissible = false}) async {
    final context = AppNavigator.rootNavigatorKey.currentContext;
    if (context == null) throw Exception('No context available for dialog');

    showDialog(
      context: context,
      barrierDismissible: kDebugMode ? true : dismissible,
      builder: (dialogContext) {
        return PopScope(
          canPop: kDebugMode ? true : dismissible,
          child: AppDialogWidget(
            dismissible: kDebugMode ? true : dismissible,
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: const AppProgressIndicator(),
          ),
        );
      },
    );

    try {
      final result = await process();
      _closeDialog();

      return result;
    } catch (e) {
      _closeDialog();
      rethrow;
    }
  }

  static void _closeDialog() {
    if (AppNavigator.rootNavigatorKey.currentState?.canPop() ?? false) {
      AppNavigator.rootNavigatorKey.currentState?.pop();
    }
  }
}

class AppDialogWidget extends StatelessWidget {
  const AppDialogWidget({
    super.key,
    this.title,
    this.child,
    this.text,
    this.padding,
    this.leftButtonText,
    this.rightButtonText,
    this.dismissible = true,
    this.enableRightButton = true,
    this.enableLeftButton = true,
    this.elevation,
    this.backgroundColor,
    this.leftButtonColor,
    this.leftButtonTextColor,
    this.leftButtonBorderColor,
    this.rightButtonColor,
    this.rightButtonTextColor,
    this.rightButtonBorderColor,
    this.onTapLeftButton,
    this.onTapRightButton,
  });

  final String? title;
  final Widget? child;
  final String? text;
  final EdgeInsets? padding;
  final String? leftButtonText;
  final String? rightButtonText;
  final bool dismissible;
  final bool enableRightButton;
  final bool enableLeftButton;
  final double? elevation;
  final Color? backgroundColor;
  final Color? leftButtonColor;
  final Color? leftButtonTextColor;
  final Color? leftButtonBorderColor;
  final Color? rightButtonColor;
  final Color? rightButtonTextColor;
  final Color? rightButtonBorderColor;
  final Function(BuildContext)? onTapLeftButton;
  final Function(BuildContext)? onTapRightButton;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: dismissible,
      child: Dialog(
        elevation: elevation,
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 512),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _DialogTitle(title: title),
                _DialogBody(text: text, padding: padding, child: child),
                _DialogButtons(
                  leftButtonText: leftButtonText,
                  rightButtonText: rightButtonText,
                  enableLeftButton: enableLeftButton,
                  enableRightButton: enableRightButton,
                  leftButtonColor: leftButtonColor,
                  leftButtonTextColor: leftButtonTextColor,
                  leftButtonBorderColor: leftButtonBorderColor,
                  rightButtonColor: rightButtonColor,
                  rightButtonTextColor: rightButtonTextColor,
                  rightButtonBorderColor: rightButtonBorderColor,
                  onTapLeftButton: onTapLeftButton,
                  onTapRightButton: onTapRightButton,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle({required this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return title != null
        ? Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.padding,
              AppSizes.padding * 1.5,
              AppSizes.padding,
              AppSizes.padding / 2,
            ),
            child: Text(
              title!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          )
        : const SizedBox.shrink();
  }
}

class _DialogBody extends StatelessWidget {
  const _DialogBody({required this.text, required this.child, required this.padding});

  final String? text;
  final Widget? child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(AppSizes.padding),
      child: text != null
          ? Text(text!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium)
          : child ?? const SizedBox.shrink(),
    );
  }
}

class _DialogButtons extends StatelessWidget {
  const _DialogButtons({
    required this.leftButtonText,
    required this.rightButtonText,
    required this.enableLeftButton,
    required this.enableRightButton,
    required this.leftButtonColor,
    required this.leftButtonTextColor,
    required this.leftButtonBorderColor,
    required this.rightButtonColor,
    required this.rightButtonTextColor,
    required this.rightButtonBorderColor,
    required this.onTapLeftButton,
    required this.onTapRightButton,
  });

  final String? leftButtonText;
  final String? rightButtonText;
  final bool enableLeftButton;
  final bool enableRightButton;
  final Color? leftButtonColor;
  final Color? leftButtonTextColor;
  final Color? leftButtonBorderColor;
  final Color? rightButtonColor;
  final Color? rightButtonTextColor;
  final Color? rightButtonBorderColor;
  final Function(BuildContext)? onTapLeftButton;
  final Function(BuildContext)? onTapRightButton;

  @override
  Widget build(BuildContext context) {
    return leftButtonText == null && rightButtonText == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Row(
              children: <Widget>[
                if (leftButtonText != null)
                  Expanded(
                    child: AppButton(
                      text: leftButtonText!,
                      buttonColor: leftButtonColor ?? Theme.of(context).colorScheme.surface,
                      borderColor:
                          leftButtonBorderColor ?? leftButtonTextColor ?? Theme.of(context).colorScheme.primary,
                      textColor: leftButtonTextColor ?? Theme.of(context).colorScheme.primary,
                      onTap: () async {
                        if (enableLeftButton) {
                          if (onTapLeftButton != null) {
                            onTapLeftButton!(context);
                          } else {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                    ),
                  ),
                if (leftButtonText != null && rightButtonText != null) const SizedBox(width: AppSizes.padding / 2),
                if (rightButtonText != null)
                  Expanded(
                    child: AppButton(
                      text: rightButtonText!,
                      buttonColor: rightButtonColor,
                      borderColor:
                          rightButtonBorderColor ?? rightButtonTextColor ?? Theme.of(context).colorScheme.primary,
                      textColor: rightButtonTextColor,
                      onTap: () async {
                        if (enableRightButton) {
                          if (onTapRightButton != null) {
                            onTapRightButton!(context);
                          } else {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                    ),
                  ),
              ],
            ),
          );
  }
}
