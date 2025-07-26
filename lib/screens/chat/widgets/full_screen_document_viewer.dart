import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:universal_file_viewer/universal_file_viewer.dart' as file_viewer;

/// Full screen document viewer for PDFs and other document types
/// Supports PDF viewing with Syncfusion PDF Viewer and text extraction display
class FullScreenDocumentViewer extends StatefulWidget {
  final Map<String, dynamic> documentData;

  const FullScreenDocumentViewer({super.key, required this.documentData});

  @override
  State<FullScreenDocumentViewer> createState() => _FullScreenDocumentViewerState();
}

class _FullScreenDocumentViewerState extends State<FullScreenDocumentViewer> {
  late PdfViewerController _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String fileName = widget.documentData['name'] ?? 'Unknown Document';
    final String extensionForDisplay = (widget.documentData['extension'] ?? '').toUpperCase();
    final String extension = (widget.documentData['extension'] ?? '').toLowerCase();
    final String documentType = widget.documentData['type'] ?? 'Document';
    final bool hasExtractedText = widget.documentData['hasExtractedText'] == true;
    final String? extractedText = widget.documentData['extractedText'];
    final int? wordCount = widget.documentData['wordCount'];
    final int? characterCount = widget.documentData['characterCount'];
    final bool isPdf = extension == 'pdf';
    final documentPath = widget.documentData['path'];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fileName,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text('$extensionForDisplay • $documentType', style: TextStyle(fontSize: 12.sp)),
          ],
        ),
        actions: [
          // Share/Copy button for text content
          if (hasExtractedText && extractedText != null && extractedText.isNotEmpty)
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: extractedText));
                Get.snackbar('Copied', 'Document text copied to clipboard');
              },
              icon: const Icon(Icons.copy),
              tooltip: 'Copy Text',
            ),
        ],
      ),
      body: SafeArea(
        child: _buildContentView(
          isPdf: isPdf,
          documentPath: documentPath,
          hasExtractedText: hasExtractedText,
          extractedText: extractedText,
          wordCount: wordCount,
          characterCount: characterCount,
          context: context,
          extension: extension,
        ),
      ),
    );
  }

  /// Main content view router
  Widget _buildContentView({
    required bool isPdf,
    required String documentPath,
    required bool hasExtractedText,
    required String? extractedText,
    required int? wordCount,
    required int? characterCount,
    required BuildContext context,
    required String extension,
  }) {
    // PDF file with bytes available
    if (isPdf) {
      return _buildPdfViewer(context, documentPath);
    }

    // For other supported document types, attempt to open with a native viewer.
    // This is a fallback for text-based files if text extraction failed.
    const supportedByExternalViewer = ['docx', 'xlsx', 'csv'];
    if (supportedByExternalViewer.contains(extension)) {
      return file_viewer.UniversalFileViewer(file: File(documentPath));
    }

    // Show extracted text if available. This is the primary view for text-based files
    // or for the text version of other files like PDFs.
    if (hasExtractedText && extractedText != null && extractedText.isNotEmpty) {
      return _buildExtractedTextView(
        extractedText: extractedText,
        wordCount: wordCount,
        characterCount: characterCount,
        context: context,
      );
    }

    // If no other view is available (e.g., unsupported type, or a PDF in text mode without extracted text), show a message.
    return _buildNoPreviewAvailable(context);
  }

  /// Full screen PDF viewer
  Widget _buildPdfViewer(BuildContext context, String documentPath) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SfPdfViewer.file(
        File(documentPath),
        controller: _pdfController,
        canShowTextSelectionMenu: true,
        enableDoubleTapZooming: true,
        enableTextSelection: true,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        canShowPaginationDialog: true,
        canShowPasswordDialog: true,
        canShowHyperlinkDialog: true,
        enableDocumentLinkAnnotation: true,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          // Document loaded successfully
          debugPrint('PDF loaded: ${details.document.pages.count} pages');
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          // Handle load failure
          Get.snackbar('Error', 'Failed to load PDF: ${details.error}');
        },
      ),
    );
  }

  /// Extracted text view with statistics
  Widget _buildExtractedTextView({
    required String extractedText,
    required int? wordCount,
    required int? characterCount,
    required BuildContext context,
  }) {
    return Padding(
      padding: EdgeInsets.all(16.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics header
          if (wordCount != null || characterCount != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.sp, horizontal: 16.sp),
              margin: EdgeInsets.only(bottom: 16.sp),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12.sp),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Wrap(
                      spacing: 16.sp,
                      children: [
                        if (wordCount != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.text_fields,
                                size: 16,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              SizedBox(width: 4.sp),
                              Text(
                                '$wordCount words',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        if (characterCount != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.short_text,
                                size: 16,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              SizedBox(width: 4.sp),
                              Text(
                                '$characterCount characters',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Extracted text content
          Text(
            'Extracted Content:',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 12.sp),

          // Scrollable text content
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.sp),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.sp),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  extractedText,
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontFamily: Platform.isAndroid ? 'monospace' : 'Courier',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// No preview available message
  Widget _buildNoPreviewAvailable(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          SizedBox(height: 24.sp),
          Text(
            'No Preview Available',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 12.sp),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.sp),
            child: Text(
              'This document type cannot be previewed or the file data is not available.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
