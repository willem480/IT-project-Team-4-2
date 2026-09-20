import 'package:flutter/material.dart';


class FindAJobDetailUser extends StatelessWidget {
  const FindAJobDetailUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
  
}

class FindAJobDetailUserPage extends StatefulWidget {
  const FindAJobDetailUserPage({super.key, required this.title});


  final String title;

  @override
  State<FindAJobDetailUserPage> createState() => _FindAJobDetailUserPage();
}

class _FindAJobDetailUserPage extends State<FindAJobDetailUserPage> {
  int _counter = 0;



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        
      ),
      body: Center(
  
        child: Column(

          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}