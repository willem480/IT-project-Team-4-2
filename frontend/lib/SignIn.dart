import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ticketing_app/Signup.dart';
import 'package:ticketing_app/main.dart';

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign in',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 255, 255, 255)),
      ),
      home: const SignInPage(title: 'Flutter Demo Home Page'),
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.title});

  final String title;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool isObsecure = true;
  bool isLoading = false;


  final TextEditingController _emailController = TextEditingController();



  void handleSignIn() async {
    final email = _emailController.text.trim();


    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

  
    final url = Uri.parse('http://127.0.0.1:8080/user/signin');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
  
        final int userId = responseData['idUser'] ?? 1;
        final String userName = responseData['name'] ?? 'User';

        print("✅ 登录成功！当前用户 ID: $userId, 用户名: $userName");

      
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(title: 'Find a job'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in failed: Invalid credentials')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("💥 网络请求错误: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_activity_outlined, color: Colors.black),
                      SizedBox(width: 8),
                      Text('MyTi', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Sign in to your account', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                const Text('Welcome back, enter your credential to access your ticket', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 24),
                
              
                const Text('Email address', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController, 
                  decoration: InputDecoration(
                    hintText: 'ABC@gmail.com',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.black, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.blue, width: 1.0),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => SignUp()));
                    },
                    child: const Text('Don\'t have an account? Sign up here', style: TextStyle(color: Colors.green, decoration: TextDecoration.underline)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),

  
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: SizedBox(
          width: 200,
          height: 50,
          child: FloatingActionButton(
            onPressed: isLoading ? null : handleSignIn, 
            backgroundColor: Colors.green,
            tooltip: 'Log in',
            child: isLoading 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text('Sign in', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}