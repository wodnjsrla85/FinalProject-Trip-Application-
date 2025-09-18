// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:travel_web/model/InquiryModel.dart';
import 'inquiry_reply.dart';

class InquiryMain extends StatelessWidget {
  const InquiryMain({super.key});

  // 색상 정의
  final Color blueColor = const Color(0xFF2C5AA0);        
  final Color greenColor = const Color(0xFF5B8A2A);       
  final Color orangeColor = const Color(0xFFE67E22);      
  final Color backgroundGray = const Color(0xFFF8F9FA);   
  final Color borderGray = const Color(0xFFDEE2E6);       
  final Color textBlack = const Color(0xFF2C3E50);        

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        title: Text(
          "문의 관리",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: orangeColor,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        titleSpacing: 0, // 왼쪽 공백 제거
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildPageHeader(),
            SizedBox(height: 24),

            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('inquery')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return buildLoadingWidget();
                  }

                  if (snapshot.hasError) {
                    return buildErrorWidget(snapshot.error.toString());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return buildEmptyWidget();
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot doc = snapshot.data!.docs[index];
                      InquiryModel inquiry = InquiryModel.fromFirebase(doc);
                      return buildInquiryCard(context, inquiry);
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

  // 페이지 상단 헤더
  Widget buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "접수된 문의 목록",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textBlack,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "고객들의 문의사항을 확인하고 답변을 작성하세요",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // 문의 카드 위젯
  Widget buildInquiryCard(BuildContext context, InquiryModel inquiry) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => InquiryReply(inquiry: inquiry)),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                buildStatusIcon(inquiry),
                SizedBox(width: 16),
                buildInquiryContent(inquiry),
                buildActionButtons(context, inquiry),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 문의 상태 아이콘
  Widget buildStatusIcon(InquiryModel inquiry) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: inquiry.isAnswered() 
            ? greenColor.withOpacity(0.6) 
            : orangeColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        inquiry.isAnswered() ? Icons.check_circle : Icons.schedule,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  // 문의 내용 영역
  Widget buildInquiryContent(InquiryModel inquiry) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            inquiry.title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: textBlack,
            ),
          ),
          SizedBox(height: 8),
          Text(
            inquiry.getShortContent(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12),
          buildInquiryInfo(inquiry),
        ],
      ),
    );
  }

  // 문의 정보 (작성자, 날짜)
  Widget buildInquiryInfo(InquiryModel inquiry) {
    return Row(
      children: [
        Icon(Icons.person, size: 14, color: Colors.grey[600]),
        SizedBox(width: 4),
        Flexible(
          child: Text(
            inquiry.uEmail,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 12),
        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
        SizedBox(width: 4),
        Text(
          inquiry.getShortDate(),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // 액션 버튼들 (상태칩, 삭제버튼)
  Widget buildActionButtons(BuildContext context, InquiryModel inquiry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        buildStatusChip(inquiry),
        SizedBox(height: 12),
        buildDeleteButton(context, inquiry),
      ],
    );
  }

  // 상태 칩
  Widget buildStatusChip(InquiryModel inquiry) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: inquiry.isAnswered() 
            ? greenColor.withOpacity(0.1) 
            : orangeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: inquiry.isAnswered() 
              ? greenColor.withOpacity(0.6) 
              : orangeColor.withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Text(
        inquiry.state,
        style: TextStyle(
          color: inquiry.isAnswered() ? greenColor : orangeColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // 삭제 버튼
  Widget buildDeleteButton(BuildContext context, InquiryModel inquiry) {
    return GestureDetector(
      onTap: () => showDeleteDialog(context, inquiry),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.red[300]!,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.delete_outline,
          color: Colors.red[600],
          size: 16,
        ),
      ),
    );
  }

  // 로딩 상태 위젯
  Widget buildLoadingWidget() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: buildCardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              "문의 목록을 불러오는 중...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 오류 상태 위젯
  Widget buildErrorWidget(String error) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: buildCardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 64),
            SizedBox(height: 16),
            Text(
              "데이터 로딩 오류",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textBlack,
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

  // 빈 상태 위젯
  Widget buildEmptyWidget() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: buildCardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline, size: 64, color: Colors.grey[500]),
            SizedBox(height: 16),
            Text(
              "접수된 문의가 없습니다",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textBlack,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "고객들의 문의가 등록되면 여기에 표시됩니다",
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

  // 공통 카드 데코레이션
  BoxDecoration buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderGray, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 3,
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  // 삭제 확인 다이얼로그
  void showDeleteDialog(BuildContext context, InquiryModel inquiry) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: buildDialogTitle(),
          content: buildDialogContent(),
          actions: buildDialogActions(context, inquiry),
        );
      },
    );
  }

  // 다이얼로그 제목
  Widget buildDialogTitle() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.warning_amber, color: Colors.orange[600], size: 20),
        ),
        SizedBox(width: 12),
        Text(
          '문의 삭제',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textBlack,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  // 다이얼로그 내용
  Widget buildDialogContent() {
    return Text(
      '이 문의를 삭제하시겠습니까?\n\n삭제된 데이터는 복구할 수 없습니다.',
      style: TextStyle(color: textBlack, fontSize: 14),
    );
  }

  // 다이얼로그 액션 버튼들
  List<Widget> buildDialogActions(BuildContext context, InquiryModel inquiry) {
    return [
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderGray, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text('취소'),
        ),
      ),
      SizedBox(width: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.red[600],
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextButton(
          onPressed: () => deleteInquiry(context, inquiry),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text('삭제'),
        ),
      ),
    ];
  }

  // 문의 삭제 실행
  Future<void> deleteInquiry(BuildContext context, InquiryModel inquiry) async {
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
        backgroundColor: greenColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
