import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFeedbackListPage extends StatelessWidget {
  const AdminFeedbackListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Feedbacks'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedbacks')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading feedbacks.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var feedbackDocs = snapshot.data!.docs;

          if (feedbackDocs.isEmpty) {
            return const Center(child: Text('No feedbacks yet.'));
          }

          return ListView.builder(
            itemCount: feedbackDocs.length,
            itemBuilder: (context, index) {
              var feedback = feedbackDocs[index];
              int rating = feedback['rating'];
              String comment = feedback['comment'] ?? '';
              Timestamp timestamp = feedback['timestamp'] ?? Timestamp.now();

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text('$rating★'),
                  ),
                  title: Text(comment),
                  subtitle: Text(
                    'Submitted: ${timestamp.toDate()}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
