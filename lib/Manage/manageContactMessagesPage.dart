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
        backgroundColor: Colors.orangeAccent,
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
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final message = messages[index];
                final timestamp = (message['timestamp'] as Timestamp).toDate();
                final formattedTime =
                    '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';

                return InkWell(
                  onTap: () {
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
                    ).then((refresh) {
                      if (refresh == true) setState(() {});
                    });
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  message['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              _buildStatusChip(message['status']),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            message['message'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Received: $formattedTime',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Pending':
        color = Colors.orange;
        break;
      case 'In Progress':
        color = Colors.blue;
        break;
      case 'Resolved':
        color = Colors.green;
        break;
      case 'Closed':
        color = Colors.grey;
        break;
      default:
        color = Colors.black;
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      Navigator.pop(context, true);
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
      Navigator.pop(context, true);
    } catch (e) {
      print("Error deleting message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete message')),
      );
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(

        title: const Text('Message Details'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Message Info',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        _selectedStatus != null
                            ? _buildStatusChip(_selectedStatus!)
                            : const Chip(
                          label: Text('Loading...', style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.grey,
                        ),

                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Name', widget.name),
                    _buildDetailRow('Email', widget.email),
                    _buildDetailRow('Message', widget.messageContent),
                    _buildDetailRow('Timestamp', _formatTimestamp(widget.timestamp)),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25),
                const Divider(thickness: 1.5),
                const SizedBox(height: 8),
                const Text(
                  'Admin Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatusSelector(),
                const SizedBox(height: 20),
                _buildAdminNoteField(),
                const SizedBox(height: 16),
                _buildActionButtons(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
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
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status) {
      case 'Pending':
        chipColor = Colors.orange;
        break;
      case 'In Progress':
        chipColor = Colors.blue;
        break;
      case 'Resolved':
        chipColor = Colors.green;
        break;
      case 'Closed':
        chipColor = Colors.grey;
        break;
      default:
        chipColor = Colors.black45;
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: chipColor,
    );
  }

  Widget _buildAdminNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Admin Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter your handling note...',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.save, color: Colors.white),
          label: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
            'Save Changes',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: _isLoading ? null : _updateStatusAndNote,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete_forever, color: Colors.white),
          label: const Text(
            'Delete Message',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: _isLoading ? null : _confirmDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

}
