import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:freeaihub/core/app_configs.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:freeaihub/core/utils/token_counter_util.dart';
import 'package:freeaihub/screens/chat/handlers/error_handler.dart';
import 'package:freeaihub/core/global/services/pdf_service.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/v4.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:csv/csv.dart';
import 'package:universal_file_viewer/universal_file_viewer.dart' as file_viewer;
import 'package:flutter/material.dart';

/// Handles all document-related functionality for chat operations
class DocumentHandler {
  final AIModel aiModel;
  final ErrorHandler errorHandler;

  /// List to store selected documents pending to be sent with next text message
  final RxList<Map<String, dynamic>> selectedDocuments = <Map<String, dynamic>>[].obs;

  DocumentHandler({required this.aiModel, required this.errorHandler});

  /// Handles document selection from device storage.
  /// Stores selected documents to be sent with next text message.
  Future<void> handleDocumentSelection() async {
    try {
      if (kDebugMode) {
        print('[DEBUG] [DocumentHandler] - Starting document selection');
      }

      // Check if too many documents are already selected
      if (selectedDocuments.length >= 2) {
        errorHandler.showError("You can select maximum 2 documents per message");
        return;
      }

      // Open file picker with allowed document types
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'xlsx', 'txt', 'csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        if (kDebugMode) {
          print('[DEBUG] [DocumentHandler] - No document selected');
        }
        return;
      }

      PlatformFile file = result.files.first;

      if (kDebugMode) {
        print('[DEBUG] [DocumentHandler] - Document selected: ${file.name}');
        print('[DEBUG] [DocumentHandler] - File size: ${file.size} bytes');
        print('[DEBUG] [DocumentHandler] - File extension: ${file.extension}');
        print('[DEBUG] [DocumentHandler] - File path: ${file.path}');
      }

      if (file.size > maxDocumentSize * 1024 * 1024) {
        final sizeMB = (file.size / (1024 * 1024)).toStringAsFixed(1);
        errorHandler.showError(
          'Document is too large ($sizeMB MB). Maximum size is $maxDocumentSize MB',
        );
        return;
      }

      // Validate file extension
      final allowedExtensions = ['pdf', 'docx', 'xlsx', 'txt', 'csv'];
      if (file.extension == null || !allowedExtensions.contains(file.extension!.toLowerCase())) {
        errorHandler.showError(
          'Unsupported document format. Please use PDF, DOCX, XLSX, TXT, or CSV',
        );
        return;
      }

      // Show loading indicator
      EasyLoading.show(status: 'Processing document...', maskType: EasyLoadingMaskType.black);

