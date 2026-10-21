
import 'package:ticketing_app/FindAJobDetailUser.dart';
import 'package:ticketing_app/Profile.dart';
import 'package:ticketing_app/SignIn.dart';
import 'AcceptJob.dart';
import 'PostJob.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ticketing_app/models/ticket_model.dart';
import 'package:ticketing_app/models/user_profile.dart';
import 'dart:html' as html; //
import 'package:ticketing_app/global.dart';
void main() {
  String? savedUserIdStr = html.window.localStorage['currentUserId'];
  int? savedUserId = savedUserIdStr != null ? int.tryParse(savedUserIdStr) : null;
  if(savedUserId!=null){
    Global.currentUserId = savedUserId;
  }
  runApp(MyApp(initialUserId: savedUserId));

}

class MyApp extends StatelessWidget {
  final int? initialUserId;
  const MyApp({super.key, required this.initialUserId});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF9FAFB)),
      ),
      home: initialUserId != null
          ? MyHomePage(title: 'Find a job', currentUserId: initialUserId!)
          : const SignIn(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final int currentUserId;

  const MyHomePage({
    super.key, 
    required this.title,
    required this.currentUserId});


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<TicketModel> openTickets = [];
  String userName = 'Loading...';
  bool isPayAscending = true;
  bool isDateAscending = true;
  bool isManager = false;
  int? managerOrgId; //This is used to record company of a user managered
  bool isDateActive = false;
  bool isPayActive = false;

  Future<void> checkManagerStatus() async{
    final url = Uri.parse('http://127.0.0.1:8080/organization/getOrganizations?viewerUserId=${widget.currentUserId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print("org list raw data: ${response.body}");
        List<dynamic> organizations = jsonDecode(response.body);

        bool hasManagerPermission = false;
        int? foundOrgId;

        for (var org in organizations) {
          if (org['canManage'] == true) {
            hasManagerPermission = true;
            foundOrgId = org['organizationId'];
            break;
          }
        }

        setState(() {
          isManager = hasManagerPermission;
          managerOrgId = foundOrgId;
        });
      }
    } catch (e) {
      print("identify error: $e");
    }
  }

  //search function
  void fetchTicketsByKeyword(String keyword) async{
    if(keyword.trim().isEmpty){
      fetchOpenTickets('');
      return;
    }
    final url = Uri.parse('http://127.0.0.1:8080/ticket/getOpenTicketsByKeyword?keyword=$keyword');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}), 
      );

      if (response.statusCode == 200) {
        
        List<TicketModel> parsedTickets = ticketFromJson(response.body);
        
        
        setState(() {
          
          openTickets = parsedTickets;

        });
        print("ticket get successfully ${openTickets.length} ");
      }
    } catch (e) {
      print("get ticket error $e");
    }

  }
  //getting organization
  void fetchOpenTickets(String filterType) async {
      
      final url = Uri.parse('http://127.0.0.1:8080/ticket/getOpenTickets?filter=$filterType');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({}), 
        );

        if (response.statusCode == 200) {
          
          List<TicketModel> parsedTickets = ticketFromJson(response.body);
          
          
          setState(() {
            
            openTickets = parsedTickets;

          });
          print("get tickte successfully， ${openTickets.length} ");
        }
      } catch (e) {
        print("get ticket error: $e");
      }
    }

