import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ticketing_app/SignIn.dart';
import 'package:ticketing_app/global.dart';
import 'package:ticketing_app/main.dart';
import 'config.dart';


class SignUp extends StatelessWidget {
  const SignUp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign up',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 255, 255, 255)),
      ),
      home: const SignUpPage(title: 'Flutter Demo Home Page'),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  bool _isSigningUp = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signUp() async {
    if (_isSigningUp) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter your name.');
      return;
    }
    if (email.isEmpty) {
      _showError('Please enter your email.');
      return;
    }

    setState(() => _isSigningUp = true);
    var accountCreated = false;
    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/user/signup',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email}),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;
      if (response.statusCode == 201) {
        accountCreated = true;
        final signInResponse = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/user/signin'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        ).timeout(const Duration(seconds: 30));

        if (!mounted) return;
        if (signInResponse.statusCode != 200) {
          _showError('Account created, but automatic sign in failed. Please sign in using the link below.');
          return;
        }

        final responseData = jsonDecode(signInResponse.body);
        final userId = responseData is Map<String, dynamic>
            ? responseData['idUser']
            : null;
        if (userId is! int || userId <= 0) {
          _showError('Account created, but automatic sign in failed. Please sign in using the link below.');
          return;
        }

        html.window.localStorage['currentUserId'] = userId.toString();
        Global.currentUserId = userId;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MyHomePage(
              title: 'Find a job',
              currentUserId: userId,
            ),
          ),
        );
      } else {
        var message = 'Signup failed (HTTP ${response.statusCode}). Please try again.';
        try {
          final body = jsonDecode(response.body);
          if (body is Map<String, dynamic>) {
            final error = body['message'] ?? body['error'];
            if (error is String && error.trim().isNotEmpty) {
              message = error;
            }
          }
        } on FormatException {
          // Keep the fallback message for empty or non-JSON responses.
        }
        _showError(message);
      }
    } on TimeoutException {
      _showError(accountCreated
          ? 'Account created, but automatic sign in timed out. Please sign in using the link below.'
          : 'Signup request timed out. Please try again.');
    } catch (_) {
      _showError(accountCreated
          ? 'Account created, but automatic sign in failed. Please sign in using the link below.'
          : 'Unable to sign up. Please check your connection and try again.');
    } finally {
      if (mounted) {
        setState(() => _isSigningUp = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        //title
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children:[
                    Icon(Icons.local_activity_outlined, color: Colors.black),
                    SizedBox(width: 8),
                    Text('MyTi', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),),
                  ]
                ),
              ),
              SizedBox(height: 8),
              Text('Create your account', style: TextStyle(fontSize: 50)),
              Text('Create your account and get started with your ticketing system', style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(height: 8),
              //name enter area
              const Text('Name', style:TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Your name',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.black, width: 1.0)
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.blue, width: 1.0)
                  ),
                ),
              ),

              SizedBox(height: 32),
              //email enter area
              const Text('Email address', style:TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'ABC@gmail.com',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.black, width: 1.0)
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.blue, width: 1.0)
                  ),
                ),
              ),

              SizedBox(height: 18),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (context) => SignIn()),);},
                  child: Text('Already have an account? Sign in here', style: TextStyle(color: Colors.green, decoration: TextDecoration.underline),
                  ),
                ),
              ),

              SizedBox(height: 32),
            ],
          ),
        ),
        )
      ),


      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 50),
        child: SizedBox(
          width: 240,
          height: 50,
          child: FloatingActionButton(
            onPressed: _isSigningUp ? null : _signUp,
            backgroundColor: Colors.green,
            tooltip: 'Create account and sign in',
            child: const Text('Create account and sign in', style: TextStyle(color: Colors.white))),
        )
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
