import 'package:flutter/material.dart';
import 'package:studymate_ai/repo/chat_service.dart';
import 'package:studymate_ai/repo/user_session.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}

class ChataitutorScreen extends StatefulWidget {
  final int? userId;
  final String? userName;

  const ChataitutorScreen({super.key, this.userId, this.userName});

  @override
  State<ChataitutorScreen> createState() => _ChataitutorScreenState();
}

class _ChataitutorScreenState extends State<ChataitutorScreen> {
  int? _userId;
  final TextEditingController _messageContriller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _quickPrompts = [
    'Summarize this PDF',
    'Explain the key concepts',
    'Create a study plan',
    'Quiz me on this material',
  ];
  bool _isTyping = false;
  int? _activeSessionId;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hello! I am your AI Study Tutor. Ask me any doubts on Your Pdf",
      isUser: false,
      time: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    _initUserId();
  }

  Future<void> _initUserId() async {
    if (_userId == null) {
      _userId = await UserSession.getUserId();
    }
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = customText ?? _messageContriller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, time: DateTime.now()),
      );
      _isTyping = true;
    });

    _messageContriller.clear();
    _scrollToBottom();

    final effectiveId = _userId ?? await UserSession.getUserId();
    final result = await ChatService.sendMessage(
      message: text,
      sessionId: _activeSessionId,
      userId: effectiveId,
    );

    if (!mounted) return;

    setState(() {
      _isTyping = false;
      if (result['session_id'] != null) {
        _activeSessionId = result['session_id'];
      }
      _messages.add(
        ChatMessage(text: result['reply'], isUser: false, time: DateTime.now()),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageContriller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'StudyMate AI Tutor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 3.5,
                      backgroundColor: Color(0xFF10B981),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Online & Ready',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
            onPressed: () {
              setState(() {
                _activeSessionId = null;
                _messages.clear();
                _messages.add(
                  ChatMessage(
                    text: "New session started! What would you like to learn?",
                    isUser: false,
                    time: DateTime.now(),
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(context, _messages[index]);
                },
              ),
            ),
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 8),
                child: Row(
                  children: const [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AI Tutor is typing...',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),

            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return ActionChip(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    label: Text(
                      _quickPrompts[i],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334155),
                      ),
                    ),
                    onPressed: () => _sendMessage(_quickPrompts[i]),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageContriller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Ask anything to AI Tutor...',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _sendMessage(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
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

Widget _buildMessageBubble(BuildContext context, ChatMessage msg) {
  return Align(
    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      decoration: BoxDecoration(
        color: msg.isUser ? const Color(0xFF4F46E5) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
          bottomRight: Radius.circular(msg.isUser ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SelectableText(
        msg.text,
        style: TextStyle(
          color: msg.isUser ? Colors.white : const Color(0xFF0F172A),
          fontSize: 14,
          height: 1.4,
        ),
      ),
    ),
  );
}
