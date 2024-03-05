import 'package:chat_app/pages/chat_page.dart';
import 'package:chat_app/services/auth/auth_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomaPage extends StatefulWidget {
  const HomaPage({super.key});

  @override
  State<HomaPage> createState() => _HomaPageState();
}

class _HomaPageState extends State<HomaPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, bool> followStatus = {};

  @override
  void initState() {
    super.initState();
    _initializeFollowStatus();
  }

  void _initializeFollowStatus() {
    FirebaseFirestore.instance
        .collection('followers')
        .doc(_auth.currentUser!.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        // Extract follow status from snapshot data
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        data.forEach((key, value) {
          followStatus[key] = value;
        });
        setState(() {}); // Update UI
      }
    });
  }

  void signOut() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(onPressed: signOut, icon: const Icon(Icons.logout))
        ],
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('error');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...');
        }

        return ListView(
          children: snapshot.data!.docs
              .map<Widget>((doc) => _buildUserListItem(doc))
              .toList(),
        );
      },
    );
  }

  Widget _buildUserListItem(DocumentSnapshot document) {
    Map<String, dynamic> userData = document.data()! as Map<String, dynamic>;

    if (_auth.currentUser!.email != userData['email']) {
      bool isFollowing = followStatus.containsKey(userData['uid']) && followStatus[userData['uid']]!;
      return ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(userData['email']),
            ElevatedButton(
              onPressed: () {
                _toggleFollow(userData['uid'], !isFollowing);
              },
              child: Text(isFollowing ? 'Following' : 'Follow'),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPagge(
                userReceiverEmail: userData['email'],
                userReceiverId: userData['uid'],
              ),
            ),
          );
        },
      );
    } else {
      return Container();
    }
  }

  void _toggleFollow(String userId, bool isFollowing) {
    FirebaseFirestore.instance
        .collection('followers')
        .doc(_auth.currentUser!.uid)
        .set({
      userId: isFollowing,
    }, SetOptions(merge: true)).then((value) {
      setState(() {
        followStatus[userId] = isFollowing;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFollowing ? 'You are now following this user.' : 'You have unfollowed this user.'),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update follow status. Please try again later.'),
        ),
      );
    });
  }
}
