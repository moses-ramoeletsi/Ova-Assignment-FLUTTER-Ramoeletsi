import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/services/groups/groups_services.dart';

class GroupChats extends StatefulWidget {
  final String groupName;
  final String groupId;

  const GroupChats({Key? key, required this.groupName, required this.groupId})
      : super(key: key);

  @override
  State<GroupChats> createState() => _GroupChatsState();
}

class _GroupChatsState extends State<GroupChats> {
  final TextEditingController _messageController = TextEditingController();
  final GroupService _groupService = GroupService();

  void _sendMessage() {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _groupService.sendMessageToGroup(widget.groupId, message);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
  return StreamBuilder(
    stream: _groupService.getMessagesFromGroup(widget.groupId),
    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
      if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      }

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      List<QueryDocumentSnapshot> messages = snapshot.data!.docs;

      return ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          var message = messages[index].data() as Map<String, dynamic>;
          bool isSender = message['senderId'] == _groupService.currentUserId;

          return ListTile(
            title: Align(
              alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                message['senderEmail'], 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSender ? Colors.blue : Colors.black,
                ),
              ),
            ),
            subtitle: Align(
              alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSender ? Colors.blue : Colors.grey,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message['message'],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
