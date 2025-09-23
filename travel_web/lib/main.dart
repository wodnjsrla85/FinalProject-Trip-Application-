import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:travel_web/ui/dashboard/main_dashboard_page.dart';
import 'package:travel_web/ui/pages/login/login.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Airplane Dashboard',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
