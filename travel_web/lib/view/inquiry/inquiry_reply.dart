// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:travel_web/model/InquiryModel.dart';

class InquiryReply extends StatefulWidget {
  final InquiryModel inquiry;
    
  InquiryReply({required this.inquiry});
  
  @override
  State<InquiryReply> createState() => _InquiryReplyState();
}

class _InquiryReplyState extends State<InquiryReply> {
  // --- Dashboard와 동일한 색상 팔레트 ---
  final Color primaryColor = Color(0xFF2C5AA0);
  final Color secondaryColor = Color(0xFF5B8A2A);
  final Color tertiaryColor = Color(0xFFE67E22);
  final Color lightGray = Color(0xFFF8F9FA);
  final Color mediumGray = Color(0xFFDEE2E6);
  final Color darkText = Color(0xFF2C3E50);

  final TextEditingController replyController = TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();  
    if (widget.inquiry.reply != null) {
      replyController.text = widget.inquiry.reply!;
    }
  }

  @override
  void dispose() {
    replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        title: Text(
          "문의 답변",
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 페이지 제목
              Text(
                "고객 문의 답변",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "고객의 문의사항을 확인하고 정중한 답변을 작성하세요",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 32),

              // 원본 문의 내용
              _buildOriginalInquiry(),
              SizedBox(height: 24),

              // 답변 입력 섹션
              _buildReplySection(),
            ],
          ),
        ),
      ),
    );
  }

  // --- 원본 문의 표시 ---
  Widget _buildOriginalInquiry() {
    return Container(
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
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.question_answer,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "접수된 문의",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.inquiry.isAnswered() 
                        ? secondaryColor.withOpacity(0.1) 
                        : tertiaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.inquiry.isAnswered() ? secondaryColor : tertiaryColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.inquiry.state,
                    style: TextStyle(
                      color: widget.inquiry.isAnswered() ? secondaryColor : tertiaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            Divider(height: 32, color: mediumGray),

            // 문의 정보들
            _buildInfoRow("제목", widget.inquiry.title, Icons.title),
            _buildInfoRow("문의자", widget.inquiry.uEmail, Icons.person),
            _buildInfoRow("문의 대상", widget.inquiry.to, Icons.business),
            _buildInfoRow("작성일", widget.inquiry.getShortDate(), Icons.calendar_today),
            
            SizedBox(height: 20),

            // 문의 내용
            Row(
              children: [
                Icon(Icons.message, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  "문의 내용:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: darkText,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: mediumGray.withOpacity(0.5)),
              ),
              child: Text(
                widget.inquiry.content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: darkText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // --- 정보 행 ---
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: darkText,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
    
  // --- 답변 섹션 ---
  Widget _buildReplySection(){
    return Container(
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
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: secondaryColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  '답변 작성',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // 답변 입력창
            TextField(
              controller: replyController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: "고객님께 정중하고 도움이 되는 답변을 작성해주세요.\n\n• 문제에 대한 명확한 해결책 제시\n• 친절하고 전문적인 어조 사용\n• 추가 문의가 있을 경우 연락처 안내",
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  height: 1.4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: mediumGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: mediumGray),
                ),
                contentPadding: EdgeInsets.all(16),
                fillColor: Colors.white,
                filled: true,
              ),
              style: TextStyle(fontSize: 14, height: 1.4),
              onChanged: (value) {
                setState(() {});
              },
            ),
            SizedBox(height: 12),

            // 글자수 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  replyController.text.length < 10 
                      ? "최소 10자 이상 작성해주세요" 
                      : "적절한 길이의 답변입니다",
                  style: TextStyle(
                    color: replyController.text.length < 10 
                        ? tertiaryColor 
                        : secondaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${replyController.text.length}자',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // 답변 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _saveReply,
                icon: isSaving 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.send, size: 20),
                label: Text(
                  isSaving ? "답변 저장 중..." : "답변 저장하기",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSaving ? Colors.grey : secondaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: secondaryColor.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // --- 답변 저장 ---
  Future<void> _saveReply() async {
    String replyText = replyController.text.trim();

    if (replyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text("답변 내용을 입력해주세요."),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    if (replyText.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text("답변을 10자 이상 작성해주세요"),
            ],
          ),
          backgroundColor: tertiaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('inquery')
          .doc(widget.inquiry.id)
          .update({
        'reply': replyText,
        'replyDate': DateTime.now().toIso8601String(),
        'state': '답변완료'
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text("답변이 성공적으로 저장되었습니다."),
            ],
          ),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      Navigator.pop(context);
      
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text("저장 중 오류가 발생했습니다: $e")),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }
}
