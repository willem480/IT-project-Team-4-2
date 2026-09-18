import 'package:flutter/material.dart';
import 'package:ticketing_app/main.dart';


class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

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
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Image.asset(
              'assets/images/images.png',
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),

            SizedBox(height: 24),
            Text('You have successully make it!', style: TextStyle(color: Colors.black, fontSize: 16)),

          ],
        ),
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: SizedBox(
          width: 500,
          height: 60, 
        
        
          child: FloatingActionButton( 
            onPressed: () {Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Find a job')), (Route<dynamic> route) => false);},
            backgroundColor: Colors.green,
            shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            child: Text('OK', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),),
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

    );
  }
  // This widget is the root of your application.
}


