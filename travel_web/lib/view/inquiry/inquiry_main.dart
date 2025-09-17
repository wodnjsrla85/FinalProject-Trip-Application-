import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:travel_web/model/InquiryModel.dart';
import 'inquiry_reply.dart';

class InquiryMain extends StatelessWidget {
  const InquiryMain({super.key});

  // --- Dashboard와 동일한 색상 팔레트 ---
  final Color primaryColor = const Color(0xFF2C5AA0);      // 진한 파란색
  final Color secondaryColor = const Color(0xFF5B8A2A);    // 진한 초록색
  final Color tertiaryColor = const Color(0xFFE67E22);     // 진한 주황색
  final Color lightGray = const Color(0xFFF8F9FA);         // 밝은 배경
  final Color mediumGray = const Color(0xFFDEE2E6);        // 진한 경계선
  final Color darkText = const Color(0xFF2C3E50);          // 진한 텍스트

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        title: Text(
          "문의 관리",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 4,
        shadowColor: primaryColor.withOpacity(0.3),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 페이지 제목
            Text(
              "접수된 문의 목록",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "고객들의 문의사항을 확인하고 답변을 작성하세요",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),

            // 문의 목록
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('inquery')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc = snapshot.data!.docs[index];
                      InquiryModel inquiry = InquiryModel.fromFirebase(doc);
                      return _buildInquiryCard(context, inquiry);
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- 로딩 상태 ---
  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mediumGray, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              spreadRadius: 3,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              "문의 목록을 불러오는 중...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 오류 상태 ---
  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mediumGray, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              spreadRadius: 3,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 64),
            SizedBox(height: 16),
            Text(
              "데이터 로딩 오류",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- 빈 상태 ---
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mediumGray, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              spreadRadius: 3,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[500]),
            SizedBox(height: 16),
            Text(
              "접수된 문의가 없습니다",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "고객들의 문의가 등록되면 여기에 표시됩니다",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 문의 카드 ---
  Widget _buildInquiryCard(BuildContext context, InquiryModel inquiry) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mediumGray, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            spreadRadius: 3,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(20),
        // 왼쪽 아이콘
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: inquiry.isAnswered() ? secondaryColor : tertiaryColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            inquiry.isAnswered() ? Icons.check_circle : Icons.schedule,
            color: Colors.white,
            size: 24,
          ),
        ),
        // 제목과 내용
        title: Text(
          inquiry.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: darkText,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              inquiry.getShortContent(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.3,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  inquiry.uEmail,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(width: 12),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  inquiry.getShortDate(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상태 칩
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: inquiry.isAnswered() 
                    ? secondaryColor.withOpacity(0.1) 
                    : tertiaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: inquiry.isAnswered() ? secondaryColor : tertiaryColor,
                  width: 1,
                ),
              ),
              child: Text(
                inquiry.state,
                style: TextStyle(
                  color: inquiry.isAnswered() ? secondaryColor : tertiaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 8),
            // 삭제 버튼
            IconButton(
              onPressed: () => _deleteInquiry(context, inquiry),
              icon: Icon(Icons.delete_outline),
              color: Colors.red[600],
              tooltip: '문의 삭제',
            ),
          ],
        ),
        // 카드 클릭
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InquiryReply(inquiry: inquiry),
            ),
          );
        },
      ),
    );
  }

  // --- 문의 삭제 ---
  _deleteInquiry(BuildContext context, InquiryModel inquiry) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange[600]),
              SizedBox(width: 12),
              Text(
                '문의 삭제',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
            ],
          ),
          content: Text(
            '이 문의를 삭제하시겠습니까?\n\n삭제된 데이터는 복구할 수 없습니다.',
            style: TextStyle(color: darkText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('inquery')
                    .doc(inquiry.id)
                    .delete();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text("문의가 삭제되었습니다"),
                      ],
                    ),
                    backgroundColor: secondaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('삭제'),
            ),
          ],
        );
      },
    );
  }
}
