import 'package:chat_app/components/chat_bubble.dart';
import 'package:chat_app/components/custom_text_field.dart';
import 'package:chat_app/services/Chat/chat_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPagge extends StatefulWidget {
  final String userReceiverEmail;
  final String userReceiverId;

  const ChatPagge(
      {super.key,
      required this.userReceiverEmail,
      required this.userReceiverId});

  @override
  State<ChatPagge> createState() => _ChatPaggeState();
}

class _ChatPaggeState extends State<ChatPagge> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  bool _isEditing = false;
  late String _editMessageId;

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      if (_isEditing) {
        await _chatService.editMessage(
            widget.userReceiverId,
            _editMessageId,
            _messageController.text
        );
        setState(() {
          _isEditing = false;
          _editMessageId = '';
          _messageController.clear();
        });
      } else {
        await _chatService.sendMessage(
            widget.userReceiverId,
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

  void _deleteMessage(String messageId) {
    _chatService.deleteMessage(widget.userReceiverId, messageId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userReceiverEmail),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMassages(
          widget.userReceiverId, _firebaseAuth.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading');
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var document = snapshot.data!.docs[index];
            return _buildMessageItem(document);
          },
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    var alignment = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return GestureDetector(
      onLongPress: () {
        if (data['senderId'] == _firebaseAuth.currentUser!.uid) {
          _editMessage(document.id, data['message']);
        }
      },
      child: Dismissible(
        key: Key(document.id),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
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
            _deleteMessage(document.id);
          }
        },
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        child: Container(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: (data['senderId'] == _firebaseAuth.currentUser!.uid)
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisAlignment: (data['senderId'] == _firebaseAuth.currentUser!.uid)
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (data['senderId'] != _firebaseAuth.currentUser!.uid)
                  Text(data['senderEmail']),
                const SizedBox(height: 5),
                ChatAppBubble(message: data['message']),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: CutsomTextField(
              controller: _messageController,
              hintText: 'Enter message',
              obscureText: false,
            ),
          ),
          IconButton(
            onPressed: sendMessage,
            icon: const Icon(
              Icons.send,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}