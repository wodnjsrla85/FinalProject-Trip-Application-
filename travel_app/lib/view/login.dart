import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/view/join.dart';
import 'package:travel_app/view/main.dart';

class Login extends ConsumerWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final pwController = TextEditingController();

    // Login 함수
    Future<void> login() async{
      try{
        final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(), 
          password: pwController.text.trim()
        );

        final user = result.user;

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Main(),)
        );

        
      } on FirebaseAuthException catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ID/PW를 확인하세요"))
        );
      }
    }

    return Scaffold(
      body : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [

            Container(
              color: Color(0xff181F32),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width * 1,
              child: Transform.rotate(
              angle: 45 * 3.1415926535 / 180, // 45도 → 라디안으로 변환
              child: const Icon(
                Icons.local_airport,
                color: Colors.white,
                size: 200,
                ),
              ),
            ),
            
            // ID
            TextField(
              controller: emailController,
            ),
            
            // PW
            TextField(
              controller: pwController,
            ),

            // Login
            ElevatedButton(onPressed: (){
              // 공백 확인
              if(emailController.text.trim().isEmpty || pwController.text.trim().isEmpty){
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("ID/PW에 공백이 존재 합니다."))
                );
              }else{
                // 로그인 함수 실행
                login();
              }
            }, child: Text("Login")),

            // 비밀번호 찾기, 회원가입
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: (){}, child: Text("비밀번호 찾기")),
                TextButton(onPressed: (){

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Join(),)
                  );

                }, child: Text("회원가입")),
              ],
            )
          ],
        ),
      )
    );
  }
}