import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';

class UserProvider with ChangeNotifier {
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('Users');

  List<AppUser> _users = [];
  List<AppUser> get users => _users;

  Future<void> fetchUsers() async {
    final snapshot = await usersCollection.get();
    _users = snapshot.docs.map((doc) => AppUser.fromMap(doc.data() as Map<String, dynamic>)).toList();
    notifyListeners();
  }

  Future<bool> addUser(AppUser user) async {
    final doc = usersCollection.doc(user.userId);
    final exists = (await doc.get()).exists;
    if (exists) return false;

    await doc.set(user.toMap());
    _users.add(user);
    notifyListeners();
    return true;
  }

  Future<String> generateNextUserId() async {
    final snapshot = await usersCollection.get();
    final ids = snapshot.docs.map((doc) => doc['userId'] as String).toList();
    final numbers = ids
        .where((id) => id.startsWith('U'))
        .map((id) => int.tryParse(id.substring(1)) ?? 0)
        .toList();

    final maxNumber = numbers.isEmpty ? 0 : numbers.reduce((a, b) => a > b ? a : b);
    final nextNumber = maxNumber + 1;
    return 'U${nextNumber.toString().padLeft(4, '0')}';
  }
}
