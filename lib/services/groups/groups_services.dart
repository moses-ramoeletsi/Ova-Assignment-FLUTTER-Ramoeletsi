import 'package:chat_app/model/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String get currentUserId => _firebaseAuth.currentUser!.uid;

  Future<void> createGroup(String groupName) async {
    await _firestore.collection('groups').add({
      'groupName': groupName,
    });
  }

  Stream<QuerySnapshot> getGroups() {
    return _firestore.collection('groups').snapshots();
  }

  Future<void> sendMessageToGroup(String groupId, String message) async {
    final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: groupId,
      message: message,
      timestamp: timestamp,
    );

    await _firestore
        .collection('groupRooms')
        .doc(groupId)
        .collection('groupsmesaages')
        .add(newMessage.toMap());
  }

  Stream<QuerySnapshot> getMessagesFromGroup(String groupId) {
    return _firestore
        .collection('groupRooms')
        .doc(groupId)
        .collection('groupsmesaages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<List<String>> getGroupMembers(String groupId) async {
    final groupSnapshot = await _firestore.collection('groups').doc(groupId).get();
    final groupData = groupSnapshot.data() as Map<String, dynamic>?;

    if (groupData == null || groupData['members'] == null) {
      return [];
    }

    return List<String>.from(groupData['members']);
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([userId]),
    });
  }
}
