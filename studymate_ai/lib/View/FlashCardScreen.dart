import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:studymate_ai/repo/user_session.dart';

class FlashcardItem {
  final String id;
  final String subject;
  final String question;
  final String answer;

  FlashcardItem({
    required this.id,
    required this.subject,
    required this.question,
    required this.answer,
  });
}

class FlashCardScreen extends StatefulWidget {
  final int? userId;
  final VoidCallback? onBack;

  const FlashCardScreen({super.key, this.userId, this.onBack});

  @override
  State<FlashCardScreen> createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen> {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

  int? _userId;
  int _selectedTabIndex = 0; // 0: Practice Flip Mode, 1: Manage Cards
  int _currentCardIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = false;

  // Dynamic Flashcards List
  final List<FlashcardItem> _flashcards = [];

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
    _fetchUserFlashcards();
  }

  // Backend kadun flashcards fetch karne (GET /api/v1/flashcards/?user_id=...)
  Future<void> _fetchUserFlashcards() async {
    try {
      final effectiveId = _userId ?? await UserSession.getUserId();
      final query = effectiveId != null ? '?user_id=$effectiveId' : '';
      final url = Uri.parse('$baseUrl/flashcards/$query');
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _flashcards.clear();
          for (var item in data) {
            _flashcards.add(
              FlashcardItem(
                id: item['id'].toString(),
                subject: item['subject'] ?? 'General',
                question: item['question'] ?? '',
                answer: item['answer'] ?? '',
              ),
            );
          }
        });
      }
    } catch (e) {
      debugPrint("Flashcards fetch error: $e");
    }
  }

  // Backend la new card post karne (POST /api/v1/flashcards/)
  Future<void> _createCardOnBackend(
    String subject,
    String question,
    String answer,
  ) async {
    try {
      final effectiveId = _userId ?? (await UserSession.getUserId()) ?? 1;
      final url = Uri.parse('$baseUrl/flashcards/');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': effectiveId,
          'subject': subject,
          'question': question,
          'answer': answer,
        }),
      );
    } catch (e) {
      debugPrint("Backend flashcard create error: $e");
    }
  }

  // Next card var jane
  void _nextCard() {
    setState(() {
      _showAnswer = false;
      if (_currentCardIndex < _flashcards.length - 1) {
        _currentCardIndex++;
      } else {
        _currentCardIndex = 0; // Cycle reset
      }
    });
  }

  void _showEditCardBottomSheet(FlashcardItem card, int index) {
    final subjectController = TextEditingController(text: card.subject);
    final questionController = TextEditingController(text: card.question);
    final answerController = TextEditingController(text: card.answer);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Flashcard',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Subject / Topic Tag',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Question / Concept',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: questionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Answer / Summary Explanation',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: answerController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final qText = questionController.text.trim();
                          final aText = answerController.text.trim();
                          final sText = subjectController.text.trim().isEmpty
                              ? 'General'
                              : subjectController.text.trim();

                          if (qText.isEmpty || aText.isEmpty) return;

                          setState(() {
                            _flashcards[index] = FlashcardItem(
                              id: card.id,
                              subject: sText,
                              question: qText,
                              answer: aText,
                            );
                          });

                          Navigator.pop(context);

                          // Backend API Update call (PUT /api/v1/flashcards/{id})
                          try {
                            final url = Uri.parse(
                              '$baseUrl/flashcards/${card.id}',
                            );
                            await http.put(
                              url,
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'subject': sText,
                                'question': qText,
                                'answer': aText,
                              }),
                            );
                          } catch (e) {
                            debugPrint("Update error: $e");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 1. DELETE CARD DIRECT FROM DB
  Future<void> _deleteFlashcard(String cardId, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete Flashcard?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Kya aap sach me is flashcard ko permanently delete karna chahte hain?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final url = Uri.parse('$baseUrl/flashcards/$cardId');
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        // Database se delete hote hi fresh list fetch karo
        await _fetchUserFlashcards();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card has Succesfuly from database'),
            backgroundColor: Color.fromARGB(255, 55, 194, 110),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  // 2. UPDATE CARD DIRECT IN DB
  Future<void> _updateCardOnBackend(
    String cardId,
    String subject,
    String question,
    String answer,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/flashcards/$cardId');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subject': subject,
          'question': question,
          'answer': answer,
        }),
      );

      if (response.statusCode == 200) {
        // Database me update hone ke baad DB se fresh reload karo
        await _fetchUserFlashcards();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card database me update ho gaya!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

  void _showCreateCardBottomSheet() {
    final subjectController = TextEditingController(text: 'Operating Systems');
    final questionController = TextEditingController();
    final answerController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title and Close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create New Flashcard',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Field 1: Subject / Topic Tag
                const Text(
                  'Subject / Topic Tag',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Field 2: Question / Concept
                const Text(
                  'Question / Concept',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: questionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter the prompt or question...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Field 3: Answer / Summary Explanation
                const Text(
                  'Answer / Summary Explanation',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: answerController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter the concise answer...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons: Cancel and Create Card
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final qText = questionController.text.trim();
                          final aText = answerController.text.trim();
                          final sText = subjectController.text.trim().isEmpty
                              ? 'General'
                              : subjectController.text.trim();

                          if (qText.isEmpty || aText.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Question ani Answer donhi fill kara!',
                                ),
                              ),
                            );
                            return;
                          }

                          final newCard = FlashcardItem(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            subject: sText,
                            question: qText,
                            answer: aText,
                          );

                          setState(() {
                            _flashcards.add(newCard);
                            _currentCardIndex = _flashcards.length - 1;
                            _showAnswer = false;
                          });

                          Navigator.pop(context);
                          await _createCardOnBackend(sText, qText, aText);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Create Card',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCards = _flashcards.isNotEmpty;
    final currentCard = hasCards ? _flashcards[_currentCardIndex] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1E293B),
                  size: 18,
                ),
                onPressed: widget.onBack,
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Flashcard Decks',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Active Recall & Deck Manager',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showCreateCardBottomSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'New Card',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Selector Bar (Practice Flip Mode / Manage Cards)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedTabIndex == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                  ),
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Practice Flip Mode',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _selectedTabIndex == 0
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedTabIndex == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                  ),
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Manage Cards (${_flashcards.length})',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _selectedTabIndex == 1
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_selectedTabIndex == 0) ...[
              if (!hasCards)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: const [
                        Icon(
                          Icons.style_outlined,
                          size: 48,
                          color: Color(0xFF94A3B8),
                        ),
                        SizedBox(height: 12),
                        Text('No flashcards yet. Tap "+ New Card" to add one!'),
                      ],
                    ),
                  ),
                )
              else ...[
                // Subject title and card counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentCard!.subject,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Card ${_currentCardIndex + 1} / ${_flashcards.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Linear Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentCardIndex + 1) / _flashcards.length,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: const Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(height: 16),

                // Flashcard Interactive Box
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showAnswer = !_showAnswer;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 280),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                color: _showAnswer
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _showAnswer ? 'ANSWER' : 'QUESTION',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: _showAnswer
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF4F46E5),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.refresh_rounded,
                              size: 20,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Column(
                            children: [
                              Text(
                                _showAnswer
                                    ? currentCard.answer
                                    : currentCard.question,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: _showAnswer ? 15 : 18,
                                  fontWeight: FontWeight.w700,
                                  height: 1.45,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _showAnswer
                                    ? 'Tap anywhere to hide answer'
                                    : 'Tap anywhere to reveal answer',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: Color(0xFF6366F1),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Spaced Repetition Active',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons: Revise Again / Got It
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _nextCard,
                          icon: const Icon(
                            Icons.refresh,
                            size: 17,
                            color: Color(0xFFEF4444),
                          ),
                          label: const Text(
                            'Revise Again',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEF2F2),
                            side: const BorderSide(color: Color(0xFFFEE2E2)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _nextCard,
                          icon: const Icon(
                            Icons.check,
                            size: 17,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Got It (Easy)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              // Manage Cards View
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _flashcards.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final card = _flashcards[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag ani Actions (Edit & Delete)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                card.subject,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                // Edit Button
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: Color(0xFF4F46E5),
                                  ),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  splashRadius: 18,
                                  onPressed: () =>
                                      _showEditCardBottomSheet(card, index),
                                ),
                                const SizedBox(width: 4),
                                // Delete Button
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Color(0xFFEF4444),
                                  ),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  splashRadius: 18,
                                  onPressed: () =>
                                      _deleteFlashcard(card.id, index),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          card.question,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          card.answer,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
