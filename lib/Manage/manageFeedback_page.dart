import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ManageFeedbackPage extends StatelessWidget {
  const ManageFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Feedbacks'),
        backgroundColor: Colors.green.shade600,
        elevation: 4,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Ratings Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: FeedbackRatingChart(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '📝 User Feedbacks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Expanded(child: FeedbackList()),
          ],
        ),
      ),
    );
  }
}

class FeedbackList extends StatefulWidget {
  const FeedbackList({super.key});

  @override
  State<FeedbackList> createState() => _FeedbackListState();
}

class _FeedbackListState extends State<FeedbackList> {
  String selectedType = 'All'; // 初始筛选为全部
  final List<String> types = ['All', 'Bug', 'Suggestion', 'UX', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dropdown filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: DropdownButtonFormField<String>(
            value: selectedType,
            items: types
                .map((type) => DropdownMenuItem(
              value: type,
              child: Text(type),
            ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => selectedType = val);
              }
            },
            decoration: InputDecoration(
              labelText: 'Filter by Type',
              labelStyle: TextStyle(color: Colors.green),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.greenAccent, width: 2),
              ),
            ),
          )

        ),

        // Feedback List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
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

              // 过滤 type
              if (selectedType != 'All') {
                feedbackDocs = feedbackDocs.where((doc) {
                  return doc['type'] == selectedType;
                }).toList();
              }

              if (feedbackDocs.isEmpty) {
                return const Center(child: Text('No feedbacks found.'));
              }

              return ListView.builder(
                itemCount: feedbackDocs.length,
                itemBuilder: (context, index) {
                  var feedback = feedbackDocs[index];
                  int rating = feedback['rating'];
                  String comment = feedback['comment'] ?? '';
                  String type = feedback['type'] ?? 'Other';
                  Timestamp timestamp = feedback['timestamp'] ?? Timestamp.now();

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 6, // 轻微阴影
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.green,
                        child: Text(
                          '$rating★',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        comment.length > 50 ? '${comment.substring(0, 50)}...' : comment,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Type: $type',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Submitted: ${timestamp.toDate()}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('Feedback Details'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(width: 4),
                                    Text('⭐ Rating: $rating', style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('📝 Type: $type', style: TextStyle(fontSize: 14)),
                                const SizedBox(height: 8),
                                Text('📝 Comment:', style: TextStyle(fontSize: 14)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    border: Border.all(color: Colors.green, width: 1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    comment,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Submitted: ${timestamp.toDate()}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );

                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class FeedbackRatingChart extends StatefulWidget {
  const FeedbackRatingChart({super.key});

  @override
  State<FeedbackRatingChart> createState() => _FeedbackRatingChartState();
}

class _FeedbackRatingChartState extends State<FeedbackRatingChart> {
  Map<int, int> ratingCounts = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedbackStats();
  }

  Future<void> _loadFeedbackStats() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('feedbacks').get();

      Map<int, int> counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var doc in snapshot.docs) {
        int rating = doc['rating'];
        if (counts.containsKey(rating)) {
          counts[rating] = counts[rating]! + 1;
        }
      }

      setState(() {
        ratingCounts = counts;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading feedback stats: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                return Text('${value.toInt()}★', style: const TextStyle(fontSize: 12));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: ratingCounts.entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: Colors.green,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
