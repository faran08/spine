import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ReportScreen extends StatefulWidget {
  final String studyId;
  const ReportScreen({super.key, required this.studyId});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _reportController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<String> sagT1Images = [];
  List<String> sagT2Images = [];
  List<String> axialImages = [];

  bool isLoading = true;
  List<Map<String, dynamic>> previousReports = [];

  @override
  void initState() {
    super.initState();
    loadImageData();
    loadPreviousReports();
  }

  /// 🔥 Loads Image Data Safely from JSON
  Future<void> loadImageData() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/flutter_image_data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      if (jsonData.containsKey(widget.studyId)) {
        setState(() {
          sagT1Images =
              List<String>.from(jsonData[widget.studyId]["sagittal_t1"] ?? []);
          sagT2Images =
              List<String>.from(jsonData[widget.studyId]["sagittal_t2"] ?? []);
          axialImages =
              List<String>.from(jsonData[widget.studyId]["axial"] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading image data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 🔥 Loads Previous Reports from Firestore
  Future<void> loadPreviousReports() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("reports")
          .where("study_id", isEqualTo: widget.studyId)
          .get(); // 🔥 No ordering in Firestore query

      setState(() {
        previousReports = snapshot.docs
            .map((doc) => {
                  "name": doc["name"],
                  "report": doc["report"],
                  "timestamp":
                      doc["timestamp"].toDate() // Handle missing timestamps
                })
            .toList();

        // 🔥 Sort the reports locally in descending order
        previousReports
            .sort((a, b) => b["timestamp"].compareTo(a["timestamp"]));
      });
    } catch (e) {
      print("Error loading previous reports: $e");
    }
  }

  /// 🔥 Builds Image Rows with Scrollable ListView
  Widget buildImageRow(String title, List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: images.isNotEmpty
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _openGallery(images, index),
                      child: Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            images[index],
                            width: 140,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: Text("No images available",
                      style: TextStyle(color: Colors.grey)),
                ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget buildAxialImageRow(String title, List<String> images) {
    List<Map<String, dynamic>> sortedImages = [];

    // Define the correct lumbar level order
    List<String> lumbarOrder = ["L1L2", "L2L3", "L3L4", "L4L5", "L5S1"];

    // Extract instance number and level, store in a list
    for (String imagePath in images) {
      final RegExp regex = RegExp(r'(\d+)_([A-Za-z0-9]+)\.png$');
      final match = regex.firstMatch(imagePath);

      if (match != null) {
        final int instanceNumber = int.parse(match.group(1)!);
        final String level = match.group(2)!;

        sortedImages.add({
          "path": imagePath,
          "instance": instanceNumber,
          "level": level,
          "levelIndex": lumbarOrder.indexOf(level) // Get index for sorting
        });
      }
    }

    // Sort first by levelIndex (lumbar order), then by instance number
    sortedImages.sort((a, b) {
      int levelCompare = a["levelIndex"].compareTo(b["levelIndex"]);
      return (levelCompare != 0)
          ? levelCompare
          : a["instance"].compareTo(b["instance"]);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        SizedBox(
          height: 220, // Increased height to accommodate label
          child: sortedImages.isNotEmpty
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: sortedImages.length,
                  itemBuilder: (context, index) {
                    final imagePath = sortedImages[index]["path"];
                    final levelName = sortedImages[index]["level"];

                    return GestureDetector(
                      onTap: () => _openGallery(images, index),
                      child: Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                imagePath,
                                width: 140,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              child: Container(
                                width: 140,
                                color: Colors.white.withOpacity(0.8),
                                padding: EdgeInsets.symmetric(vertical: 5),
                                child: Text(
                                  levelName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: Text("No images available",
                      style: TextStyle(color: Colors.grey)),
                ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  /// 🔥 Open Photo View Gallery for image navigation
  void _openGallery(List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryPhotoViewWrapper(
          galleryItems: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  /// 🔥 Submits Report to Firestore with Validation
  void submitReport() {
    if (_formKey.currentState!.validate()) {
      FirebaseFirestore.instance.collection("reports").add({
        "study_id": widget.studyId,
        "name": _nameController.text,
        "report": _reportController.text,
        "timestamp": FieldValue.serverTimestamp(),
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Report submitted successfully!")),
        );
        Navigator.pop(context); // Return to home screen
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting report: $error")),
        );
      });
    }
  }

  /// 🔥 Builds Previous Reports Section
  Widget buildPreviousReports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Previous Reports",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        previousReports.isEmpty
            ? Text("No previous reports available",
                style: TextStyle(color: Colors.grey))
            : Container(
                height: 200,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: previousReports.length,
                  itemBuilder: (context, index) {
                    var report = previousReports[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Card(
                        elevation: 3,
                        child: ListTile(
                          title: Text(
                            report["name"],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Text(
                            "${report["timestamp"].toLocal()}",
                            style: TextStyle(fontSize: 12, color: Colors.black),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report for ${widget.studyId}')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey, // Form key for validation
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildImageRow("Sagittal T1", sagT1Images),
                    buildImageRow("Sagittal T2", sagT2Images),
                    buildAxialImageRow("Axial T2", axialImages),

                    buildPreviousReports(), // 🔥 Show previous reports

                    // 🔥 Doctor Name Input
                    Text("Doctor's Name",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Enter Doctor's Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Doctor's name is required" : null,
                      ),
                    ),
                    SizedBox(height: 10),

                    // 🔥 Report Text Box
                    Text("Report",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextFormField(
                        controller: _reportController,
                        decoration: InputDecoration(
                          labelText: "Enter Report",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 5,
                        validator: (value) =>
                            value!.isEmpty ? "Report cannot be empty" : null,
                      ),
                    ),
                    SizedBox(height: 20),

                    Center(
                      child: ElevatedButton(
                        onPressed: submitReport,
                        child: Text("Submit Report",
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class GalleryPhotoViewWrapper extends StatefulWidget {
  final List<String> galleryItems;
  final int initialIndex;

  const GalleryPhotoViewWrapper({
    super.key,
    required this.galleryItems,
    this.initialIndex = 0,
  });

  @override
  _GalleryPhotoViewWrapperState createState() =>
      _GalleryPhotoViewWrapperState();
}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper> {
  late int currentIndex;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: widget.initialIndex);
  }

  /// Extracts level from filename: `instanceNumber_Level.png`
  String _extractLevel(String imagePath) {
    final RegExp regex = RegExp(r'(\d+)_([A-Za-z0-9]+)\.png$');
    final match = regex.firstMatch(imagePath);
    return match != null ? match.group(2)! : "Unknown";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Image ${currentIndex + 1} / ${widget.galleryItems.length}",
              style: TextStyle(color: Colors.white),
            ),
            Text(
              "Level: ${_extractLevel(widget.galleryItems[currentIndex])}",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.black),
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: AssetImage(widget.galleryItems[index]),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              itemCount: widget.galleryItems.length,
              loadingBuilder: (context, event) => Center(
                child: SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(),
                ),
              ),
              backgroundDecoration: BoxDecoration(color: Colors.black),
              pageController: pageController,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
            ),
            // Navigation arrows
            if (widget.galleryItems.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous button
                    FloatingActionButton(
                      heroTag: "prev",
                      backgroundColor: Colors.white.withOpacity(0.7),
                      mini: true,
                      child: Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    SizedBox(width: 30),
                    // Next button
                    FloatingActionButton(
                      heroTag: "next",
                      backgroundColor: Colors.white.withOpacity(0.7),
                      mini: true,
                      child: Icon(Icons.arrow_forward, color: Colors.black),
                      onPressed: () {
                        pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
