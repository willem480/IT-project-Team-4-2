import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ticketing_app/TeamSelection.dart';

class OrganizationSelectionPage extends StatefulWidget {
  final int ticketId;
  final int currentUserId;

  const OrganizationSelectionPage({
    super.key,
    required this.ticketId,
    required this.currentUserId,
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

        // 过滤出 canManage 为 true 的组织
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
      print("网络请求错误: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Select an Organization', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : managedOrgs.isEmpty
          ? const Center(child: Text("No organizations available for delegation."))
          : ListView.builder(
        itemCount: managedOrgs.length,
        itemBuilder: (context, index) {
          final org = managedOrgs[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ListTile(
              title: Text(org['name'] ?? 'Unnamed Organization', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Members: ${org['memberCount'] ?? 0}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // 💡 关键接力：带着选中的 orgId 跳转到选团队页面
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeamSelectionPage(
                      ticketId: widget.ticketId,
                      orgId: org['organizationId'], // 传给下一页
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