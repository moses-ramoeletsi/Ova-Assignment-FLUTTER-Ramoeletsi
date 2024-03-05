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

  void sendMaessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
          widget.userReceiverId, _messageController.text);

      _messageController.clear();
    }
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
          return Text('Eror${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading');
        }

        return ListView(
          children: snapshot.data!.docs.map((document) => _buildMessageItem(document)).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot documnet) {
    Map<String, dynamic> data = documnet.data() as Map<String, dynamic>;
    var aligment = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Container(
      alignment: aligment,
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
          Text(data['senderEmail']),
          const SizedBox(height: 5),
          ChatAppBubble(message: data['message'])
        ]),
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
              onPressed: sendMaessage,
              icon: const Icon(
                Icons.arrow_forward,
                size: 40,
              ))
        ],
      ),
    );
  }
}
