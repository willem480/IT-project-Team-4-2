  import 'package:flutter/material.dart';
  import 'package:ticketing_app/main.dart';
  import 'package:ticketing_app/PostAJobDetailUser.dart';
  import 'package:ticketing_app/models/ticket_model.dart';
  import 'Organisation.dart';
  import 'models/user_profile.dart';
  import 'package:http/http.dart' as http;
  import 'dart:convert';
  import 'package:ticketing_app/global.dart';
  import 'dart:html' as html;




  class Profile extends StatefulWidget {
    final int userId;
  

    const Profile({
      super.key,
      required this.userId,
  });

    @override
    State<Profile> createState() => _ProfilePage();
    
  }



  class _ProfilePage extends State<Profile> {
    String userEmail = 'Loading...';
    String userName = 'Loading...';
    String title = 'Loading...';
    String location = 'Loading...';
    DateTime? date ;
    String description = "No description";
    String userDescription = "No description";
    double pay = 0.0;
    double totalEarnings = 0.0;
    double thisMonthEarnings = 0.0;
    int thisMonthTimes = 0;
    UserProfile? userProfile;
    List<TicketModel> postedTickets = [];
    List<TicketModel> completedTickets = [];
    bool isPayAscending = true;
    bool isDateAscending = true;
    bool isDateActive = false;
    bool isPayActive = false;
    bool isSubscribed = false;

    Future<void> toggleSubscribe(bool value) async {
      final url = Uri.parse('http://127.0.0.1:8080/user/subscribeToEmail?userId=${widget.userId}&isSubscribed=$value');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({}),
        );

        if (response.statusCode == 200) {
          setState(() {
            isSubscribed = value;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(value ? "Subscribed to email successfully!" : "Unsubscribed successfully!")),
          );
        } else {
          print("Failed to update subscription status");
        }
      } catch (e) {
        print("Network request error: $e");
      }
    }


    void fetchFirstUserData() async {

      final url = Uri.parse('http://127.0.0.1:8080/profilePage/getUser?userId=${widget.userId}');

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
            userEmail = myUser.email ?? 'unknown@email.com';
            totalEarnings = myUser.totalEarnings.toDouble() ?? 0.0;
            thisMonthEarnings = myUser.totalEarningsThisMonth.toDouble() ?? 0.0;
            thisMonthTimes = myUser.numberOfEarningsThisMonth.toInt() ?? 0;
            userDescription= myUser.description ?? "No description";
            isSubscribed = myUser.isSubscribed ?? false;
          });
        }
    }

    Future<void> updateProfileDescription(String newDescription) async{
        final url = Uri.parse(
            'http://127.0.0.1:8080/user/updateUser?id=${widget.userId}&name=${Uri.encodeComponent(userName)}&email=${Uri.encodeComponent(userEmail)}&description=${Uri.encodeComponent(newDescription)}'
        );

      try{
        //Post
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            }),
        );

        if(response.statusCode == 200){
          print("profile is success loaded");

          setState(() {
            userDescription = newDescription;
          });


        }
        else{
          print("fail update description ");
        }

      }catch(e){
        print("network request error");
      }
    }

    void fetchPostedTickets(String filterType) async {

      final url = Uri.parse('http://127.0.0.1:8080/profilePage/getPostedTickets?userId=${widget.userId}&filter=$filterType');

      try{
        //Post
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
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

    void fetchCompletedTickets(String filterType) async {

      final url = Uri.parse('http://127.0.0.1:8080/profilePage/getCompletedTickets?userId=${widget.userId}&filter=$filterType');

        //Post
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
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
      fetchPostedTickets('');
      fetchCompletedTickets('');
    }

    void _showEditDescriptionDialog() {
      TextEditingController editController = TextEditingController(text: userDescription);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Edit Description"),
            content: TextField(
              controller: editController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Write something about yourself...",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  String newText = editController.text;
                  Navigator.pop(context);
                  updateProfileDescription(newText);
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      );
    }


    
    bool is_Detail_Tab = true;
    @override
    Widget build(BuildContext context) {
      bool isMe = widget.userId == Global.currentUserId;
      return Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              if(isMe){
                html.window.localStorage['currentPage'] = 'home';
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => MyHomePage(title: 'Find a job', currentUserId: widget.userId),
                  ),
                      (route) => false,
                );
              }
              else{
                Navigator.pop(context);
              }
            },
          ),
          title: Text('Hello! $userName', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

          actions: [
            if (isMe) ...[
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                        'Subscribe Email',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)
                    ),
                    Checkbox(
                      value: isSubscribed,
                      activeColor: Colors.blueAccent,
                      onChanged: (bool? newValue) {
                        if (newValue != null) {
                          toggleSubscribe(newValue);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ],
          ],
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Description", style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
                                      if(isMe)
                                      IconButton(onPressed: (){_showEditDescriptionDialog();}, icon: Icon(Icons.edit),)
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  Text(userDescription, style: const TextStyle(fontSize: 15, height: 1.4), maxLines: 7, overflow: TextOverflow.ellipsis,),
                                ]
                              ),
                            ),
                              
                            
      
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
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 16,
                      children: [
                        _buildTabButton('Posted jobs', is_Detail_Tab, (){
                          setState(() => is_Detail_Tab = true);

                        }),
                        const SizedBox(width: 12),
                        _buildTabButton('Completed jobs', !is_Detail_Tab, (){
                          setState(() => is_Detail_Tab = false);
                        }),

                        SizedBox(width: 20),
                        OutlinedButton.icon(
                          onPressed: (){
                            setState(() {
                              isDateActive = true;
                              isPayActive = false;
                              isDateAscending = !isDateAscending;
                            });

                            String filterValue = isDateAscending ? 'timeAscending' : 'timeDescending';
                            print("User toggled filter: $filterValue");
                            if(is_Detail_Tab){
                              fetchPostedTickets(filterValue);
                            }
                            else{
                              fetchCompletedTickets(filterValue);
                            }
                          },

                          icon: Icon(
                            isDateAscending ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 16,
                            color: isDateActive ? Colors.blue.shade800 : Colors.black87,
                          ),

                          label: Text(
                            isDateAscending ? "Date: New to Last" : "Date : Last to New",
                            style: TextStyle(
                              color: isDateActive ? Colors.blue.shade800 : Colors.black87,
                              fontWeight: isDateActive ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),

                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            backgroundColor: isDateActive ? Colors.blue.shade50 : Colors.white,
                            side: BorderSide(color: isDateActive ? Colors.blue : Colors.grey, width: isDateActive ? 1.5 : 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        const SizedBox(width: 20),

// 2. Pay 筛选按钮
                        OutlinedButton.icon(
                          onPressed: (){
                            setState(() {
                              isPayActive = true;
                              isDateActive = false;
                              isPayAscending = !isPayAscending;
                            });

                            String filterValue = isPayAscending ? 'payDescending' : 'payAscending';
                            print("User toggled filter: $filterValue");
                            if(is_Detail_Tab){
                              fetchPostedTickets(filterValue);
                            }
                            else{
                              fetchCompletedTickets(filterValue);
                            }
                          },

                          icon: Icon(
                            isPayAscending ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 16,
                            color: isPayActive ? Colors.blue.shade800 : Colors.black87,
                          ),

                          label: Text(
                            isPayAscending ? "Pay: High to Low" : "Pay : Low to High",
                            style: TextStyle(
                              color: isPayActive ? Colors.blue.shade800 : Colors.black87,
                              fontWeight: isPayActive ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),

                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            backgroundColor: isPayActive ? Colors.blue.shade50 : Colors.white,
                            side: BorderSide(color: isPayActive ? Colors.blue : Colors.grey, width: isPayActive ? 1.5 : 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),


                        if (isDateActive || isPayActive) ...[
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isDateActive = false;
                                isPayActive = false;
                              });

                              if (is_Detail_Tab) {
                                fetchPostedTickets('');
                              } else {
                                fetchCompletedTickets('');
                              }
                            },
                            child: const Text("Reset", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                          ),
                        ],

                      

                    
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

// Bottom Navigation Bar with highlighted "My Profile" tab and shadow effect
        bottomNavigationBar: isMe ? BottomAppBar(
          color: Colors.white,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Unselected Organization Tab
              TextButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => OrganisationPage(userId: widget.userId),
                    ),
                  );
                },
                icon: const Icon(Icons.bookmark_border, size: 25, color: Colors.grey),
                label: const Text('Organization', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
              ),

              const SizedBox(width: 60),

              // Highlighted My Profile Tab with shadow container wrapper
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_2_outlined, size: 25, color: Colors.blue),
                  label: const Text('My Profile', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ) : null,
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
            ticket.location ?? 'Unknown Location',
            ticket.pay?.toString() ?? '0',
            ticket.description ?? "No description",
            ticket.idTicket ?? 0,
            ticket.datePosted?.toString() ?? "No date",
            widget.userId,


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
            ticket.location ?? 'Unknown Location',
            ticket.pay?.toString() ?? '0',
            ticket.description ?? "No description",
            ticket.idTicket ?? 0, 
            ticket.datePosted?.toString() ?? 'No date',
            widget.userId,
            isReadOnly: true,
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

    Widget _buildTicket(BuildContext context, String title, String companyName, String price, String description, int ticketId, String datePosted, int currentUserId, {bool isReadOnly = false}){
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: InkWell(
            onTap: (){
              print('check your posted jobs');
              Navigator.push(context, MaterialPageRoute(builder: (context) => PostAJobDetailUser(
                ticketId: ticketId,
                title: title,
                company: companyName,
                price: price,
                description: description,
                date: datePosted,
                currentUserId:Global.currentUserId,
                isReadOnly: isReadOnly || (widget.userId != Global.currentUserId),
              )));
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),


                          Row(
                            children: [
                              const Icon(Icons.business, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(child: Text(companyName, style: const TextStyle(fontSize: 14, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          const SizedBox(height: 8),


                          Text("Poster Name: $userName", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),


                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [

                        Text('\$$price', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),

                        const SizedBox(height: 24),


                        Text(datePosted.toString().length >= 10 ? datePosted.toString().substring(0,10) : datePosted, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    )
                  ],
                )
            )
        ),
      );
    }

  }
