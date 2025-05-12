import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _profileController = TextEditingController();

  String? _selectedUserId;
  bool _useAvailableId = true;

  List<String> _availableIds = [];
  String? _nextUserId;

  @override
  void initState() {
    super.initState();
    _generateUserIdOptions();
  }

  Future<void> _generateUserIdOptions() async {
    final snapshot = await _firestore.collection('Users').get();
    final usedIds = snapshot.docs
        .map((doc) => doc['userId'] as String)
        .toList();

    List<int> existingNumbers = usedIds
        .map((id) => int.tryParse(id.replaceAll('U', '')) ?? 0)
        .toList();

    existingNumbers.sort();
    Set<int> usedSet = existingNumbers.toSet();

    // 找出空出来的 id（比如 U0003 不存在）
    List<String> available = [];
    for (int i = 1; i < existingNumbers.last; i++) {
      if (!usedSet.contains(i)) {
        available.add("U${i.toString().padLeft(4, '0')}");
      }
    }

    String nextId = "U${(existingNumbers.isNotEmpty ? existingNumbers.last + 1 : 1).toString().padLeft(4, '0')}";

    setState(() {
      _availableIds = available;
      _nextUserId = nextId;
      _selectedUserId = _useAvailableId && available.isNotEmpty ? available.first : nextId;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedUserId != null) {
      final uuid = const Uuid().v4(); // 你可以使用 Firebase Auth 来注册真实用户
      await _firestore.collection('Users').doc(uuid).set({
        'userId': _selectedUserId,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profile_Picture': 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png'

      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added successfully')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add User'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  const Text('User ID Mode:'),
                  const SizedBox(width: 10),
                  DropdownButton<bool>(
                    value: _useAvailableId,
                    items: const [
                      DropdownMenuItem(value: true, child: Text('Use Empty ID')),
                      DropdownMenuItem(value: false, child: Text('Next Available')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _useAvailableId = value!;
                        _selectedUserId = _useAvailableId
                            ? (_availableIds.isNotEmpty ? _availableIds.first : _nextUserId)
                            : _nextUserId;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Assigned User ID: ${_selectedUserId ?? "Loading..."}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value == null || value.isEmpty ? 'Enter email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Add User', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
