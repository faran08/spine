import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ImageCarousel extends StatelessWidget {
  final List<String> imagePaths;
  final bool showLevels;

  const ImageCarousel(
      {super.key, required this.imagePaths, this.showLevels = true});

  @override
  Widget build(BuildContext context) {
    return imagePaths.isEmpty
        ? Text("No images available")
        : CarouselSlider(
            options: CarouselOptions(
              height: 250,
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
            ),
            items: imagePaths.map((path) {
              // Extract instance number and level from filename
              final RegExp regex = RegExp(r'(\d+)_([A-Za-z0-9]+)\.png$');
              final match = regex.firstMatch(path);
              final String levelName =
                  match != null ? match.group(2)! : "Unknown";

              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: Image.asset(path, fit: BoxFit.cover),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        path,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  if (showLevels) // Conditionally show level text
                    Positioned(
                      bottom: 5,
                      child: Container(
                        width: 160,
                        padding:
                            EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          levelName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
          );
  }
}
