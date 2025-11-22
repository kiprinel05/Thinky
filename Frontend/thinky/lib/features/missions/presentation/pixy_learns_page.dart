import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/mission_service.dart';

class PixyLearnsPage extends StatefulWidget {
  const PixyLearnsPage({super.key});

  @override
  State<PixyLearnsPage> createState() => _PixyLearnsPageState();
}

class _PixyLearnsPageState extends State<PixyLearnsPage>
    with TickerProviderStateMixin {
  List<LearningImage> _images = [];
  Map<String, String> _labels = {};
  bool _isLoading = true;
  bool _showIntroduction = true;
  bool _showCompletion = false;
  int _learnedExamples = 0;
  int _totalExamples = 0;
  double _progressPercentage = 0.0;
  List<String> _categories = [];
  late AnimationController _pixyAnimationController;
  late Animation<double> _pixyScaleAnimation;

  @override
  void initState() {
    super.initState();
    _pixyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pixyScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pixyAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadImages();
  }

  @override
  void dispose() {
    _pixyAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    try {
      final response = await ApiClient.get('/pixy-learns/images');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _images = (data['images'] as List)
              .map((img) => LearningImage.fromJson(img))
              .toList();
          _totalExamples = data['total'] ?? _images.length;
          _isLoading = false;
        });
      } else {
        // Fallback: use hardcoded images if API fails
        setState(() {
          _images = [
            LearningImage(id: 'apple1', url: 'apple'),
            LearningImage(id: 'apple2', url: 'apple'),
            LearningImage(id: 'cat1', url: 'cat'),
            LearningImage(id: 'cat2', url: 'cat'),
            LearningImage(id: 'apple3', url: 'apple'),
            LearningImage(id: 'cat3', url: 'cat'),
          ];
          _totalExamples = _images.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback: use hardcoded images if API fails
      setState(() {
        _images = [
          LearningImage(id: 'apple1', url: 'apple'),
          LearningImage(id: 'apple2', url: 'apple'),
          LearningImage(id: 'cat1', url: 'cat'),
          LearningImage(id: 'cat2', url: 'cat'),
          LearningImage(id: 'apple3', url: 'apple'),
          LearningImage(id: 'cat3', url: 'cat'),
        ];
        _totalExamples = _images.length;
        _isLoading = false;
      });
    }
  }

  void _selectLabel(String imageId, String label) {
    setState(() {
      _labels[imageId] = label;
    });
  }

  void _startMission() {
    setState(() {
      _showIntroduction = false;
    });
  }

  Future<void> _submitLabels() async {
    if (_labels.length < _images.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please label all images before submitting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final labels = _labels.entries
          .map((entry) => {'image_id': entry.key, 'label': entry.value})
          .toList();

      final response = await ApiClient.post('/pixy-learns/label', {
        'labels': labels,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _learnedExamples = data['learned_examples'];
          _progressPercentage = data['progress_percentage'].toDouble();
          _categories = List<String>.from(data['categories']);

          if (_learnedExamples == _totalExamples) {
            _showCompletion = true;
          }
        });

        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pixy learned ${data['learned_examples']} examples!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (response.statusCode == 404) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Endpoint not found. Please restart the backend server.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.statusCode} - ${response.body}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting labels: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFF6B6B),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading images...',
                style: GoogleFonts.alata(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_showIntroduction) {
      return _buildIntroductionScreen();
    }

    if (_showCompletion) {
      return _buildCompletionScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFF6B6B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress section
            _buildProgressSection(),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Pixy mascot
                    _buildPixyMascot(),
                    const SizedBox(height: 24),
                    // Instructions
                    _buildInstructions(),
                    const SizedBox(height: 24),
                    // Images grid
                    _buildImagesGrid(),
                    const SizedBox(height: 24),
                    // Submit button
                    _buildSubmitButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroductionScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFF6B6B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'welcome/page1/background_welcome.png',
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
                width: double.infinity,
              ),
            ),
            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Pixy mascot
                  ScaleInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: ScaleTransition(
                        scale: _pixyScaleAnimation,
                        child: Image.asset(
                          'welcome/page2/thinking.png',
                          height: 220,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Introduction text
                  FadeInWidget(
                    delay: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        "How does Pixy learn?",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.alata(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Help Pixy learn by labeling images! Show Pixy examples of apples and cats, and watch as it learns from them.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.alata(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.95),
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Start button
                  FadeInWidget(
                    delay: const Duration(milliseconds: 600),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _startMission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 22),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'START TEACHING',
                                style: GoogleFonts.alata(
                                  color: const Color(0xFFFF6B6B),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: const Color(0xFFFF6B6B),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Learning Progress',
                style: GoogleFonts.alata(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_learnedExamples}/${_totalExamples}',
                  style: GoogleFonts.alata(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: _progressPercentage / 100,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.white.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPixyMascot() {
    return FadeInWidget(
      delay: const Duration(milliseconds: 200),
      child: Image.asset(
        'welcome/page2/thinking.png',
        height: 120,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildInstructions() {
    return FadeInWidget(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Text(
          'Label each image as "apple" or "cat" to help Pixy learn!',
          textAlign: TextAlign.center,
          style: GoogleFonts.alata(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildImagesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final image = _images[index];
        final selectedLabel = _labels[image.id];
        return _buildImageCard(image, selectedLabel);
      },
    );
  }

  Widget _buildImageCard(LearningImage image, String? selectedLabel) {
    return FadeInWidget(
      delay: Duration(milliseconds: 400 + (image.id.hashCode % 200)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Image.asset(
                    'missions/pixy_learns/images/${image.id}.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to text if image not found
                      return Center(
                        child: Text(
                          image.url.toUpperCase(),
                          style: GoogleFonts.alata(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Label buttons
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildLabelButton(
                      'apple',
                      selectedLabel == 'apple',
                      () => _selectLabel(image.id, 'apple'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLabelButton(
                      'cat',
                      selectedLabel == 'cat',
                      () => _selectLabel(image.id, 'cat'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B6B) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B6B) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.alata(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final allLabeled = _labels.length == _images.length;
    return FadeInWidget(
      delay: const Duration(milliseconds: 500),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: allLabeled ? _submitLabels : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: allLabeled
                ? Colors.white
                : Colors.white.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: allLabeled ? 8 : 0,
            shadowColor: Colors.white.withOpacity(0.3),
          ),
          child: Text(
            'TEACH PIXY',
            style: GoogleFonts.alata(
              color: allLabeled
                  ? const Color(0xFFFF6B6B)
                  : Colors.grey.shade400,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFF6B6B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'welcome/page1/background_welcome.png',
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
                width: double.infinity,
              ),
            ),
            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Pixy mascot
                  ScaleInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: Image.asset(
                      'welcome/page1/hello.png',
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Success message
                  FadeInWidget(
                    delay: const Duration(milliseconds: 400),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Text(
                          'Great Job!',
                          style: GoogleFonts.alata(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Progress display
                  FadeInWidget(
                    delay: const Duration(milliseconds: 500),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Pixy learned ${_learnedExamples} examples!',
                            style: GoogleFonts.alata(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFF6B6B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Categories: ${_categories.join(", ")}',
                              style: GoogleFonts.alata(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFFF6B6B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Message
                  FadeInWidget(
                    delay: const Duration(milliseconds: 600),
                    child: Text(
                      'Pixy now understands the difference between apples and cats! This is how AI learns from examples.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.alata(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Continue button
                  FadeInWidget(
                    delay: const Duration(milliseconds: 700),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'CONTINUE TO MISSIONS',
                              style: GoogleFonts.alata(
                                color: const Color(0xFFFF6B6B),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: const Color(0xFFFF6B6B),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data models
class LearningImage {
  final String id;
  final String url;

  LearningImage({required this.id, required this.url});

  factory LearningImage.fromJson(Map<String, dynamic> json) {
    return LearningImage(id: json['id'], url: json['url']);
  }
}

// PROFESORUL dupa teaches
// de studiat daca nu e nici mar nici pisica? ce face pixy?
