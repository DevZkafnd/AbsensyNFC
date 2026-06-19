import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Supabase.initialize(
    url: 'https://rflwuexzllhzfnmemyqd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmbHd1ZXh6bGxoemZubWVteXFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM0NjM1MzUsImV4cCI6MjA2OTAzOTUzNX0.0pMcWk7CplpumfzSjdAd448G0vWuax72Nx5BumkFmLc',
  );
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final message = details.exceptionAsString();
    return Material(
      color: const Color(0xFFF3F3F3),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            kReleaseMode ? 'Terjadi error: $message' : details.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensy User',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
