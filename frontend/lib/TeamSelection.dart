import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ticketing_app/config.dart';
import 'dart:convert';
import 'PersonalSelection.dart';

class TeamSelectionPage extends StatefulWidget {
  final int ticketId;
  final int orgId;
  final int currentUserId;

  const TeamSelectionPage({
    super.key,
    required this.ticketId,
    required this.orgId,
    required this.currentUserId,
  });

  @override
  State<TeamSelectionPage> createState() => _TeamSelectionPageState();
}

class _TeamSelectionPageState extends State<TeamSelectionPage> {
  List<dynamic> managedTeams = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchManagedTeams();
  }

  Future<void> fetchManagedTeams() async {
    final url = Uri.parse(ApiConfig.getOrganizationTeams(widget.orgId, widget.currentUserId));

    print("request team list $url =====");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        var decodedData = json.decode(response.body);

        List<dynamic> targetList = [];
        if (decodedData['teams'] != null) {
          targetList = decodedData['teams'];
        }

        setState(() {
          managedTeams = targetList;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("network error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        title: const Text('Select a Team', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : managedTeams.isEmpty
          ? const Center(child: Text("No teams available for delegation.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: managedTeams.length,
        itemBuilder: (context, index) {
          final team = managedTeams[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(team['name'] ?? 'Unnamed Team', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text('Members: ${team['memberCount'] ?? 0}', style: const TextStyle(color: Colors.grey)),
              trailing: const Icon(Icons.chevron_right, color: Colors.blueAccent),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PersonnelSelectionPage(
                      ticketId: widget.ticketId,
                      teamId: team['teamId'],
                      currentUserId: widget.currentUserId,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}