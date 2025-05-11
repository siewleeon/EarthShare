import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RateFeedbackPage extends StatefulWidget {
  const RateFeedbackPage({super.key});

  @override
  State<RateFeedbackPage> createState() => _RateFeedbackPageState();
}

class _RateFeedbackPageState extends State<RateFeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _rating = 5;
  String _feedbackType = 'Suggestion';

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('feedbacks').add({
          'rating': _rating,
          'comment': _commentController.text.trim(),
          'type': _feedbackType,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Thank You!'),
            content: const Text('Your feedback has been submitted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        _formKey.currentState!.reset();
        _commentController.clear();
        setState(() {
          _rating = 5;
        });
      } catch (e) {
        print("Error submitting feedback: $e");

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Something went wrong. Please try again later.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color(0xFFCCFF66),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Rate us and Feedback',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
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
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/default_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text(
                    'We value your feedback!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text('Rating:'),
                  DropdownButtonFormField<int>(
                    value: _rating,
                    items: List.generate(5, (i) => i + 1)
                        .map((num) => DropdownMenuItem(
                      value: num,
                      child: Text('$num Stars'),
                    ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _rating = val);
                      }
                    },
                  ),

                  const Text('Feedback Type:'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _feedbackType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: ['Bug', 'Suggestion', 'UX', 'Other']
                        .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _feedbackType = val);
                      }
                    },
                  ),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      labelText: 'Comment',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a comment' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Submit Feedback'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



}
