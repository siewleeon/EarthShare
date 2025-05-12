import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageContactMessagesPage extends StatefulWidget {
  const ManageContactMessagesPage({super.key});

  @override
  State<ManageContactMessagesPage> createState() => _ManageContactMessagesPageState();
}

class _ManageContactMessagesPageState extends State<ManageContactMessagesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  List<Map<String, dynamic>> _allMessages = [];
  List<Map<String, dynamic>> _filteredMessages = [];
  // 获取所有联系消息
  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      final snapshot = await _firestore.collection('contactMessages').get();
      final messages = snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['name'],
        'email': doc['email'],
        'message': doc['message'],
        'timestamp': doc['timestamp'],
        'status': doc['status'],
      }).toList();

      setState(() {
        _allMessages = messages;
        _filteredMessages = messages;
      });
    } catch (e) {
      print("Error fetching messages: $e");
    }
  }

  void _filterMessages(String query) {
    setState(() {
      _searchQuery = query;
      _filteredMessages = _allMessages.where((msg) {
        final name = msg['name'].toString().toLowerCase();
        final email = msg['email'].toString().toLowerCase();
        final message = msg['message'].toString().toLowerCase();
        return name.contains(query.toLowerCase()) ||
            email.contains(query.toLowerCase()) ||
            message.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Manage Contact Messages'),
        backgroundColor: Colors.orangeAccent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
      ),
      body: Column(
        children: [
          // 🔍 SearchBar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: _filterMessages,
              decoration: InputDecoration(
                hintText: 'Search messages...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
            ),
          ),

          // 📋 Message List
          Expanded(
            child: _filteredMessages.isEmpty
                ? const Center(child: Text('No matching messages found.'))
                : ListView.builder(
              itemCount: _filteredMessages.length,
              itemBuilder: (context, index) {
                final message = _filteredMessages[index];
                final timestamp = (message['timestamp'] as Timestamp).toDate();
                final formattedTime = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    title: Text(message['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message['message'], maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('Received: $formattedTime', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    trailing: _buildStatusChip(message['status']),
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
                        if (refresh == true) _fetchMessages();
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
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
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
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
