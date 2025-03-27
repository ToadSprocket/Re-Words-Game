import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../managers/gameLayoutManager.dart';

class LoadingDialog {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> show(BuildContext context, GameLayoutManager gameLayoutManager, {String message = "Loading..."}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button from dismissing
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
              side: BorderSide(color: AppStyles.dialogBorderColor, width: AppStyles.dialogBorderWidth),
            ),
            backgroundColor: AppStyles.dialogBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppStyles.dialogBorderColor)),
                  const SizedBox(height: 16),
                  Text(message, style: gameLayoutManager.dialogTitleStyle, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void dismiss(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
