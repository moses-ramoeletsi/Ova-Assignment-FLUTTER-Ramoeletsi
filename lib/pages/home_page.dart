import 'package:chat_app/pages/chat_page.dart';
import 'package:chat_app/pages/groups_pages.dart';
import 'package:chat_app/services/auth/auth_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, bool> followStatus = {};
  TextEditingController _searchController = TextEditingController();
  late Stream<QuerySnapshot> _usersStream;

  @override
  void initState() {
    super.initState();
    _initializeFollowStatus();
    _usersStream = FirebaseFirestore.instance.collection('users').snapshots();
  }

  void _initializeFollowStatus() {
    FirebaseFirestore.instance
        .collection('followers')
        .doc(_auth.currentUser!.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        data.forEach((key, value) {
          followStatus[key] = value;
        });
        setState(() {});
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
          IconButton(onPressed: signOut, icon: const Icon(Icons.logout)),
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GroupsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _usersStream = FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isGreaterThanOrEqualTo: value)
                      .snapshots();
                });
              },
              decoration: InputDecoration(
                labelText: 'Search by email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _usersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('error');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
      bool isFollowing =
          followStatus.containsKey(userData['uid']) && followStatus[userData['uid']]!;
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
          _startConversationIfFollowed(userData['uid'], userData);
        },
      );
    } else {
      return const SizedBox(); // Avoid showing current user in the list
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
          content: Text(isFollowing
              ? 'You are now following this user.'
              : 'You have unfollowed this user.'),
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

  void _startConversationIfFollowed(String userReceiverId, Map<String, dynamic> userData) {
    if (followStatus.containsKey(userReceiverId) && followStatus[userReceiverId]!) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            userReceiverEmail: userData['email'],
            userReceiverId: userData['uid'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only start a conversation with users you are following.'),
        ),
      );
    }
  }
}
