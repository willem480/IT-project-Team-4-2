import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ticketing_app/TeamSelection.dart';
import 'package:ticketing_app/TeamSelectionForTeamDelegatePage.dart';

class OrganizationSelectionPage extends StatefulWidget {
  final int ticketId;
  final int currentUserId;
  final bool isForTeamDelegate;

  const OrganizationSelectionPage({
    super.key,
    required this.ticketId,
    required this.currentUserId,
    this.isForTeamDelegate = false,
  });

  @override
  State<OrganizationSelectionPage> createState() => _OrganizationSelectionPageState();
}

class _OrganizationSelectionPageState extends State<OrganizationSelectionPage> {
  List<dynamic> managedOrgs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrganizations();
  }

  Future<void> fetchOrganizations() async {
    final url = Uri.parse("http://127.0.0.1:8080/organization/getOrganizations?viewerUserId=${widget.currentUserId}");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> allOrgs = jsonDecode(response.body);

        List<dynamic> filteredOrgs = allOrgs.where((org) => org['canManage'] == true).toList();

        setState(() {
          managedOrgs = filteredOrgs;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("network request error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        title: const Text('Select an Organization', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : managedOrgs.isEmpty
          ? const Center(child: Text("No organizations available for delegation.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: managedOrgs.length,
        itemBuilder: (context, index) {
          final org = managedOrgs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Text(org['name'] ?? 'Unnamed Organization', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text('Members: ${org['memberCount'] ?? 0}', style: const TextStyle(color: Colors.grey)),
              trailing: const Icon(Icons.chevron_right, color: Colors.blueAccent),
              onTap: () {
                if (widget.isForTeamDelegate) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeamSelectionForTeamDelegatePage(
                        ticketId: widget.ticketId,
                        orgId: org['organizationId'],
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeamSelectionPage(
                        ticketId: widget.ticketId,
                        orgId: org['organizationId'],
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}