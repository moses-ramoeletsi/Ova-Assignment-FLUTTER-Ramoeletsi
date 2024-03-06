import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/services/groups/groups_services.dart';

import '../components/group_bubble.dart'; // Import your custom bubble widget

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
  bool _isEditing = false;
  late String _editMessageId;

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      if (_isEditing) {
        await _groupService.editMessageInGroup(
            widget.groupId,
            _editMessageId,
            _messageController.text
        );
        setState(() {
          _isEditing = false;
          _editMessageId = '';
          _messageController.clear();
        });
      } else {
        await _groupService.sendMessageToGroup(
            widget.groupId,
            _messageController.text
        );
        _messageController.clear();
      }
    }
  }

  void _editMessage(String messageId, String currentMessage) {
    setState(() {
      _isEditing = true;
      _editMessageId = messageId;
      _messageController.text = currentMessage;
    });
  }

  void _deleteMessage(String messageId) async {
    try {
      await _groupService.deleteMessage(widget.groupId, messageId);
    } catch (e) {
      print('Error deleting message: $e');
      // Handle error if needed
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
            var message = messages[index].data() as Map<String, dynamic>?;

            if (message == null) {
              return SizedBox();
            }

            bool isSender = (message['senderId'] ?? '') == _groupService.currentUserId;

            return GestureDetector(
              onLongPress: () {
                if (isSender) {
                  _editMessage(messages[index].id, message['message']);
                }
              },
              child: Dismissible(
                key: Key(messages[index].id),
                direction: DismissDirection.startToEnd,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 20.0),
                  child: Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Confirm Deletion'),
                          content: Text('Are you sure you want to delete this message?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text('Delete'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Cancel'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                  return false;
                },
                onDismissed: (direction) {
                  if (direction == DismissDirection.startToEnd) {
                    _deleteMessage(messages[index].id);
                  }
                },
                child: MessageBubble(
                  senderEmail: message['senderEmail'] ?? 'Unknown',
                  message: message['message'] ?? 'No message',
                  isSender: isSender,
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
