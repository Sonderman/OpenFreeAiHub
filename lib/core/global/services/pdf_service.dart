import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Service class for handling PDF file operations including file picking and text extraction
class PdfService {
  /// Pick a PDF file from device storage
  /// Returns the file path if successful, null if cancelled or error occurred
  Future<String?> pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: false, // We don't need the bytes, just the path
        withReadStream: false,
      );

      if (result != null && result.files.single.path != null) {
        final String filePath = result.files.single.path!;

        // Verify file exists and is a PDF
        final File file = File(filePath);
        if (await file.exists()) {
          if (kDebugMode) {
            print('PDF file picked successfully: $filePath');
          }
          return filePath;
        } else {
          throw Exception('Selected file does not exist');
        }
      } else {
        if (kDebugMode) {
          print('PDF file selection cancelled by user');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking PDF file: $e');
      }
      throw Exception('Failed to pick PDF file: $e');
    }
  }

  /// Pick multiple PDF files from device storage
  /// Returns list of file paths if successful, empty list if cancelled or error occurred
  Future<List<String>> pickMultiplePdfFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        List<String> filePaths = [];

        for (PlatformFile file in result.files) {
          if (file.path != null) {
            final File fileObj = File(file.path!);
            if (await fileObj.exists()) {
              filePaths.add(file.path!);
            }
          }
        }

        if (kDebugMode) {
          print('${filePaths.length} PDF files picked successfully');
        }

        return filePaths;
      } else {
        if (kDebugMode) {
          print('PDF file selection cancelled by user');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking multiple PDF files: $e');
      }
      throw Exception('Failed to pick PDF files: $e');
    }
  }

  /// Extract text content from a PDF file using file path
  /// Returns the extracted text content
  Future<String> extractTextFromPdf(String filePath) async {
    try {
      // Check if file exists
      final File file = File(filePath);
      if (!await file.exists()) {
        throw Exception('PDF file does not exist at path: $filePath');
      }

      // Read file bytes
      final Uint8List bytes = await file.readAsBytes();

      // Extract text using bytes
      return await extractTextFromPdfBytes(bytes);
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting text from PDF file: $e');
      }
      throw Exception('Failed to extract text from PDF: $e');
    }
  }

  /// Extract text content from PDF bytes
  /// Returns the extracted text content
  Future<String> extractTextFromPdfBytes(Uint8List bytes) async {
    try {
      // Load the PDF document from bytes
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Extract text from all pages
      final String extractedText = PdfTextExtractor(document).extractText();

      // Clean up
      document.dispose();

      if (extractedText.isEmpty) {
        throw Exception('No text content found in the PDF document');
      }

      if (kDebugMode) {
        print('[DEBUG] Successfully extracted ${extractedText.length} characters from PDF');
      }

      return extractedText.trim();
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting text from PDF bytes: $e');
      }
      throw Exception('Failed to extract text from PDF bytes: $e');
    }
  }

  /// Pick a PDF file and extract its text content in one operation
  /// Returns a Map containing file info and extracted text
  Future<Map<String, dynamic>?> pickAndExtractPdf() async {
    try {
      // Pick PDF file
      final String? filePath = await pickPdfFile();

      if (filePath == null) {
        return null; // User cancelled selection
      }

      // Extract text from selected file
      final String extractedText = await extractTextFromPdf(filePath);

      // Get file info
      final File file = File(filePath);
      final String fileName = file.path.split('/').last;
      final int fileSize = await file.length();

      return {
        'fileName': fileName,
        'filePath': filePath,
        'fileSize': fileSize,
        'extractedText': extractedText,
        'extractedAt': DateTime.now().toIso8601String(),
        'wordCount': extractedText.split(RegExp(r'\s+')).length,
        'characterCount': extractedText.length,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error in pick and extract PDF operation: $e');
      }
      throw Exception('Failed to pick and extract PDF: $e');
    }
  }

  /// Pick multiple PDF files and extract text from all of them
  /// Returns a List of Maps containing file info and extracted text for each file
  Future<List<Map<String, dynamic>>> pickAndExtractMultiplePdfs() async {
    try {
      // Pick multiple PDF files
      final List<String> filePaths = await pickMultiplePdfFiles();

      if (filePaths.isEmpty) {
        return []; // User cancelled selection or no files selected
      }

      List<Map<String, dynamic>> results = [];

      for (String filePath in filePaths) {
        try {
          // Extract text from current file
          final String extractedText = await extractTextFromPdf(filePath);

          // Get file info
          final File file = File(filePath);
          final String fileName = file.path.split('/').last;
          final int fileSize = await file.length();

          results.add({
            'fileName': fileName,
            'filePath': filePath,
            'fileSize': fileSize,
            'extractedText': extractedText,
            'extractedAt': DateTime.now().toIso8601String(),
            'wordCount': extractedText.split(RegExp(r'\s+')).length,
            'characterCount': extractedText.length,
          });
        } catch (e) {
          // Add error info for this specific file
          final File file = File(filePath);
          final String fileName = file.path.split('/').last;

          results.add({
            'fileName': fileName,
            'filePath': filePath,
            'fileSize': 0,
            'extractedText': '',
            'extractedAt': DateTime.now().toIso8601String(),
            'wordCount': 0,
            'characterCount': 0,
            'error': 'Failed to extract text: $e',
          });

          if (kDebugMode) {
            print('Error extracting text from $fileName: $e');
          }
        }
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Error in pick and extract multiple PDFs operation: $e');
      }
      throw Exception('Failed to pick and extract multiple PDFs: $e');
    }
  }

  /// Validate if a file is a valid PDF
  /// Returns true if valid, false otherwise
  Future<bool> validatePdfFile(String filePath) async {
    try {
      final File file = File(filePath);

      if (!await file.exists()) {
        return false;
      }

      // Check file extension
      if (!filePath.toLowerCase().endsWith('.pdf')) {
        return false;
      }

      // Try to load the PDF document to validate structure
      final Uint8List bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Check if document has pages
      final bool isValid = document.pages.count > 0;

      // Clean up
      document.dispose();

      return isValid;
    } catch (e) {
      if (kDebugMode) {
        print('Error validating PDF file: $e');
      }
      return false;
    }
  }

  /// Get PDF file information without extracting text
  /// Returns a Map containing basic file information
  Future<Map<String, dynamic>?> getPdfFileInfo(String filePath) async {
    try {
      final File file = File(filePath);

      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final Uint8List bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      final String fileName = file.path.split('/').last;
      final int fileSize = await file.length();
      final int pageCount = document.pages.count;

      // Get document info if available
      String title = '';
      String author = '';
      String subject = '';
      String creator = '';

      try {
        if (document.documentInformation.title.isNotEmpty) {
          title = document.documentInformation.title;
        }
        if (document.documentInformation.author.isNotEmpty) {
          author = document.documentInformation.author;
        }
        if (document.documentInformation.subject.isNotEmpty) {
          subject = document.documentInformation.subject;
        }
        if (document.documentInformation.creator.isNotEmpty) {
          creator = document.documentInformation.creator;
        }
      } catch (e) {
        // Document info might not be available
        if (kDebugMode) {
          print('Could not extract document metadata: $e');
        }
      }

      // Clean up
      document.dispose();

      return {
        'fileName': fileName,
        'filePath': filePath,
        'fileSize': fileSize,
        'pageCount': pageCount,
        'title': title,
        'author': author,
        'subject': subject,
        'creator': creator,
        'analyzedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting PDF file info: $e');
      }
      throw Exception('Failed to get PDF file information: $e');
    }
  }
}
