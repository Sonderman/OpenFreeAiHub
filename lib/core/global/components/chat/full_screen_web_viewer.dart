import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard functionality
import 'package:webviewx_plus/webviewx_plus.dart'; // Import webviewx_plus

class FullScreenWebViewer extends StatefulWidget {
  // Changed to StatefulWidget
  final String htmlContent;

  const FullScreenWebViewer({super.key, required this.htmlContent});

  @override
  State<FullScreenWebViewer> createState() => _FullScreenWebViewerState();
}

class _FullScreenWebViewerState extends State<FullScreenWebViewer>
    with SingleTickerProviderStateMixin {
  // State class for WebViewX with TabController
  late WebViewXController webviewController; // Controller for WebViewX
  late TabController _tabController; // Tab controller for managing tabs

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Initialize tab controller with 2 tabs
  }

  @override
  void dispose() {
    // Check if the controller has a dispose method before calling it
    webviewController.dispose();
    _tabController.dispose(); // Dispose tab controller
    super.dispose();
  }

  // Method to copy HTML content to clipboard
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.htmlContent));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('HTML code copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTML Viewer'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          tabs: const [
            Tab(icon: Icon(Icons.preview), text: 'Preview'),
            Tab(icon: Icon(Icons.code), text: 'Code View'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
        ),
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(), // Disable swiping between tabs
          children: [
            // Preview Tab - WebView
            Container(
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: WebViewX(
                  key: const ValueKey('webviewx'),
                  initialContent: widget.htmlContent,
                  initialSourceType: SourceType.html,
                  javascriptMode: JavascriptMode.unrestricted,
                  onWebViewCreated: (controller) {
                    webviewController = controller;
                  },
                  height: MediaQuery.of(context).size.height - 200,
                  width: MediaQuery.of(context).size.width,
                  webSpecificParams: const WebSpecificParams(webAllowFullscreenContent: true),
                  mobileSpecificParams: const MobileSpecificParams(
                    androidEnableHybridComposition: true,
                  ),
                ),
              ),
            ),
            // Code View Tab - Formatted HTML Code
            Container(
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8.0),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Column(
                children: [
                  // Header with copy button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8.0),
                        topRight: Radius.circular(8.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'HTML Code',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: _copyToClipboard,
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy to clipboard',
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                  // Code content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: SelectableText(
                        widget.htmlContent,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