      try {
        // Give UI time to render the loading indicator before starting heavy task
        // Use multiple frame delays to ensure UI updates
        await Future.delayed(const Duration(milliseconds: 200));

        // Process document in isolate thread to prevent UI freezing
        final documentData = await _processDocumentInIsolate(file);

        if (documentData != null) {
          selectedDocuments.add(documentData);

          if (kDebugMode) {
            print('[DEBUG] [DocumentHandler] - Document stored successfully: ${file.name}');
            print('[DEBUG] [DocumentHandler] - Document Word Count: ${documentData['wordCount']}');
            print('[DEBUG] [DocumentHandler] - Document Token Cost: ${documentData['tokenCount']}');
          }

          // Clear any previous errors
          errorHandler.clearError();
        }
      } catch (e) {
        if (kDebugMode) {
          print('[DEBUG] [DocumentHandler] - Error processing document in isolate: $e');
        }
        errorHandler.showError(
          'Failed to process document. Please try again.',
          exception: e is Exception ? e : Exception(e.toString()),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[DEBUG] [DocumentHandler] - Error in document selection: $e');
      }
      errorHandler.showError(
        'Failed to select document. Please try again.',
        exception: e is Exception ? e : Exception(e.toString()),
      );
    } finally {
      EasyLoading.dismiss();
    }
  }

  /// Process document in isolate thread to prevent UI freezing
  Future<Map<String, dynamic>?> _processDocumentInIsolate(PlatformFile file) async {
    try {
      // Use Flutter's optimized compute function for better performance
      final fileData = {
        'filePath': file.path,
        'fileName': file.name,
        'fileSize': file.size,
        'fileExtension': file.extension?.toLowerCase(),
      };

      final result = await compute(_processDocumentTask, [fileData]);
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('[DEBUG] [DocumentHandler] - Error in isolate task: $e');
      }
      rethrow;
    }
  }

  /// Static function to process document in isolate
  /// This function runs in a separate isolate thread
  static Future<Map<String, dynamic>> _processDocumentTask(List<dynamic> args) async {
    try {
      final fileData = args[0] as Map<String, dynamic>;
      final String? filePath = fileData['filePath'];
      final String fileName = fileData['fileName'];
      final int fileSize = fileData['fileSize'];
      final String? fileExtension = fileData['fileExtension'];

      // Read file bytes - this is the heavy operation moved to isolate
      Uint8List fileBytes;
      if (filePath != null) {
        final actualFile = File(filePath);
        if (!await actualFile.exists()) {
          throw Exception('Selected file does not exist or is not accessible');
        }
        fileBytes = await actualFile.readAsBytes();
      } else {
        throw Exception('Could not read file data - no path or bytes available');
      }

      // Create document data structure
      final documentData = {
        'id': UuidV4().generate(),
        'name': fileName,
        'path': filePath,
        'size': fileSize,
        'extension': fileExtension,
        'type': _getDocumentTypeStatic(fileExtension ?? ''),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'mimeType': _getMimeTypeStatic(fileExtension ?? ''),
      };

      // Handle text extraction for supported formats (simplified for performance)
      switch (fileExtension) {
        case 'pdf':
          try {
            // PDF text extraction in isolate
            final pdfService = PdfService();
            final extractedText = (await pdfService.extractTextFromPdfBytes(fileBytes)).trim();
            final tokenCount = TokenCounterUtil.countTextTokens(extractedText);

            documentData['tokenCount'] = tokenCount;
            documentData['extractedText'] = extractedText;
            documentData['wordCount'] = extractedText.isEmpty
                ? 0
                : extractedText.split(RegExp(r'\s+')).length;
            documentData['characterCount'] = extractedText.length;
            documentData['hasExtractedText'] = extractedText.isNotEmpty;
          } catch (e) {
            documentData['tokenCount'] = 0;
            documentData['extractedText'] = '';
            documentData['hasExtractedText'] = false;
            documentData['extractionError'] = e.toString();
          }
          break;

        case 'txt':
          try {
            // Text file decoding in isolate
            final extractedText = utf8.decode(fileBytes).trim();
            final tokenCount = TokenCounterUtil.countTextTokens(extractedText);

            documentData['tokenCount'] = tokenCount;
            documentData['extractedText'] = extractedText;
            documentData['wordCount'] = extractedText.isEmpty
                ? 0
                : extractedText.split(RegExp(r'\s+')).length;
            documentData['characterCount'] = extractedText.length;
            documentData['hasExtractedText'] = extractedText.isNotEmpty;
          } catch (e) {
            documentData['tokenCount'] = 0;
            documentData['extractedText'] = '';
            documentData['hasExtractedText'] = false;
            documentData['extractionError'] = e.toString();
          }
          break;

        case 'docx':
        case 'xlsx':
        case 'csv':
          try {
            String extractedText = '';

            if (fileExtension == 'docx') {
              extractedText = await _extractTextFromDocx(fileBytes);
            } else if (fileExtension == 'xlsx') {
              extractedText = await _extractTextFromXlsx(fileBytes);
            } else if (fileExtension == 'csv') {
              extractedText = await _extractTextFromCsv(fileBytes);
            }

            final extractedTextTrimmed = extractedText.trim();
            final tokenCount = TokenCounterUtil.countTextTokens(extractedTextTrimmed);

            documentData['tokenCount'] = tokenCount;
            documentData['extractedText'] = extractedTextTrimmed;
            documentData['wordCount'] = extractedTextTrimmed.isEmpty
                ? 0
                : extractedTextTrimmed.split(RegExp(r'\s+')).length;
            documentData['characterCount'] = extractedTextTrimmed.length;
            documentData['hasExtractedText'] = extractedTextTrimmed.isNotEmpty;
            documentData['supportsNativePreview'] = true; // Mark as supporting native preview
          } catch (e) {
            documentData['tokenCount'] = 0;
            documentData['extractedText'] = '';
            documentData['hasExtractedText'] = false;
            documentData['extractionError'] = e.toString();
            documentData['supportsNativePreview'] =
                true; // Still supports preview even if text extraction fails
          }
          break;

        default:
          documentData['hasExtractedText'] = false;
          // Check if universal file viewer supports this format
          documentData['supportsNativePreview'] = _supportsNativePreview(fileExtension ?? '');
          break;
      }

      return documentData;
    } catch (e) {
      throw Exception('Document processing failed: ${e.toString()}');
    }
  }

  /// Static helper function for document type (for isolate usage)
  static String _getDocumentTypeStatic(String extension) {
    switch (extension) {
      case 'pdf':
        return 'PDF Document';
      case 'docx':
        return 'Word Document';
      case 'xlsx':
        return 'Excel Spreadsheet';
      case 'txt':
        return 'Text Document';
      case 'csv':
        return 'CSV Spreadsheet';
      default:
        return 'Document';
    }
  }

  /// Static helper function for MIME type (for isolate usage)
  static String _getMimeTypeStatic(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      default:
        return 'application/octet-stream';
    }
  }

  /// Static helper function for DOCX text extraction (for isolate usage)
  static Future<String> _extractTextFromDocx(Uint8List fileBytes) async {
    try {
      // Decode the DOCX archive (zip file)
      final archive = ZipDecoder().decodeBytes(fileBytes);

      // Find the document.xml file which contains the main text content
      ArchiveFile? documentXml;
      for (final file in archive) {
        if (file.name == 'word/document.xml') {
          documentXml = file;
          break;
        }
      }

      if (documentXml == null) {
        throw Exception('Could not find document.xml in DOCX file');
      }

      // Decode the XML content
      final xmlContent = utf8.decode(documentXml.content as List<int>);
      final document = XmlDocument.parse(xmlContent);

      // Extract text from all <w:t> elements (text nodes)
      final textNodes = document.findAllElements('w:t');
      final textContent = StringBuffer();

      for (final node in textNodes) {
        if (node.innerText.isNotEmpty) {
          textContent.write(node.innerText);
          textContent.write(' '); // Add space between text nodes
        }
      }

      return textContent.toString().trim();
    } catch (e) {
      throw Exception('Failed to extract text from DOCX: ${e.toString()}');
    }
  }

  /// Static helper function for XLSX text extraction (for isolate usage)
  static Future<String> _extractTextFromXlsx(Uint8List fileBytes) async {
    try {
      // Decode the XLSX archive (zip file)
      final archive = ZipDecoder().decodeBytes(fileBytes);

      // Find shared strings file for text values
      ArchiveFile? sharedStringsXml;
      for (final file in archive) {
        if (file.name == 'xl/sharedStrings.xml') {
          sharedStringsXml = file;
          break;
        }
      }

      // Extract shared strings if available
      final sharedStrings = <String>[];
      if (sharedStringsXml != null) {
        final xmlContent = utf8.decode(sharedStringsXml.content as List<int>);
        final document = XmlDocument.parse(xmlContent);

        // Extract text from shared strings
        final stringNodes = document.findAllElements('t');
        for (final node in stringNodes) {
          if (node.innerText.isNotEmpty) {
            sharedStrings.add(node.innerText);
          }
        }
      }

      // Find all worksheet files
      final worksheetTexts = <String>[];
      for (final file in archive) {
        if (file.name.startsWith('xl/worksheets/sheet') && file.name.endsWith('.xml')) {
          try {
            final xmlContent = utf8.decode(file.content as List<int>);
            final document = XmlDocument.parse(xmlContent);

            // Extract cell values
            final cellValues = <String>[];
            final cellNodes = document.findAllElements('c');

            for (final cellNode in cellNodes) {
              final valueNode = cellNode.findElements('v').firstOrNull;
              if (valueNode != null && valueNode.innerText.isNotEmpty) {
                final cellType = cellNode.getAttribute('t');

                if (cellType == 's') {
                  // Shared string reference
                  final index = int.tryParse(valueNode.innerText);
                  if (index != null && index < sharedStrings.length) {
                    cellValues.add(sharedStrings[index]);
                  }
                } else {
                  // Direct value
                  cellValues.add(valueNode.innerText);
                }
              }
            }

            if (cellValues.isNotEmpty) {
              worksheetTexts.add(cellValues.join(' '));
            }
          } catch (e) {
            // Skip problematic worksheets
            continue;
          }
        }
      }

      return worksheetTexts.join('\n').trim();
    } catch (e) {
      throw Exception('Failed to extract text from XLSX: ${e.toString()}');
    }
  }

  /// Static helper function for CSV text extraction (for isolate usage)
  static Future<String> _extractTextFromCsv(Uint8List fileBytes) async {
    try {
      // Decode CSV file
      final csvContent = utf8.decode(fileBytes);

      // Parse CSV data
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvContent);

      // Convert to readable text format
      final textContent = StringBuffer();

      for (int i = 0; i < csvData.length; i++) {
        final row = csvData[i];

        // Join row values with tabs for better readability
        final rowText = row.map((cell) => cell?.toString() ?? '').join('\t');
        textContent.writeln(rowText);

        // Add extra line break after header row
        if (i == 0 && csvData.length > 1) {
          textContent.writeln();
        }
      }

      return textContent.toString().trim();
    } catch (e) {
      throw Exception('Failed to extract text from CSV: ${e.toString()}');
    }
  }

  /// Static helper function to check if universal file viewer supports the format
  static bool _supportsNativePreview(String extension) {
    // Universal file viewer supported formats based on their documentation
    // Note: TXT files are handled with custom preview due to universal_file_viewer issues
    const supportedFormats = {'pdf', 'docx', 'xlsx', 'csv', 'txt'};
    return supportedFormats.contains(extension.toLowerCase());
  }

  /// Create a preview widget for the document using universal file viewer
  Widget createDocumentPreviewWidget(Map<String, dynamic> document) {
    final String? filePath = document['path'];
    final bool supportsPreview = document['supportsNativePreview'] ?? false;

    if (filePath == null || !supportsPreview) {
      return const Center(
        child: Text(
          'Preview not available for this document type',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return file_viewer.UniversalFileViewer(file: File(filePath));
  }

  /// Remove a selected document by ID
  void removeSelectedDocument(String documentId) {
    selectedDocuments.removeWhere((doc) => doc['id'] == documentId);
    if (kDebugMode) {
      print('[DEBUG] [DocumentHandler] - Document removed: $documentId');
    }
  }

  /// Clear all selected documents
  void clearSelectedDocuments() {
    selectedDocuments.clear();
    if (kDebugMode) {
      print('[DEBUG] [DocumentHandler] - All documents cleared');
    }
  }

  /// Get selected documents metadata for message attachment
  List<Map<String, dynamic>> getSelectedDocumentsMetadata() {
    return selectedDocuments
        .map(
          (doc) => {
            'id': doc['id'],
            'name': doc['name'],
            'size': doc['size'],
            'type': doc['type'],
            'extension': doc['extension'],
            'path': doc['path'],
            'mimeType': doc['mimeType'],
            'timestamp': doc['timestamp'],
            // Include PDF-specific data if available
            if (doc['hasExtractedText'] == true) ...{
              'extractedText': doc['extractedText'],
              'wordCount': doc['wordCount'],
              'characterCount': doc['characterCount'],
              'hasExtractedText': doc['hasExtractedText'],
            },
            if (doc['extractionError'] != null) 'extractionError': doc['extractionError'],
          },
        )
        .toList();
  }

  /// Check if there are selected documents
  bool get hasSelectedDocuments => selectedDocuments.isNotEmpty;

  /// Get selected document count
  int get selectedDocumentCount => selectedDocuments.length;
}
