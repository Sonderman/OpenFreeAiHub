// New StatelessWidget for handling HTML code blocks
import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart'; // Not strictly necessary if only using Material widgets
// import 'package:flutter_html/flutter_html.dart'; // No longer directly rendering HTML here
import 'package:get/get.dart';
import 'package:gpt_markdown/custom_widgets/code_field.dart';
// import 'package:gpt_markdown/custom_widgets/code_field.dart'; // Not rendering CodeField here anymore
import 'package:sizer/sizer.dart';
import 'full_screen_web_viewer.dart'; // Import the full screen viewer

class HtmlCodePreview extends StatelessWidget {
  final String htmlCode;
  final dynamic controller; // Changed to dynamic to support both controller types

  const HtmlCodePreview({super.key, required this.htmlCode, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Now, always show a button that navigates to the full-screen HTML viewer.
    return Obx(() {
      if (!(controller?.isTyping?.value == true)) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 4.sp, horizontal: 8.sp),
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            icon: Icon(
              Icons.preview_outlined,
              size: 24.0,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            label: Text('Open HTML Preview', style: TextStyle(fontSize: 12.0)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              elevation: 4.0,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              Get.to(() => FullScreenWebViewer(htmlContent: htmlCode));
            },
          ),
        );
      } else {
        return CodeField(name: "html", codes: htmlCode);
      }
    });
  }
}
