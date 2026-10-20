import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
    print("===== 2. 成功进入 TeamSelectionPage 的 initState =====");
    fetchManagedTeams();
  }

  Future<void> fetchManagedTeams() async {
    final url = Uri.parse("http://127.0.0.1:4523/m1/8806835-8598944-default/organization/getOrganizationTeams?organizationId=1&viewerUserI");

    print("===== 1. 开始请求: $url =====");

    try {
      final response = await http.get(url);
      print("===== 2. 收到状态码: ${response.statusCode} =====");


      print("===== 3. 后端返回的原始 JSON: ${response.body} =====");

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
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("===== 网络报错: $e =====");
    }
  }


  //rendering
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Team', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : managedTeams.isEmpty
          ? const Center(child: Text("No teams available for delegation."))
          : ListView.builder(
        itemCount: managedTeams.length,
        itemBuilder: (context, index) {
          final team = managedTeams[index];
          return ListTile(

            title: Text(team['name'] ?? 'Unnamed Team'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PersonnelSelectionPage(
                    ticketId: widget.ticketId,
                    teamId: team['teamId'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}