import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String groupId;
  final String groupName;
  final List<String> members; 
  final Timestamp createdTime;

  Group({
    required this.groupId,
    required this.groupName,
    required this.members,
    required this.createdTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'members': members,
      'createdTime': createdTime,
    };
  }
}
