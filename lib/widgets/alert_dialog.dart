import 'package:flutter/material.dart';
import 'package:notes_app/utils/font_size.dart';
import 'package:notes_app/utils/style.dart';

class AlertDialogWidget extends StatelessWidget {
  final String headingText;
  final String contentText;
  final VoidCallback confirmFunction;
  final VoidCallback declineFunction;

  const AlertDialogWidget({
    super.key,
    required this.headingText,
    required this.contentText,
    required this.confirmFunction,
    required this.declineFunction,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        headingText,
        textAlign: TextAlign.center,
        style: fontStyleBold.copyWith(fontSize: FontSize.mediumLarge),
      ),

      content: Text(contentText),
      actions: [
        TextButton(
          onPressed: declineFunction,
          child: const Text("No"),
        ),
        TextButton(
          onPressed: confirmFunction,
          child: const Text("Yes"),
        ),
      ],
    );
  }
}
