import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:travel_app/view/home_booking/home.dart';

class ChatBotBottomSheet extends StatefulWidget {
  const ChatBotBottomSheet({super.key});

  @override
  State<ChatBotBottomSheet> createState() => _ChatBotBottomSheetState();
}

class _ChatBotBottomSheetState extends State<ChatBotBottomSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  static const String _apiBaseUrl = 'https://22153bbc18ad.ngrok-free.app';

  @override
  void dispose() {
    _endSession();
    _messageController.dispose();
    _chatScrollController.dispose();
    _messages.clear();
    super.dispose();
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _messages.add(ChatMessage(
          text: '⚠️ 로그인 후 이용해주세요.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      return;
    }

    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'session_id': user.uid,
          'query': message,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _messages.add(ChatMessage(
            text: responseData['answer'] ?? '응답 없음',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: '⚠️ 서버 오류: ${response.statusCode}',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: '⚠️ 네트워크 오류: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _endSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await http.post(
        Uri.parse('$_apiBaseUrl/end_session'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'session_id': user.uid}),
      );
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // 핸들바
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003366), // 메인 블루
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.support_agent, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Travel Assistant",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                      Text(
                        "Ask me about flights, hotels, or travel tips",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF718096), size: 22),
                ),
              ],
            ),
          ),

          // 채팅 영역
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _chatScrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildLoadingMessage();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // 입력 영역
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[100]!)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Ask me anything about travel...',
                          hintStyle: TextStyle(color: Color(0xFF718096)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFFFD700), // 옐로우 버튼
                    child: IconButton(
                      onPressed: () => _sendMessage(_messageController.text),
                      icon: const Icon(Icons.send_rounded, color: Color(0xFF003366), size: 20), // 블루 아이콘
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF003366),
            child: Icon(Icons.chat_bubble_outline, size: 36, color: Colors.white),
          ),
          SizedBox(height: 20),
          Text(
            "Start a conversation",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A202C),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "I'm here to help you with flight bookings, travel tips, and destination recommendations",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF94A3B8)),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Thinking...',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFF003366) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: message.isUser ? null : Border.all(color: Colors.grey[200]!),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : const Color(0xFF1A202C),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
