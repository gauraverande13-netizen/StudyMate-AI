import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:studymate_ai/View/DocumentViewerScreen.dart';
import 'package:studymate_ai/repo/user_session.dart';
import '../repo/summary_service.dart';

// Document model for maintaining uploaded files list
class UploadedDocItem {
  final String id;
  final String fileName;
  final String summary;
  final List<String> keyTakeaways;
  final DateTime uploadedAt;
  final Uint8List? fileBytes;
  final String? filePath;
  final String? fileUrl;
  final String? fullContent;

  UploadedDocItem({
    required this.id,
    required this.fileName,
    required this.summary,
    required this.keyTakeaways,
    required this.uploadedAt,
    this.fileBytes,
    this.filePath,
    this.fileUrl,
    this.fullContent,
  });
}

class SummaryScreen extends StatefulWidget {
  final int? userId;
  final VoidCallback? onBack;
  final Function(int)? onNavigateToTab;

  const SummaryScreen({
    super.key,
    this.userId,
    this.onBack,
    this.onNavigateToTab,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  int? _userId;
  bool _isUploading = false;
  String? _errorMessage;

  // Uploaded docs ki list
  final List<UploadedDocItem> _uploadedDocs = [];

  // Currently open/selected document
  UploadedDocItem? _selectedDoc;

  // 👇 1. लोडिंग फ्लॅग जोडा
  bool _isLoadingList = false;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    if (_userId == null) {
      _userId = await UserSession.getUserId();
    }
    _loadDocumentsFromDB();
  }

  // 👇 3. डेटाबेसमधून डॉक्युमेंट्स फेच करणारे फंक्शन
  Future<void> _loadDocumentsFromDB() async {
    setState(() {
      _isLoadingList = true;
    });

    final effectiveId = _userId ?? (await UserSession.getUserId()) ?? 1;
    final rawList = await SummaryService.getUserDocuments(userId: effectiveId);

    List<UploadedDocItem> items = [];
    for (var item in rawList) {
      // Summary parsing
      String summaryStr = '';
      if (item['summary'] is List) {
        summaryStr = (item['summary'] as List).join('\n\n');
      } else if (item['summary'] != null) {
        summaryStr = item['summary'].toString();
      }

      // Key points parsing
      List<String> points = [];
      final rawPoints = item['key_points'];
      if (rawPoints is List) {
        points = rawPoints.map((e) => e.toString().trim()).toList();
      } else if (rawPoints is String) {
        points = rawPoints
            .split('\n')
            .map((e) => e.replaceAll(RegExp(r'^[-*•\d.]+\s*'), '').trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      final docId = item['id'].toString();
      final fileUrl = item['file_url'] ?? SummaryService.getFileUrl(docId);

      items.add(
        UploadedDocItem(
          id: docId,
          fileName: item['filename'] ?? 'Untitled Document',
          summary: summaryStr.isNotEmpty ? summaryStr : 'Summary unavailable.',
          keyTakeaways: points,
          uploadedAt:
              DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
          fileUrl: fileUrl,
          fullContent: item['full_text'],
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _uploadedDocs.clear();
      _uploadedDocs.addAll(items);
      _isLoadingList = false;
    });
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;

      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      final effectiveId = _userId ?? (await UserSession.getUserId()) ?? 1;
      final response = await SummaryService.uploadAndSummarize(
        pickedFile,
        userId: effectiveId,
      );

      if (!mounted) return;

      setState(() {
        _isUploading = false;
        if (response['success'] == true) {
          // Summary string ya list dono me se safely handle karein
          String parsedSummary = '';
          final rawSummary = response['summary'];
          if (rawSummary is List) {
            parsedSummary = rawSummary.join('\n\n');
          } else if (rawSummary != null) {
            parsedSummary = rawSummary.toString();
          }

          // Key takeaways list parsing
          List<String> parsedPoints = [];
          final rawPoints = response['key_points'];

          if (rawPoints is List) {
            parsedPoints = rawPoints.map((e) => e.toString().trim()).toList();
          } else if (rawPoints is String) {
            parsedPoints = rawPoints
                .split('\n')
                .map((e) => e.replaceAll(RegExp(r'^[-*•\d.]+\s*'), '').trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }

          final docId = (response['doc_id'] ?? DateTime.now().millisecondsSinceEpoch).toString();
          final fileUrl = response['file_url'] ?? SummaryService.getFileUrl(docId);
          final fullContent = response['full_text'] ?? '';

          final newDoc = UploadedDocItem(
            id: docId,
            fileName: response['filename'] ?? pickedFile.name,
            summary: parsedSummary.isNotEmpty
                ? parsedSummary
                : 'No summary available.',
            keyTakeaways: parsedPoints,
            uploadedAt: DateTime.now(),
            fileBytes: pickedFile.bytes,
            filePath: kIsWeb ? null : pickedFile.path,
            fileUrl: fileUrl,
            fullContent: fullContent,
          );

          setState(() {
            _uploadedDocs.insert(0, newDoc);
          });

          // Turant DocumentViewerScreen open karein taaki user ko original PDF dikhe
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentViewerScreen(
                fileName: newDoc.fileName,
                summary: newDoc.summary,
                keyTakeaways: newDoc.keyTakeaways,
                fileBytes: newDoc.fileBytes,
                filePath: newDoc.filePath,
                fileUrl: newDoc.fileUrl,
                fullContent: newDoc.fullContent,
                docId: newDoc.id,
                onConvertToFlashcards: () {
                  widget.onNavigateToTab?.call(3);
                },
              ),
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${newDoc.fileName} successfully uploaded! Original PDF opened.',
              ),
              backgroundColor: const Color(0xFF059669),
            ),
          );
        } else {
          _errorMessage = response['message'];
        }
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'File selection error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: _selectedDoc != null
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1E293B),
                  size: 18,
                ),
                onPressed: () {
                  setState(() {
                    _selectedDoc = null; // Wapas list view me jaane ke liye
                  });
                },
              )
            : (widget.onBack != null
                  ? IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF1E293B),
                        size: 18,
                      ),
                      onPressed: widget.onBack,
                    )
                  : null),
        title: Text(
          _selectedDoc != null ? 'Document Summary' : 'Document Summarizer',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Upload Card (Hamesha top pe rahega)
            GestureDetector(
              onTap: _isUploading ? null : _pickAndUploadDocument,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _isUploading
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.cloud_upload_outlined,
                              color: Color(0xFF4F46E5),
                              size: 28,
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isUploading
                          ? 'Analyzing Document with AI...'
                          : 'Tap to upload PDF, DOCX or TXT',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Automatic key points & flashcard generator',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Max 25 MB',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 13,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 2. Agar koi document select kiya hai to uski Details / Summary Card dikhao
            if (_selectedDoc != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Selected Document',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedDoc = null;
                      });
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 16,
                      color: Color(0xFF4F46E5),
                    ),
                    label: const Text(
                      'View All',
                      style: TextStyle(color: Color(0xFF4F46E5), fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildSummaryDetailsCard(_selectedDoc!),
            ]
            // 3. Agar koi select nahi kiya to Uploaded PDFs ki List dikhao
            else ...[
              const Text(
                'Uploaded Documents',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              if (_uploadedDocs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: const [
                      Icon(
                        Icons.folder_open_rounded,
                        size: 38,
                        color: Color(0xFF94A3B8),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Abhi tak koi PDF upload nahi kiya',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Upar diye card par tap karke PDF upload karein',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _uploadedDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _uploadedDocs[index];
                    return _buildDocumentListItem(item);
                  },
                ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Document Item Widget in List
  Widget _buildDocumentListItem(UploadedDocItem doc) {
    return InkWell(
      onTap: () {
        // 👉 New Screen me real original PDF viewer open karna:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentViewerScreen(
              fileName: doc.fileName,
              summary: doc.summary,
              keyTakeaways: doc.keyTakeaways,
              fileBytes: doc.fileBytes,
              filePath: doc.filePath,
              fileUrl: doc.fileUrl,
              fullContent: doc.fullContent,
              docId: doc.id,
              onConvertToFlashcards: () {
                widget.onNavigateToTab?.call(3);
              },
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Color(0xFF4F46E5),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Summarized',
                          style: TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${doc.keyTakeaways.length} key points',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  // Summary Details Card
  Widget _buildSummaryDetailsCard(UploadedDocItem doc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: Color(0xFF4F46E5),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  doc.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Summarized',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          const Text(
            'EXECUTIVE SUMMARY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            doc.summary,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Color(0xFF334155),
            ),
          ),
          if (doc.keyTakeaways.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Key Takeaways',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...doc.keyTakeaways.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: Color(0xFF4F46E5),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              point,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DocumentViewerScreen(
                      fileName: doc.fileName,
                      summary: doc.summary,
                      keyTakeaways: doc.keyTakeaways,
                      fileBytes: doc.fileBytes,
                      filePath: doc.filePath,
                      fileUrl: doc.fileUrl,
                      fullContent: doc.fullContent,
                      docId: doc.id,
                      onConvertToFlashcards: () {
                        widget.onNavigateToTab?.call(3);
                      },
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
                side: const BorderSide(color: Color(0xFF4F46E5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text(
                'View Original PDF Document',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onNavigateToTab?.call(3);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.style_outlined, size: 18),
              label: Text(
                'Convert to ${doc.keyTakeaways.length > 1 ? doc.keyTakeaways.length : 3} Revision Flashcards',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
