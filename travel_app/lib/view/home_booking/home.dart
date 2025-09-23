import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/Widget/flight_result.dart';
import 'package:travel_app/Widget/flight_search.dart';
import 'package:travel_app/Widget/package_widget.dart';
import 'package:travel_app/Widget/user_info.dart';
import 'package:travel_app/view/home_booking/chat_bot_bottom_sheet.dart';
import 'package:travel_app/vm/home_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ======================
// 챗 메시지 모델
// ======================
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// ======================
// 홈 화면
// ======================
class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchStateProvider);
    final flights = ref.watch(flightsProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D29),
      body: CustomScrollView(
        slivers: [
          // 커스텀 앱바 - 다크 테마
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1A1D29),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1D29),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 헤더 섹션
                        Row(
                          children: [
                            // 유저 프로필
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[300],
                                image: user?.photoURL != null 
                                    ? DecorationImage(
                                        image: NetworkImage(user!.photoURL!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: user?.photoURL == null 
                                  ? const Icon(Icons.person, color: Colors.grey, size: 24)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Good Morning",
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    user?.displayName ?? "Traveler",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 알림 버튼
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // 메인 타이틀
                        const Text(
                          "Securely Book\nyour Flight Ticket",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              collapseMode: CollapseMode.pin,
            ),
          ),

          // 메인 콘텐츠
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    
                    // 항공편 검색 카드 - 새 디자인
                    Container(
                      decoration: _modernCardDecoration(),
                      child: const FlightSearch(),
                    ),
                    const SizedBox(height: 24),

                    // 검색 결과 섹션
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: searchState
                          ? Container(
                              key: ValueKey(flights.hashCode),
                              decoration: _modernCardDecoration(),
                              child: const FlightResult(),
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),

                    if (searchState) const SizedBox(height: 24),

                

                    // 여행 패키지 섹션
                    Container(
                      decoration: _modernCardDecoration(),
                      child: const PackageWidget(),
                    ),

                    const SizedBox(height: 24),

                    // 추가 서비스 카드들 - 모던 스타일
                    _buildModernServiceCards(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // 플로팅 액션 버튼 - 챗봇
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showChatBot(context),
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.chat_bubble, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  // 모던 카드 데코레이션
  BoxDecoration _modernCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // Upcoming flights 섹션
  Widget _buildUpcomingFlights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Upcoming flights",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A202C),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                "See All",
                style: TextStyle(
                  color: Color(0xFF667EEA),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _modernCardDecoration(),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flight,
                  color: Color(0xFF667EEA),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Canada Airways",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Toronto → Vancouver",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                "\$550",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A202C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showChatBot(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChatBotBottomSheet(),
    );
  }

  // 모던 서비스 카드들
  Widget _buildModernServiceCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            "Travel Services",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A202C),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildModernServiceCard(
                "Check-in",
                "Online check-in available",
                Icons.flight_takeoff,
                const Color(0xFF667EEA),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernServiceCard(
                "Flight Status",
                "Track your flight",
                Icons.schedule,
                const Color(0xFF48BB78),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildModernServiceCard(
                "Baggage",
                "Check allowance",
                Icons.luggage,
                const Color(0xFFED8936),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernServiceCard(
                "Loyalty",
                "Earn miles",
                Icons.card_giftcard,
                const Color(0xFF9F7AEA),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernServiceCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF718096),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================
// 챗봇 바텀시트
// ======================
// class ChatBotBottomSheet extends StatefulWidget {
//   const ChatBotBottomSheet({super.key});

//   @override
//   State<ChatBotBottomSheet> createState() => _ChatBotBottomSheetState();
// }

// class _ChatBotBottomSheetState extends State<ChatBotBottomSheet> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _chatScrollController = ScrollController();
//   final List<ChatMessage> _messages = [];
//   bool _isLoading = false;

//   static const String _apiBaseUrl = 'https://ccee97d9a988.ngrok-free.app';

//   @override
//   void dispose() {
//     _endSession();
//     _messageController.dispose();
//     _chatScrollController.dispose();
//     _messages.clear();
//     super.dispose();
//   }

//   Future<void> _sendMessage(String message) async {
//     if (message.trim().isEmpty) return;

//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       setState(() {
//         _messages.add(ChatMessage(text: '⚠️ 로그인 후 이용해주세요.', isUser: false, timestamp: DateTime.now()));
//       });
//       return;
//     }

//     setState(() {
//       _messages.add(ChatMessage(text: message, isUser: true, timestamp: DateTime.now()));
//       _isLoading = true;
//     });

//     _messageController.clear();
//     _scrollToBottom();

//     try {
//       final response = await http.post(
//         Uri.parse('$_apiBaseUrl/chat'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'session_id': user.uid,
//           'query': message,
//         }),
//       );

//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         setState(() {
//           _messages.add(ChatMessage(
//             text: responseData['answer'] ?? '응답 없음',
//             isUser: false,
//             timestamp: DateTime.now(),
//           ));
//         });
//       } else {
//         setState(() {
//           _messages.add(ChatMessage(text: '⚠️ 서버 오류: ${response.statusCode}', isUser: false, timestamp: DateTime.now()));
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _messages.add(ChatMessage(text: '⚠️ 네트워크 오류: $e', isUser: false, timestamp: DateTime.now()));
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//       _scrollToBottom();
//     }
//   }

//   Future<void> _endSession() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     try {
//       await http.post(
//         Uri.parse('$_apiBaseUrl/end_session'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({'session_id': user.uid}),
//       );
//       debugPrint("✅ 세션 종료 완료 (session_id: ${user.uid})");
//     } catch (e) {
//       debugPrint("⚠️ 세션 종료 실패: $e");
//     }
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_chatScrollController.hasClients) {
//         _chatScrollController.animateTo(
//           _chatScrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.8,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(25),
//           topRight: Radius.circular(25),
//         ),
//       ),
//       child: Column(
//         children: [
//           // 핸들바
//           Container(
//             margin: const EdgeInsets.only(top: 12, bottom: 8),
//             width: 40,
//             height: 4,
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),

//           // 헤더 - 모던 스타일
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     gradient: const LinearGradient(
//                       colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//                     ),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: const Icon(Icons.support_agent, color: Colors.white, size: 24),
//                 ),
//                 const SizedBox(width: 16),
//                 const Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "AI Travel Assistant",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF1A202C),
//                         ),
//                       ),
//                       Text(
//                         "Ask me about flights, hotels, or travel tips",
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Color(0xFF718096),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     shape: BoxShape.circle,
//                   ),
//                   child: IconButton(
//                     onPressed: () => Navigator.of(context).pop(),
//                     icon: const Icon(Icons.close, color: Color(0xFF718096), size: 20),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // 채팅 영역
//           Expanded(
//             child: _messages.isEmpty
//                 ? _buildModernEmptyState()
//                 : ListView.builder(
//                     controller: _chatScrollController,
//                     padding: const EdgeInsets.all(20),
//                     itemCount: _messages.length + (_isLoading ? 1 : 0),
//                     itemBuilder: (context, index) {
//                       if (index == _messages.length && _isLoading) {
//                         return _buildModernLoadingMessage();
//                       }
//                       return _buildModernMessageBubble(_messages[index]);
//                     },
//                   ),
//           ),

//           // 입력 영역 - 모던 스타일
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border(top: BorderSide(color: Colors.grey[100]!)),
//             ),
//             child: SafeArea(
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFF8FAFC),
//                         borderRadius: BorderRadius.circular(25),
//                         border: Border.all(color: Colors.grey[200]!),
//                       ),
//                       child: TextField(
//                         controller: _messageController,
//                         decoration: const InputDecoration(
//                           hintText: 'Ask me anything about travel...',
//                           hintStyle: TextStyle(color: Color(0xFF718096)),
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//                         ),
//                         maxLines: null,
//                         textInputAction: TextInputAction.send,
//                         onSubmitted: _sendMessage,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Container(
//                     decoration: BoxDecoration(
//                       gradient: const LinearGradient(
//                         colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//                       ),
//                       borderRadius: BorderRadius.circular(25),
//                     ),
//                     child: IconButton(
//                       onPressed: () => _sendMessage(_messageController.text),
//                       icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildModernEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   const Color(0xFF667EEA).withOpacity(0.1),
//                   const Color(0xFF764BA2).withOpacity(0.1),
//                 ],
//               ),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.chat_bubble_outline_rounded,
//               size: 48,
//               color: Color(0xFF667EEA),
//             ),
//           ),
//           const SizedBox(height: 24),
//           const Text(
//             "Start a conversation",
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.w700,
//               color: Color(0xFF1A202C),
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 40),
//             child: Text(
//               "I'm here to help you with flight bookings, travel tips, and destination recommendations",
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Color(0xFF718096),
//                 height: 1.4,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildModernLoadingMessage() {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 16),
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//         decoration: BoxDecoration(
//           color: const Color(0xFFF8FAFC),
//           borderRadius: BorderRadius.circular(25),
//           border: Border.all(color: Colors.grey[200]!),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             SizedBox(
//               width: 16,
//               height: 16,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2,
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Text(
//               'Thinking...',
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildModernMessageBubble(ChatMessage message) {
//     return Align(
//       alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 16),
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//         constraints: BoxConstraints(
//           maxWidth: MediaQuery.of(context).size.width * 0.75,
//         ),
//         decoration: BoxDecoration(
//           gradient: message.isUser
//               ? const LinearGradient(
//                   colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
//                 )
//               : null,
//           color: message.isUser ? null : const Color(0xFFF8FAFC),
//           borderRadius: BorderRadius.circular(25),
//           border: message.isUser ? null : Border.all(color: Colors.grey[200]!),
//         ),
//         child: Text(
//           message.text,
//           style: TextStyle(
//             color: message.isUser ? Colors.white : const Color(0xFF1A202C),
//             fontSize: 14,
//             height: 1.4,
//             fontWeight: FontWeight.w400,
//           ),  
//         ),
//       ),
//     );
//   }
// }