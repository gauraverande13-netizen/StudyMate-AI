import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:studymate_ai/repo/summary_service.dart';

class DocumentViewerScreen extends StatefulWidget {
  final String fileName;
  final String summary;
  final List<String> keyTakeaways;
  final String? fullContent;
  final Uint8List? fileBytes;
  final String? filePath;
  final String? fileUrl;
  final String? docId;
  final VoidCallback? onConvertToFlashcards;

  const DocumentViewerScreen({
    super.key,
    required this.fileName,
    required this.summary,
    required this.keyTakeaways,
    this.fullContent,
    this.fileBytes,
    this.filePath,
    this.fileUrl,
    this.docId,
    this.onConvertToFlashcards,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PdfViewerController _pdfViewerController;

  bool _isPdf = false;
  bool _showRawText = false;
  bool _isLoadingPdf = true;
  bool _pdfLoadFailed = false;
  String? _pdfLoadError;

  int _currentPage = 1;
  int _pageCount = 1;

  String? _fullText;
  Uint8List? _loadedBytes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pdfViewerController = PdfViewerController();

    _isPdf = widget.fileName.toLowerCase().endsWith('.pdf');
    _fullText = widget.fullContent;
    _loadedBytes = widget.fileBytes;

    _initializeDocument();
  }

  Future<void> _initializeDocument() async {
    // If text was not provided upfront and we have a docId, fetch the full extracted content
    if ((_fullText == null || _fullText!.isEmpty) && widget.docId != null) {
      final docData = await SummaryService.getDocumentContent(widget.docId);
      if (mounted && docData != null) {
        setState(() {
          _fullText = docData['full_text'];
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }

  String _getEffectiveFileUrl() {
    if (widget.fileUrl != null && widget.fileUrl!.isNotEmpty) {
      if (widget.fileUrl!.startsWith('http://') ||
          widget.fileUrl!.startsWith('https://')) {
        return widget.fileUrl!;
      }
      return 'http://127.0.0.1:8000${widget.fileUrl!}';
    }
    if (widget.docId != null) {
      return SummaryService.getFileUrl(widget.docId);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              _isPdf
                  ? (_showRawText ? 'Extracted Text View' : 'Original PDF View')
                  : 'Document Reader & AI Companion',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
        actions: [
          // If it's a PDF, allow user to toggle between real PDF and formatted text view
          if (_isPdf)
            IconButton(
              tooltip: _showRawText
                  ? 'Switch to Original PDF'
                  : 'Switch to Text View',
              icon: Icon(
                _showRawText
                    ? Icons.picture_as_pdf_rounded
                    : Icons.text_snippet_outlined,
                color: const Color(0xFF4F46E5),
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _showRawText = !_showRawText;
                });
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF4F46E5),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.menu_book_rounded, size: 18),
              text: 'Document',
            ),
            Tab(icon: Icon(Icons.auto_awesome, size: 18), text: 'AI Summary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Document View (Real PDF if PDF, or formatted paper view)
          _isPdf && !_showRawText && !_pdfLoadFailed
              ? _buildRealPdfView()
              : _buildDocumentTextView(),

          // TAB 2: AI Summary & Takeaways View
          _buildSummaryInsightsView(),
        ],
      ),
    );
  }

  // Real PDF Reader View using SfPdfViewer
  Widget _buildRealPdfView() {
    final effectiveUrl = _getEffectiveFileUrl();
    final hasSource =
        _loadedBytes != null ||
        (!kIsWeb && widget.filePath != null) ||
        effectiveUrl.isNotEmpty;

    if (!hasSource) {
      return _buildDocumentTextView();
    }

    return Column(
      children: [
        // Top PDF Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Page Navigator
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                tooltip: 'Previous Page',
                onPressed: _currentPage > 1
                    ? () => _pdfViewerController.previousPage()
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Page $_currentPage of $_pageCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                tooltip: 'Next Page',
                onPressed: _currentPage < _pageCount
                    ? () => _pdfViewerController.nextPage()
                    : null,
              ),

              const Spacer(),

              // Zoom Controls
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                tooltip: 'Zoom Out',
                onPressed: () {
                  final newZoom = (_pdfViewerController.zoomLevel - 0.25)
                      .clamp(1.0, 3.0);
                  _pdfViewerController.zoomLevel = newZoom;
                },
              ),
              IconButton(
                icon: const Icon(Icons.fit_screen_rounded, size: 20),
                tooltip: 'Reset Zoom',
                onPressed: () {
                  _pdfViewerController.zoomLevel = 1.0;
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                tooltip: 'Zoom In',
                onPressed: () {
                  final newZoom = (_pdfViewerController.zoomLevel + 0.25)
                      .clamp(1.0, 3.0);
                  _pdfViewerController.zoomLevel = newZoom;
                },
              ),
            ],
          ),
        ),

        // PDF View Body
        Expanded(
          child: Stack(
            children: [
              _buildSfPdfViewer(effectiveUrl),
              if (_isLoadingPdf)
                Container(
                  color: Colors.white,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF4F46E5),
                          strokeWidth: 2.5,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'Loading original PDF...',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildSfPdfViewer(String effectiveUrl) {
    if (_loadedBytes != null) {
      return SfPdfViewer.memory(
        _loadedBytes!,
        controller: _pdfViewerController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          if (mounted) {
            setState(() {
              _pageCount = details.document.pages.count;
              _isLoadingPdf = false;
            });
          }
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          if (mounted) {
            setState(() {
              _pdfLoadFailed = true;
              _isLoadingPdf = false;
              _pdfLoadError = details.description;
            });
          }
        },
        onPageChanged: (PdfPageChangedDetails details) {
          if (mounted) {
            setState(() {
              _currentPage = details.newPageNumber;
            });
          }
        },
      );
    }

    if (!kIsWeb && widget.filePath != null && File(widget.filePath!).existsSync()) {
      return SfPdfViewer.file(
        File(widget.filePath!),
        controller: _pdfViewerController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          if (mounted) {
            setState(() {
              _pageCount = details.document.pages.count;
              _isLoadingPdf = false;
            });
          }
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          if (mounted) {
            setState(() {
              _pdfLoadFailed = true;
              _isLoadingPdf = false;
              _pdfLoadError = details.description;
            });
          }
        },
        onPageChanged: (PdfPageChangedDetails details) {
          if (mounted) {
            setState(() {
              _currentPage = details.newPageNumber;
            });
          }
        },
      );
    }

    if (effectiveUrl.isNotEmpty) {
      return SfPdfViewer.network(
        effectiveUrl,
        controller: _pdfViewerController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          if (mounted) {
            setState(() {
              _pageCount = details.document.pages.count;
              _isLoadingPdf = false;
            });
          }
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          if (mounted) {
            setState(() {
              _pdfLoadFailed = true;
              _isLoadingPdf = false;
              _pdfLoadError = details.description;
            });
          }
        },
        onPageChanged: (PdfPageChangedDetails details) {
          if (mounted) {
            setState(() {
              _currentPage = details.newPageNumber;
            });
          }
        },
      );
    }

    return _buildDocumentTextView();
  }

  // Formatted Text View (Fallback or user chosen reading mode)
  Widget _buildDocumentTextView() {
    final displayText = (_fullText != null && _fullText!.trim().isNotEmpty)
        ? _fullText!
        : ((widget.fullContent != null && widget.fullContent!.trim().isNotEmpty)
            ? widget.fullContent!
            : widget.summary);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 750),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Color(0xFFEF4444),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Copy Text',
                    color: const Color(0xFF64748B),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: displayText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Document text copied to clipboard!'),
                          backgroundColor: Color(0xFF059669),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),

