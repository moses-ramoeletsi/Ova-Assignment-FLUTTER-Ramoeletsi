import 'package:chat_app/services/groups/groups_services.dart';
import 'package:flutter/material.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({Key? key}) : super(key: key);

  @override
  _CreateGroupPageState createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final GroupService _groupService = GroupService();
  final TextEditingController _groupNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(labelText: 'Group Name'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String groupName = _groupNameController.text.trim();
                if (groupName.isNotEmpty) {
                  await _groupService.createGroup(groupName);
                  Navigator.pop(context); 
                } 
              },
              child: const Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}
