import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add Firestore import
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> studyIds = [];
  Map<String, List<Map<String, dynamic>>> reportsData =
      {}; // Add reports data map

  @override
  void initState() {
    super.initState();
    loadStudyIds();
  }

  Future<void> loadStudyIds() async {
    final String jsonString =
        await rootBundle.loadString('assets/flutter_image_data.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    setState(() {
      studyIds = jsonData.keys.toList();
    });

    await loadAllReports(); // Load all reports at once
  }

  Future<void> loadAllReports() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection("reports").get();

      Map<String, List<Map<String, dynamic>>> tempReportsData = {};

      for (var doc in snapshot.docs) {
        String studyId = doc["study_id"];
        if (!tempReportsData.containsKey(studyId)) {
          tempReportsData[studyId] = [];
        }
        tempReportsData[studyId]!.add({
          "name": doc["name"],
          "report": doc["report"],
          "timestamp": doc["timestamp"].toDate()
        });
      }

      setState(() {
        reportsData = tempReportsData;
        reportsData.forEach((key, value) {
          value.sort((a, b) => b["timestamp"].compareTo(a["timestamp"]));
        });
      });
    } catch (e) {
      print("Error loading reports: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Spinalis DxGen',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: studyIds.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(10),
              child: ListView.builder(
                itemCount: studyIds.length,
                itemBuilder: (context, index) {
                  String studyId = studyIds[index];
                  List<Map<String, dynamic>>? reports = reportsData[studyId];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportScreen(studyId: studyId),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.folder, size: 50, color: Colors.blue),
                            SizedBox(height: 10),
                            Text(
                              'Study ID: $studyId',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            if (reports != null && reports.isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: reports
                                      .fold<Map<String, int>>({},
                                          (acc, report) {
                                        acc[report["name"]] =
                                            (acc[report["name"]] ?? 0) + 1;
                                        return acc;
                                      })
                                      .entries
                                      .map((entry) => Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 5,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${entry.key}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  '${entry.value} report(s)',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ReportScreen(studyId: studyId),
                                  ),
                                );
                              },
                              child: Text(
                                "Write Report",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