              if (_pdfLoadFailed && _isPdf) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFD97706),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _pdfLoadError != null
                              ? 'Displaying extracted content from PDF ($widget.fileName).'
                              : 'Displaying extracted content from PDF.',
                          style: const TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 32, color: Color(0xFFF1F5F9)),

              // Extracted Document Text
              SelectableText(
                displayText,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.8,
                  color: Color(0xFF334155),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tab 2: AI Summary & Key Takeaways
  Widget _buildSummaryInsightsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 750),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                      'AI Summarized',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Copy Summary',
                    color: const Color(0xFF64748B),
                    onPressed: () {
                      final summaryCopy = '${widget.summary}\n\nKey Points:\n${widget.keyTakeaways.map((p) => '• $p').join('\n')}';
                      Clipboard.setData(ClipboardData(text: summaryCopy));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Summary copied to clipboard!'),
                          backgroundColor: Color(0xFF059669),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'EXECUTIVE SUMMARY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                widget.summary,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF334155),
                ),
              ),
              if (widget.keyTakeaways.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...widget.keyTakeaways.map(
                        (point) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '• ',
                                style: TextStyle(
                                  color: Color(0xFF4F46E5),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: SelectableText(
                                  point,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onConvertToFlashcards?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.style_outlined, size: 20),
                  label: Text(
                    'Convert to ${widget.keyTakeaways.length > 1 ? widget.keyTakeaways.length : 3} Revision Flashcards',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
