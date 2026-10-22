import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ticketing_app/config.dart';
import 'dart:convert';
import 'package:ticketing_app/main.dart';

class TeamSelectionForTeamDelegatePage extends StatefulWidget {
  final int ticketId;
  final int orgId;
  final int currentUserId;

  const TeamSelectionForTeamDelegatePage({
    super.key,
    required this.ticketId,
    required this.orgId,
    required this.currentUserId,
  });

  @override
  State<TeamSelectionForTeamDelegatePage> createState() => _TeamSelectionForTeamDelegatePageState();
}

class _TeamSelectionForTeamDelegatePageState extends State<TeamSelectionForTeamDelegatePage> {
  List<dynamic> managedTeams = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    print("===== 进入 TeamSelectionForTeamDelegatePage 的 initState =====");
    fetchManagedTeams();
  }

  Future<void> _delegateToTeam(int teamId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/ticketAssignment/delegateJobTeam?ticketId=${widget.ticketId}&teamId=$teamId");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅delegate team successfully")),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage(title: 'Find a job', currentUserId: widget.currentUserId)),
              (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("delegate error${response.statusCode}")),
        );
      }
    } catch (e) {
      print("network request error: $e");
    }
  }

  Future<void> fetchManagedTeams() async {
    final url = Uri.parse(ApiConfig.getOrganizationTeams(widget.orgId, widget.currentUserId));

    print("===== team list: $url =====");

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
      print("network error: $e =====");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        title: const Text('Select a Team to Delegate', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
              subtitle: Text('Members count: ${team['memberCount'] ?? 0}', style: const TextStyle(color: Colors.grey)),
              trailing: const Icon(Icons.send_rounded, color: Colors.blueAccent),
              onTap: () {
                _delegateToTeam(team['teamId']);
              },
            ),
          );
        },
      ),
    );
  }
}