void fetchAssignTickets() async {
      
      final url = Uri.parse('http://127.0.0.1:8080/ticketAssignment/getAcceptedJobsWithFilter?assigneeID=${widget.currentUserId}');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({}), 
        );

        if (response.statusCode == 200) {
          
          List<TicketModel> parsedTickets = ticketFromJson(response.body);
          
          
          setState(() {
            
            openTickets = parsedTickets;

          });
          print(" get ticket successfully， ${openTickets.length} ");
        }
      } catch (e) {
        print("💥 get ticket error: $e");
      }
    }

  void fetchUserData() async {
    final url = Uri.parse('http://127.0.0.1:8080/profilePage/getUser?userId=${widget.currentUserId}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        UserProfile myUser = UserProfile.fromJson(jsonData);
        setState(() {
          userName = myUser.name ?? 'User';
        });
        print("username changed to: $userName");
      }
    } catch (e) {
      print("parse user data error: $e");
    }
  }
    @override
    void initState(){
      super.initState();
      fetchOpenTickets('');
      fetchUserData();
      checkManagerStatus();
    }

  @override
  Widget build(BuildContext context) {
    

 
    return Scaffold(
      appBar: AppBar(
          backgroundColor: const Color(0xFFF9FAFB),
          elevation: 0,

          leading: IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            tooltip: 'Log out to Sign In',
            onPressed: () {

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SignInPage(title: 'Find a job')),
                    (route) => false,
              );
            },
          ),
          title: Text('MYTI', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),

          actions:[
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () {
                  print('profile open');
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Profile(userId: widget.currentUserId)));
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: Text(
                    userName.isNotEmpty? userName.substring(0,1).toUpperCase():'U',
                    style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          ]
      ),
      //body
      body: SafeArea(
       
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            //left align

            children: [
              //fixed area, this is upper area excluding 
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Hello, $userName', style: TextStyle(fontSize: 20)), 
              ),

//Search area
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Autocomplete<TicketModel>(

                  onSelected: (TicketModel selection) {
                    print('user choose: ${selection.title}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FindAJobDetailUser(
                          ticketId: selection.idTicket ?? 0,
                          title: selection.title ?? "No title",
                          company: selection.location ?? selection.posterName ?? "Unknown",
                          price: selection.pay?.toString() ?? '0',
                          description: selection.description ?? "No description",
                          date: selection.datePosted?.toString() ?? "no date",
                          currentUserId: widget.currentUserId,
                          isManager: isManager,
                          managerOrgId: managerOrgId,
                        ),
                      ),
                    );
                  },


                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.trim().isEmpty) {
                      return const Iterable<TicketModel>.empty();
                    }
                    return openTickets.where((TicketModel ticket) {
                      return (ticket.title ?? '').toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },


                  optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<TicketModel> onSelected, Iterable<TicketModel> options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: MediaQuery.of(context).size.width - 32,
                          constraints: const BoxConstraints(maxHeight: 250),
                          color: Colors.white,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final TicketModel option = options.elementAt(index);
                              return ListTile(
                                title: Text(option.title ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('\$${option.pay ?? 0} - ${option.location ?? option.posterName ?? ''}', style: const TextStyle(color: Colors.grey)),
                                onTap: () {
                                  onSelected(option);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },


                  fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      onSubmitted: (value) {
                        onFieldSubmitted();
                        fetchTicketsByKeyword(value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search tickets, assignees, or locations...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: const BorderSide(color: Colors.blue, width: 1.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [

                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          isPayActive = true;
                          isDateActive = false;
                          isPayAscending = !isPayAscending;
                        });
                        String filterValue = isPayAscending ? 'payDescending' : 'payAscending';
                        fetchOpenTickets(filterValue);
                      },
                      icon: Icon(
                        isPayAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: isPayActive ? Colors.blue.shade800 : Colors.black87,
                      ),
                      label: Text(
                        isPayAscending ? "Pay: High to Low" : "Pay: Low to High",
                        style: TextStyle(
                          color: isPayActive ? Colors.blue.shade800 : Colors.black87,
                          fontWeight: isPayActive ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

                        backgroundColor: isPayActive ? Colors.blue.shade50 : Colors.white,

                        side: BorderSide(color: isPayActive ? Colors.blue : Colors.grey.shade300, width: isPayActive ? 1.5 : 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 12),

                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          isDateActive = true;
                          isPayActive = false;
                          isDateAscending = !isDateAscending;
                        });
                        String filterValue = isDateAscending ? 'timeAscending' : 'timeDescending';
                        fetchOpenTickets(filterValue);
                      },
                      icon: Icon(
                        isDateAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: isDateActive ? Colors.blue.shade800 : Colors.black87,
                      ),
                      label: Text(
                        isDateAscending ? "Time: Oldest first" : "Time: Newest first",
                        style: TextStyle(
                          color: isDateActive ? Colors.blue.shade800 : Colors.black87,
                          fontWeight: isDateActive ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

                        backgroundColor: isDateActive ? Colors.blue.shade50 : Colors.white,
                        side: BorderSide(color: isDateActive ? Colors.blue : Colors.grey.shade300, width: isDateActive ? 1.5 : 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                          fetchOpenTickets('');
                        },
                        child: const Text("Reset", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),

              //scrol area
              Expanded(
                child: SingleChildScrollView(
                  //sizebox to stretch width
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment:CrossAxisAlignment.center,
                      children: openTickets.isEmpty 
                      ? [ const Padding(padding: EdgeInsets.all(20), child:Text("No Jobs yet"))]
                      : openTickets.map((ticket) {
                        return _buildJobCard(
                          context,
                          ticket.title ?? "No title",
                          ticket.location ?? ticket.posterName ?? "Unknown Location",
                          ticket.pay?.toString() ?? '0',
                          ticket.description ?? "No description",
                          ticket.idTicket ?? 0,
                          ticket.datePosted?.toString() ?? "no date",
                      );
                    }).toList(),
                  ),
                  //jobs
                ),
              ),
              ),
            ],
          ),
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => PostJob(currentUserId: widget.currentUserId)),);},
        backgroundColor: Colors.blue,
        shape: const CircleBorder(),
        tooltip: 'Post a Job',
        child: const Icon(Icons.add, color:  Colors.white),
      ),

      //lock at center
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      //bottom navigation bar
// Bottom Navigation Bar with highlighted "Find a Job" tab and shadow effect
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Highlighted Find a Job Tab with shadow container wrapper
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
                icon: const Icon(Icons.search, size: 25, color: Colors.blue),
                label: const Text('Find a Job', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(width: 60),

            // Unselected Accept a Job Tab (navigates to AcceptJobPage)
            TextButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => AcceptJobPage(userId: widget.currentUserId),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outlined, size: 25, color: Colors.grey),
              label: const Text('Accept a Job', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),


    );
  }
  Widget _buildJobCard(BuildContext context, String title, String companyName, String price, String description, int ticketId, String date){
    return Padding(

      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
          onTap: (){
            print('tap job ticket in find job page');
            Navigator.push(context, MaterialPageRoute(builder: (context) => FindAJobDetailUser(
                ticketId: ticketId, title: title, company: companyName, price: price, description: description, date: date,
                currentUserId: widget.currentUserId, isManager: isManager, managerOrgId: managerOrgId
            )),);
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
                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Icon(Icons.business, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(child: Text(companyName, style: const TextStyle(fontSize: 13, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text("Poster Name: $userName", style: const TextStyle(fontSize: 12, color: Colors.black54)),

                      ],
                    ),
                  ),

                  const SizedBox(width: 16),


                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$$price', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),
                      Text(date, style: TextStyle(fontSize: 12, color: Colors.grey)),

                    ],
                  )
                ],
              )
          )
      ),
    );
  }
}
