import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageContactMessagesPage extends StatefulWidget {
  const ManageContactMessagesPage({super.key});

  @override
  State<ManageContactMessagesPage> createState() => _ManageContactMessagesPageState();
}

class _ManageContactMessagesPageState extends State<ManageContactMessagesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 获取所有联系消息
  Future<List<Map<String, dynamic>>> _fetchMessages() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('contactMessages').get();
      return querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'email': doc['email'],
          'message': doc['message'],
          'timestamp': doc['timestamp'],
          'status': doc['status'],
        };
      }).toList();
    } catch (e) {
      print("Error fetching messages: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Contact Messages'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMessages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error fetching messages'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No messages found.'));
          } else {
            List<Map<String, dynamic>> messages = snapshot.data!;
            return ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                var message = messages[index];
                return ListTile(
                  title: Text(message['name']),
                  subtitle: Text(message['message']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message['status']),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          // 点击跳转到详情页面
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MessageDetailPage(
                                messageId: message['id'],
                                name: message['name'],
                                email: message['email'],
                                messageContent: message['message'],
                                timestamp: message['timestamp'],
                                status: message['status'],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class MessageDetailPage extends StatefulWidget {
  final String messageId;
  final String name;
  final String email;
  final String messageContent;
  final Timestamp timestamp;
  final String status;

  const MessageDetailPage({
    super.key,
    required this.messageId,
    required this.name,
    required this.email,
    required this.messageContent,
    required this.timestamp,
    required this.status,
  });

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _noteController = TextEditingController();
  final List<String> _statusOptions = ['Pending', 'In Progress', 'Resolved', 'Closed'];

  String? _adminNote;
  String? _selectedStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAdminNoteAndStatus();
  }

  Future<void> _loadAdminNoteAndStatus() async {
    DocumentSnapshot doc = await _firestore.collection('contactMessages').doc(widget.messageId).get();
    if (doc.exists) {
      setState(() {
        _adminNote = doc['adminNote'] ?? '';
        _noteController.text = _adminNote!;
        _selectedStatus = doc['status'] ?? 'Pending';
      });
    }
  }

  Future<void> _updateStatusAndNote() async {
    if (_selectedStatus == null) return;

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('contactMessages').doc(widget.messageId).update({
        'status': _selectedStatus,
        'adminNote': _noteController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Error updating: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update message')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (shouldDelete == true) {
      _deleteMessage();
    }
  }

  Future<void> _deleteMessage() async {
    try {
      await _firestore.collection('contactMessages').doc(widget.messageId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted')),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Error deleting message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Name: ${widget.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Email: ${widget.email}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Message: ${widget.messageContent}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Timestamp: ${widget.timestamp.toDate()}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Status:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              items: _statusOptions.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Text('Admin Note:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your handling note...',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateStatusAndNote,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Changes'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _confirmDelete,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Message'),
            ),
          ],
        ),
      ),
    );
  }
}
