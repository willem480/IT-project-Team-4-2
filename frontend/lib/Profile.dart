import 'package:flutter/material.dart';
import 'package:ticketing_app/FindAJobDetailUser.dart';
import 'package:ticketing_app/main.dart';
import 'package:ticketing_app/PostAJobDetailUser.dart';
import 'Organisation.dart';



class Profile extends StatefulWidget {


  const Profile({
    super.key,
});

  @override
  State<Profile> createState() => _ProfilePage();
  
}



class _ProfilePage extends State<Profile> {
  bool is_Detail_Tab = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const MyHomePage(title: 'Find a job'),
              ),
              (route) => false,
            );
          },
        ),
        title: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

      ),
      body: Column(

        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(50),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //intro
                  Container(
                    height: 250,
                    width: 500,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey), 
                    ),

                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          Text('TOTAL EARNING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)), 
                          const SizedBox(height: 25),
                          Text('\$ Total money',style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),),
                          const SizedBox(height: 60),
                          Text('This month: \$ money and times payouts', style: const TextStyle(fontWeight:FontWeight.bold, fontSize: 15, color: Colors.grey)),
                        ],
                    )
                  ),
                  const SizedBox(height:20),

                  //button
                  Row(
                    children: [
                      _buildTabButton('Posted jobs', is_Detail_Tab, (){
                        setState(() => is_Detail_Tab = true);

                      }),
                      const SizedBox(width: 12),
                      _buildTabButton('Completed jobs', !is_Detail_Tab, (){
                        setState(() => is_Detail_Tab = false);
                      })
                    ],
                  ),
                  SizedBox(height: 25),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(onPressed:() {}, 
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Text('Time'), SizedBox(width: 8), Icon(Icons.arrow_downward)]))),

                  is_Detail_Tab ? _buildPostedJobSection(context) : _buildCompletedJobs(), 


                ],
              ),


          )),
          
          Text(
            '',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
      
          bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const OrganisationPage(),
                  ),
                );
              }, 
              icon: Icon(Icons.bookmark_border, size: 25, color: Colors.black), 
              label: Text('Organization', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            ),
  
            const SizedBox(width: 60),
            TextButton.icon(
              onPressed: () {}, 
              icon: Icon(Icons.person_2_outlined, size: 25, color: Colors.black), 
              label: Text('My Profile', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            ),
          ],
        )
      ),
    );
  }

  // The Details View (Description + Map)
  Widget _buildPostedJobSection(BuildContext context) {
    return Column(
      
      crossAxisAlignment: CrossAxisAlignment.center,
      
      children: [
        InkWell(
          onTap: (){
            print('check your posted jobs');
            Navigator.push(context, MaterialPageRoute(builder: (context) => PostAJobDetailUser(title: 'title: B', company: 'Company: B', price: '500',)),);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 800,
            height: 250,
            margin: const EdgeInsets.all(50),
            padding: EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                )
              ]
            ),           
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // alignment: Alignment.topLeft,
                Text(
                  'Company B',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),  
                //more item
              ],
            )
          )
        ),
      ],
    );
  }


  Widget _buildCompletedJobs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: (){
            print('check your completed jobs');
            Navigator.push(context, MaterialPageRoute(builder: (context) => FindAJobDetailUser(title: 'title: A', company: 'Company: A', price: '600',)),);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 800,
            height: 250,
            margin: const EdgeInsets.all(50),
            padding: EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                )
              ]
            ),           
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // alignment: Alignment.topLeft,
                Text(
                  'Company A',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),  
                //more item
              ],
            )
          )
        ),
      ],
    );
  }
  // Helper method for the pill-shaped toggle buttons
  Widget _buildTabButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color.fromARGB(255, 0, 0, 0) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color.fromARGB(255, 255, 255, 255) : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }


}
