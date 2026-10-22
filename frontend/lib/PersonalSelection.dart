import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'config.dart';

class PersonnelSelectionPage extends StatefulWidget {
  final int ticketId;
  final int teamId;
  final int currentUserId;

  const PersonnelSelectionPage({
    super.key,
    required this.ticketId,
    required this.teamId,
    required this.currentUserId,
  });

  @override
  State<PersonnelSelectionPage> createState() => _PersonnelSelectionPageState();
}

class _PersonnelSelectionPageState extends State<PersonnelSelectionPage> {
  int? selectedUserId;
  List<dynamic> teamMembers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTeamMembers();
  }

  Future<void> fetchTeamMembers() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/team/getTeamMembers?teamId="
        "${widget.teamId}&viewerUserId=${widget.currentUserId}");

    print("team member list: $url =====");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        var decodedData = json.decode(response.body);

        if (decodedData != null && decodedData['members'] != null) {
          setState(() {
            teamMembers = decodedData['members'];
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("network error: $e");
    }
  }

  Future<void> _submitDelegation() async {
    if (selectedUserId == null) return;

    final url = Uri.parse("${ApiConfig.baseUrl}/ticketAssignment/delegateJobIndividual?ticketId=${widget.ticketId}&assigneeId=$selectedUserId&teamId=${widget.teamId}");


    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );


      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("job successfully！")),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage(title: 'Find a job', currentUserId: widget.currentUserId)),
              (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("delegate error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("💥 Network request error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        title: const Text('Select Personnel', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: teamMembers.isEmpty
                ? const Center(child: Text("No members available in this team.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: teamMembers.length,
              itemBuilder: (context, index) {
                final member = teamMembers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RadioListTile<int>(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(member['userName'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(member['email'] ?? '', style: const TextStyle(color: Colors.black54)),
                    value: member['userId'],
                    groupValue: selectedUserId,
                    activeColor: Colors.blueAccent,
                    onChanged: (int? value) {
                      setState(() {
                        selectedUserId = value;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: selectedUserId == null ? null : _submitDelegation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                child: const Text('Confirm Delegation', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}