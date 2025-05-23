import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/background_controller.dart';
import 'package:my_note_app/utils/padding_size.dart';
class BackgroundColorOpacityDialog extends StatefulWidget {
  const BackgroundColorOpacityDialog({super.key});

  @override
  State<BackgroundColorOpacityDialog> createState() => _BackgroundColorOpacityDialogState();
}

class _BackgroundColorOpacityDialogState extends State<BackgroundColorOpacityDialog> {

  double opacity = 0.1;

  @override
  void initState() {
    super.initState();

    opacity = Get.find<BackgroundController>().getOpacity();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withValues(alpha: opacity),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: GetBuilder<BackgroundController>(
        builder: (backgroundController) {
          return SizedBox(
            height: context.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: opacity,
                  // value: backgroundController.colorOpacity,
                  onChanged: (v) {
                    opacity = v;
                    setState(() {
                    });
                    backgroundController.setOpacity(opacity);
                  },
                ),
                const SizedBox(height: PaddingSize.large),

                ElevatedButton(
                  onPressed: () => Get.back(result: opacity),
                  child: Icon(Icons.check, size: 32),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}
