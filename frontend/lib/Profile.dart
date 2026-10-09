import 'package:flutter/material.dart';
import 'package:ticketing_app/FindAJobDetailUser.dart';
import 'package:ticketing_app/main.dart';
import 'package:ticketing_app/PostAJobDetailUser.dart';
import 'package:ticketing_app/models/ticket_model.dart';
import 'Organisation.dart';
import 'models/user_profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';





class Profile extends StatefulWidget {


  const Profile({
    super.key,
});

  @override
  State<Profile> createState() => _ProfilePage();
  
}



class _ProfilePage extends State<Profile> {

  String userName = 'Loading...';
  String title = 'Loading...';
  String location = 'Loading...';
  String description = "No description";
  String user_Description = "No description";
  double pay = 0.0;
  double totalEarnings = 0.0;
  double thisMonthEarnings = 0.0;
  int thisMonthTimes = 0;
  UserProfile? userProfile;
  List<TicketModel> postedTickets = [];
  List<TicketModel> completedTickets = [];


  void fetchFirstUserData() async {

    final url = Uri.parse('http://127.0.0.1:4523/m1/8806835-8598944-default/profilePage/getUser');

      //Post
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
      
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        UserProfile myUser = UserProfile.fromJson(jsonData);
        setState(() {
          userName = myUser.name ?? 'User';
          totalEarnings = myUser.totalEarnings.toDouble() ?? 0.0;
          thisMonthEarnings = myUser.totalEarningsThisMonth.toDouble() ?? 0.0;
          thisMonthTimes = myUser.numberOfEarningsThisMonth.toInt() ?? 0;
          user_Description= myUser.description ?? "No description";
        });
      }
  }

  void fetchPostedTickets() async {

    final url = Uri.parse('http://127.0.0.1:4523/m1/8806835-8598944-default/profilePage/getPostedTickets');

    try{
      //Post
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': 1}),
      );

      if (response.statusCode == 200) {
        List<TicketModel> parsedTickets = ticketFromJson(response.body);
        setState(() {
          postedTickets = parsedTickets;
        });
      }
    }catch(e){
      print("ticket crash");
    }

  }

  void fetchCompletedTickets() async {

    final url = Uri.parse('http://127.0.0.1:4523/m1/8806835-8598944-default/profilePage/getCompletedTickets');

      //Post
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': 1}),
      );

      if (response.statusCode == 200) {
        List<TicketModel> parsedTickets = ticketFromJson(response.body);
        setState(() {
          completedTickets = parsedTickets;
        });
      }
  }



  @override
  void initState() {
    super.initState();
    fetchFirstUserData();
    fetchPostedTickets();
    fetchCompletedTickets();

  }


  
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
        title: Text('Hello! $userName', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

      ),
      body: Column(

        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(50),
              child: SizedBox(
                width: double.infinity,
              
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //intro
                  Container(
                    height: 250,
                    width: 500,
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey), 
                    ),

                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.blue,
                            child: Text(
                              userName.isNotEmpty? userName.substring(0,1).toUpperCase():'U',
                              style: TextStyle(fontSize: 32, color:Colors.white, fontWeight:FontWeight.bold),),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                Text("Description", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),            
                                const SizedBox(height: 20),
                                Text("$user_Description", style: const TextStyle(fontSize: 15, height: 1.4), maxLines: 7, overflow: TextOverflow.ellipsis,),
                              ]
                            )
                          )
                          
                        ],
                    )
                  ),
                  const SizedBox(height:30),
                  //job summary
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
                          
                          Text('TOTAL EARNINGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)), 
                          const SizedBox(height: 25),
                          Text('\$$totalEarnings',style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),),
                          const SizedBox(height: 60),
                          Text('This month: \$$thisMonthEarnings and $thisMonthTimes times payouts', style: const TextStyle(fontWeight:FontWeight.bold, fontSize: 15, color: Colors.grey)),
                        ],
                    )
                  ),
                  const SizedBox(height: 30),
                  //button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTabButton('Posted jobs', is_Detail_Tab, (){
                        setState(() => is_Detail_Tab = true);

                      }),
                      const SizedBox(width: 12),
                      _buildTabButton('Completed jobs', !is_Detail_Tab, (){
                        setState(() => is_Detail_Tab = false);
                      }),

                      SizedBox(width: 20),
                      OutlinedButton(
                        onPressed: (){}, 
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [Text('Time'), SizedBox(width: 8), Icon(Icons.arrow_downward)]
                      ))
                  
                    ],
                  ),
                

                  is_Detail_Tab ? _buildPostedJobSection(context) : _buildCompletedJobs(), 


                ],
              ),
              )


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
    //if no ticket
    if (postedTickets.isEmpty){
        return Padding(
          padding: const EdgeInsets.all(50.0),
          child: Text('No jobs yet.', style: TextStyle(color: Colors.grey)),
          );
      }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: postedTickets.map((ticket){ // assign postedTicket to ticket
        return _buildTicket(
          context, 
          ticket.title.toString() ?? 'No title', 
          ticket.organizationName ?? 'Unknown Location', 
          ticket.pay?.toString() ?? '0',
          ticket.description ?? "No description",
          ticket.idTicket ?? 0,
          );
          
      }).toList(),
    );
  }


  Widget _buildCompletedJobs() {
     //if no ticket
    if (completedTickets.isEmpty){
        return Padding(
          padding: const EdgeInsets.all(50.0),
          child: Text('No jobs yet.', style: TextStyle(color: Colors.grey)),
          );
      }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: completedTickets.map((ticket){ // assign completedTicket to ticket
        return _buildTicket(
          context, 
          ticket.title.toString() ?? 'No title', 
          ticket.organizationName ?? 'Unknown Location', 
          ticket.pay?.toString() ?? '0',
          ticket.description ?? "No description",
          ticket.idTicket ?? 0, 
          );
          
      }).toList(),
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

  Widget _buildTicket(BuildContext context, String title, String companyName, String price, String description, int ticketId){
      return InkWell(
          onTap: (){
            print('check your posted jobs');
            Navigator.push(context, MaterialPageRoute(builder: (context) => PostAJobDetailUser(ticketId: ticketId, title: title, company: companyName, price: price, description: description)),);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 800,
            height: 225,
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
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
                // alignment: Alignment.topLeft,
              Text(
                companyName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              
              const Spacer(),

              Text(
                '\$$price',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              //more item
                //more item
              ],
            )
          )
        );
  }

}
