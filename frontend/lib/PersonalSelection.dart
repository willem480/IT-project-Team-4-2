import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PersonnelSelectionPage extends StatefulWidget {
  final int ticketId;
  final int teamId;

  const PersonnelSelectionPage({
    super.key,
    required this.ticketId,
    required this.teamId,
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

    final url = Uri.parse("http://127.0.0.1:4523/m1/8806835-8598944-default/team/getTeamMembers?teamId=${widget.teamId}&viewerUserId=1");

    print("===== 准备获取小组成员: $url =====");

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
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("网络请求错误: $e");
    }
  }

  //rendering
  Future<void> _submitDelegation() async {
    if (selectedUserId == null) return;

    final url = Uri.parse("http://127.0.0.1:4523/m1/8806835-8598944-default/ticketAssignment/delegateJobIndividual");
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "ticketId": widget.ticketId,
          "assigneeId": selectedUserId, 
          "teamId": widget.teamId,
        }),
      );

      if (response.statusCode == 200) {
        print("Delegation successful");
     
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        print("Failed to delegate job");
      }
    } catch (e) {
      print("Network request error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Personnel', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: teamMembers.isEmpty
                      ? const Center(child: Text("No members available in this team."))
                      : ListView.builder(
                          itemCount: teamMembers.length,
                          itemBuilder: (context, index) {
                            final member = teamMembers[index];
                            return RadioListTile<int>(
                              // 根据截图提取 userName 和 email 字段
                              title: Text(member['userName'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: Text(member['email'] ?? '', style: const TextStyle(color: Colors.black54)),
                              // 提取 userId 作为选中时的值
                              value: member['userId'], 
                              groupValue: selectedUserId,
                              activeColor: Colors.blueAccent, // 选中时圆点的颜色
                              onChanged: (int? value) {
                                setState(() {
                                  selectedUserId = value;
                                });
                              },
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
                      // 当未选中任何人时，禁用按钮 (onPressed 设为 null)
                      onPressed: selectedUserId == null ? null : _submitDelegation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        disabledBackgroundColor: Colors.grey.shade300, // 禁用状态下的颜色
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