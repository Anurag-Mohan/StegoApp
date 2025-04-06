import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'processing.dart';
import 'extraction.dart';
import 'p2p_chat.dart';
import 'package:characters/characters.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = isDarkMode ? const Color(0xFF6A3DE8) : const Color(0xFF3D5AFE);
    final accentColor = isDarkMode ? const Color(0xFFB388FF) : const Color(0xFF536DFE);
    
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
            title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [

              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: Colors.white,
              ).animate().fadeIn(duration: 400.ms).then()
                .rotate(duration: 800.ms).then()
                .scale(duration: 400.ms, alignment: Alignment.center),
                
              const SizedBox(width: 8),

              ...'Steganography'.characters.map((char) {
                return Text(
                  char,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ).animate(delay: 100.ms * 'Steganography'.characters.toList().indexOf(char))
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
              }).toList(),
            ],
          ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [const Color(0xFF1A237E), const Color(0xFF311B92)]
                        : [const Color(0xFF3D5AFE), const Color(0xFF7C4DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -30,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -40,
                      bottom: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    Center(
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: CustomPaint(
                          painter: WavePainter(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .scale(
                          duration: 1500.ms, 
                          curve: Curves.easeInOut,
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2),
                        )
                        .then()
                        .scale(
                          duration: 1500.ms, 
                          curve: Curves.easeInOut,
                          begin: const Offset(1.2, 1.2),
                          end: const Offset(0.8, 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.security_rounded),
                tooltip: 'Security Settings',
                onPressed: () {
                  Navigator.pushNamed(context, '/setup');
                },
              ).animate().fadeIn(delay: 300.ms),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                tooltip: 'About',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.security_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Steganography App',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Version 1.0.0',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hide and extract secret messages in images and videos using advanced steganography techniques.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Keep your communications private and secure.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: theme.hintColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                },
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),

          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Secure Data Operations',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onBackground,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 10),
                  Text(
                    'Choose an operation to begin your steganography process',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 40),
                  

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      
                      Card(
                        elevation: 6,
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (ctx) => P2PChatPage()),
                            );
                          },
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: isDarkMode 
                                    ? [const Color(0xFF4A148C), const Color(0xFF7B1FA2)]
                                    : [const Color(0xFF7C4DFF), const Color(0xFFB388FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_rounded,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Secure P2P Chat',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Encrypted offline messaging with friends nearby',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(
                        begin: 0.3,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOutQuint,
                      ),
                      
                     
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        children: [
                          _buildOperationCard(
                            context,
                            icon: Icons.lock_rounded,
                            title: 'Hide Text',
                            subtitle: 'Embed text message in an image file',
                            colors: isDarkMode 
                                ? [const Color(0xFF5C6BC0), const Color(0xFF3949AB)]
                                : [const Color(0xFF42A5F5), const Color(0xFF1976D2)],
                            delay: 100.ms,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TextInputPage(),
                                ),
                              );
                            },
                          ),
                          _buildOperationCard(
                            context,
                            icon: Icons.lock_open_rounded,
                            title: 'Extract Text',
                            subtitle: 'Retrieve hidden text from steganographic image',
                            colors: isDarkMode 
                                ? [const Color(0xFF66BB6A), const Color(0xFF388E3C)]
                                : [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
                            delay: 200.ms,
                            onTap: () async {
                              final XFile? image = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 100,
                              );
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
                          _buildOperationCard(
                            context,
                            icon: Icons.image_rounded,
                            title: 'Hide Image',
                            subtitle: 'Conceal an image within another image',
                            colors: isDarkMode 
                                ? [const Color(0xFFFFB74D), const Color(0xFFFF9800)]
                                : [const Color(0xFFFFA726), const Color(0xFFE65100)],
                            delay: 300.ms,
                            onTap: () async {
                              await _pickTwoImagesAndNavigate(
                                context,
                                (secret, carrier) => ProcessImageInImagePage(
                                  secretImageUri: secret,
                                  carrierUri: carrier,
                                ),
                              );
                            },
                          ),
                          _buildOperationCard(
                            context,
                            icon: Icons.image_search_rounded,
                            title: 'Extract Image',
                            subtitle: 'Recover hidden image from steganographic image',
                            colors: isDarkMode 
                                ? [const Color(0xFFAB47BC), const Color(0xFF7B1FA2)]
                                : [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)],
                            delay: 400.ms,
                            onTap: () async {
                              await _pickImageAndNavigate(
                                context,
                                (path) => ExtractImageFromImagePage(carrierUri: path),
                              );
                            },
                          ),
                          _buildOperationCard(
                            context,
                            icon: Icons.video_library_rounded,
                            title: 'Hide in Video',
                            subtitle: 'Embed an image within video frames',
                            colors: isDarkMode 
                                ? [const Color(0xFFEF5350), const Color(0xFFD32F2F)]
                                : [const Color(0xFFF44336), const Color(0xFFB71C1C)],
                            delay: 500.ms,
                            onTap: () async {
                              await _pickImageAndVideoAndNavigate(context);
                            },
                          ),
                          _buildOperationCard(
                            context,
                            icon: Icons.video_settings_rounded,
                            title: 'Extract Video',
                            subtitle: 'Recover hidden image from steganographic video',
                            colors: isDarkMode 
                                ? [const Color(0xFF26A69A), const Color(0xFF00796B)]
                                : [const Color(0xFF009688), const Color(0xFF00695C)],
                            delay: 600.ms,
                            onTap: () async {
                              await _pickVideoAndNavigate(
                                context,
                                (path) => ExtractImageFromVideoPage(carrierVideoUri: path),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: isDarkMode 
                    ? Colors.blueGrey.shade900 
                    : Colors.blueGrey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.security_rounded,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Security First',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'All operations are performed locally on your device. Your data never leaves your phone for maximum privacy and security.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: theme.colorScheme.onBackground.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms).slideY(
                begin: 0.3,
                end: 0,
                duration: 600.ms,
                curve: Curves.easeOutQuint,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 30),
          ),
        ],
      ),
    );
  }


  Future<void> _pickImageAndNavigate(
    BuildContext context,
    Widget Function(String path) builder,
  ) async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (image != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => builder(image.path),
        ),
      );
    }
  }

  Future<void> _pickTwoImagesAndNavigate(
    BuildContext context,
    Widget Function(String secret, String carrier) builder,
  ) async {

    bool? shouldContinue = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Two Images',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You will need to select two images:\n\n1. First, the secret image to hide\n2. Second, the carrier image',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldContinue != true) return;

    final XFile? secretImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (secretImage != null && context.mounted) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Secret image selected. Please select the carrier image.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      
      final XFile? carrierImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (carrierImage != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => builder(secretImage.path, carrierImage.path),
          ),
        );
      }
    }
  }

  Future<void> _pickVideoAndNavigate(
    BuildContext context,
    Widget Function(String path) builder,
  ) async {
    final XFile? video = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
    );
    if (video != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => builder(video.path),
        ),
      );
    }
  }

  Future<void> _pickImageAndVideoAndNavigate(BuildContext context) async {

    bool? shouldContinue = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Image and Video',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You will need to select:\n\n1. First, the secret image to hide\n2. Second, the carrier video',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldContinue != true) return;

    final XFile? secretImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (secretImage != null && context.mounted) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Secret image selected. Please select the carrier video.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      
      final XFile? carrierVideo = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
      );
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
  }


  Widget _buildOperationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required Duration delay,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shadowColor: colors[0].withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: colors[0].withOpacity(0.2),
        highlightColor: colors[0].withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 30, color: Colors.white),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fadeIn(delay: delay, duration: 400.ms)
                    .scale(
                      delay: delay, 
                      curve: Curves.easeOutBack, 
                      duration: 600.ms
                    )
                    .then(delay: 2000.ms)
                    .shimmer(duration: 1200.ms, color: Colors.white)
                    .then(delay: 2000.ms)
                    .rotate(duration: 500.ms, begin: 0, end: 0.05)
                    .then()
                    .rotate(duration: 500.ms, begin: 0.05, end: -0.05)
                    .then()
                    .rotate(duration: 500.ms, begin: -0.05, end: 0),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ).animate().fadeIn(delay: delay + 100.ms),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ).animate().fadeIn(delay: delay + 200.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().slideY(
            begin: 0.3,
            end: 0,
            duration: 600.ms,
            delay: delay,
            curve: Curves.easeOutQuint,
          ),
    );
  }
}


class WavePainter extends CustomPainter {
  final Color color;
  
  WavePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    for (int i = 1; i <= 3; i++) {
      final paint = Paint()
        ..color = color.withOpacity(1.0 - (i * 0.25))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
        
      canvas.drawCircle(center, radius * i * 0.8, paint);
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}