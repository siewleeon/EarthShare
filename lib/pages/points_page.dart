import 'package:flutter/material.dart';
import '../models/point.dart';
import '../services/points_service.dart';

class PointsPage extends StatefulWidget {
  final String userId;
  const PointsPage({super.key, required this.userId});

  @override
  State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  int totalPoints = 0;
  List<Point> pointHistory = [];

  @override
  void initState() {
    super.initState();
    loadPoints();
  }

  Future<void> loadPoints() async {
    final points = await PointsService.getUserPoints(widget.userId);
    final total = await PointsService.getUserTotalPoints(widget.userId);
    setState(() {
      pointHistory = points;
      totalPoints = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Points Summary'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.green[100],
            child: Column(
              children: [
                Text('Total Points', style: TextStyle(fontSize: 20)),
                SizedBox(height: 8),
                Text('$totalPoints', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: pointHistory.length,
              itemBuilder: (context, index) {
                final p = pointHistory[index];
                return ListTile(
                  leading: Icon(
                    p.isIncrease ? Icons.add : Icons.remove,
                    color: p.isIncrease ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    '${p.isIncrease ? '+' : '-'}${p.points} pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: p.isIncrease ? Colors.green : Colors.red,
                    ),
                  ),
                  subtitle: Text(p.description),
                  trailing: Text(
                    '${p.createdAt.year}-${p.createdAt.month.toString().padLeft(2, '0')}-${p.createdAt.day.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
