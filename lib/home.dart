import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'processing.dart';
import 'extraction.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Steganography App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: () {
              Navigator.pushNamed(context, '/setup');
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Steganography App',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2023 Steganography App',
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Hide and extract secret messages in images and videos using advanced steganography techniques.',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Steganography Operations',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Choose an operation to begin',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  OperationCard(
                    icon: Icons.lock,
                    title: 'Hide Text',
                    subtitle: 'Text in an image',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TextInputPage(),
                        ),
                      );
                    },
                  ),
                  OperationCard(
                    icon: Icons.lock_open,
                    title: 'Extract Text',
                    subtitle: 'Text from image',
                    color: Colors.green,
                    onTap: () async {
                      final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (image != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExtractTextPage(
                              carrierUri: image.path,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  OperationCard(
                    icon: Icons.image,
                    title: 'Hide Image',
                    subtitle: 'Image in Image',
                    color: Colors.orange,
                    onTap: () async {
                      final XFile? secretImage = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (secretImage != null && context.mounted) {
                        final XFile? carrierImage = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (carrierImage != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProcessImageInImagePage(
                                secretImageUri: secretImage.path,
                                carrierUri: carrierImage.path,
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  OperationCard(
                    icon: Icons.image_search,
                    title: 'Extract Image',
                    subtitle: 'image from image',
                    color: Colors.purple,
                    onTap: () async {
                      final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (image != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExtractImageFromImagePage(
                              carrierUri: image.path,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  OperationCard(
                    icon: Icons.video_library,
                    title: 'Hide in Video',
                    subtitle: 'Image in video',
                    color: Colors.red,
                    onTap: () async {
                      final XFile? secretImage = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (secretImage != null && context.mounted) {
                        final XFile? carrierVideo = await ImagePicker().pickVideo(source: ImageSource.gallery);
                        if (carrierVideo != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProcessImageInVideoPage(
                                secretImageUri: secretImage.path,
                                carrierVideoUri: carrierVideo.path,
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  OperationCard(
                    icon: Icons.video_settings,
                    title: 'Extract  Video',
                    subtitle: 'Image from video',
                    color: Colors.teal,
                    onTap: () async {
                      final XFile? video = await ImagePicker().pickVideo(source: ImageSource.gallery);
                      if (video != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExtractImageFromVideoPage(
                              carrierVideoUri: video.path,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class OperationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const OperationCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}