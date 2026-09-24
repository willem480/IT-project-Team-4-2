import 'package:flutter/material.dart';
import 'package:ticketing_app/SuccessPage.dart';


class PostJob extends StatefulWidget {
  const PostJob({super.key});
  // This widget is the root of your application.
  @override
  State<PostJob> createState() => _PostJobPageState();
}


class _PostJobPageState extends State<PostJob> {
  String? selectedCompany;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('Good morning, Alan', style: TextStyle(color:Colors.black)),
      ),
      body: SafeArea(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 200, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text('Post a job', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 45),
            

            //name
            const Text(
              'Full Name',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
            ),
            TextField(
              decoration: InputDecoration(
                hintText: 'Name',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
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
            SizedBox(height: 32.0),
            
            
            //email
              const Text(
              'Email',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
            ),
            
            TextField(
              decoration: InputDecoration(
                hintText: 'Write your email',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
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

            SizedBox(height: 32.0),
            

            //Address
              const Text(
              'Address',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
            ),
          

            TextField(
              decoration: InputDecoration(
                hintText: 'Write your address including postcode',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
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

            SizedBox(height: 32.0),
            

            //Amount of money
    
            const Text(
              'Amount of Money',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
            ),
            
  
            TextField(
              decoration: InputDecoration(
                hintText: 'Fill your expect money',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
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

            SizedBox(height: 32.0),
          

            //Company
 
            const Text(
              'Company',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
            ),


            DropdownButtonFormField<String>(
              
              value: selectedCompany, 
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              
              decoration: InputDecoration(
                hintText: 'Choose a company',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.black, width: 1.0)
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.blue, width: 1.0)
                ),
              ),


              //fake input
              items: ['A', 'B', 'C'].map((String companyName){
                return DropdownMenuItem<String>(
                  value:companyName,
                  child: Text(companyName),
                );
              }).toList(),

              onChanged: (String? newValue){
                setState(() {
                  selectedCompany = newValue;
                });
              },


            ),

            SizedBox(height: 32.0),
  

            //Final date

            const Text(
              'Final date',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
            ),
            
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter your final date in dd/mm/yy',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
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

            SizedBox(height: 32.0),
            
            //description
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
            ),
            TextField(
 
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Write your description to the ticket',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
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

            SizedBox(height: 45.0),

          ],
 
          
        ),
        )
      ),


      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: SizedBox(
          width: 200,
          height: 70,
        
          child: FloatingActionButton(
            onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => SuccessPage()),);},
            backgroundColor: Colors.blue,
            shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            tooltip: 'Submit',
            child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))
          ),
      ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );  
  }
}