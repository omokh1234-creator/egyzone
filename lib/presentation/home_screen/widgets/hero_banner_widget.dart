import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

class HeroBannerWidget extends StatefulWidget {
  const HeroBannerWidget({super.key});

  @override
  State<HeroBannerWidget> createState() => _HeroBannerWidgetState();
}

class _HeroBannerWidgetState extends State<HeroBannerWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _banners = [
    {
      "title": "New Arrivals",
      "subtitle": "Discover the latest products",
      "image": "assets/images/iPhone_15_Pro/iPhone-15-Pro-Lineup-Feature.jpg",
      "semanticLabel": "Modern laptop computer with wireless mouse and plant on white desk",
      "action": "New Arrivals",
    },
    {
      "title": "Fashion",
      "subtitle": "Up to 50% off on selected items",
      "image": "assets/images/Kids_hodie/JH01J_LS05_2021.png",
      "semanticLabel": "Colorful shopping bags and gift boxes on pink background",
      "action": "Fashion",
    },
    {
      "title": "Tech Essentials",
      "subtitle": "Upgrade your workspace",
      "image": "assets/images/sony Headphones/UZdqRXXVyMqVELiCvRHbS7.jpg",
      "semanticLabel": "Modern workspace with laptop, smartphone, and coffee on wooden desk",
      "action": "Electronics",
    },
  ];

  @override
  void initState() {
    super.initState();
    _startPlay();
  }

  void _startPlay() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        final nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startPlay();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 22.h,
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      child: Stack(
        children: [
          // Banner PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return GestureDetector(
                onTap: () {
                  final action = banner['action'] as String?;
                  if (action == 'New Arrivals') {
                    Navigator.pushNamed(context, '/search-screen', arguments: {'sortBy': 'Newest'});
                  } else if (action == 'Fashion') {
                    Navigator.pushNamed(context, '/search-screen', arguments: {'category': 'Fashion'});
                  } else if (action == 'Electronics') {
                    Navigator.pushNamed(context, '/search-screen', arguments: {'category': 'Electronics'});
                  }
                },
                child: _BannerCard(
                  title: banner['title'] as String,
                  subtitle: banner['subtitle'] as String,
                  imageUrl: banner['image'] as String,
                  semanticLabel: banner['semanticLabel'] as String,
                ),
              );
            },
          ),

          // Page Indicators
          Positioned(
            bottom: 1.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _banners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                  width: _currentPage == index ? 8.w : 2.w,
                  height: 1.h,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual banner card with image and text overlay
class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.semanticLabel,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate banner height based on width (2:1 ratio)
            final bannerHeight = constraints.maxWidth * 0.5;

            return SizedBox(
              width: constraints.maxWidth, // Fill available width
              height: bannerHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Banner Image
                  CustomImageWidget(
                    imageUrl: imageUrl,
                    width: constraints.maxWidth,
                    height: bannerHeight,
                    fit: BoxFit.cover,
                    semanticLabel: semanticLabel,
                  ),

                  // Optional gradient overlay for readability
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black38, // smooth fade at bottom
                        ],
                      ),
                    ),
                  ),

                  // Overlay text aligned at bottom-left
                  Positioned(
                    bottom: 2.h, // using Sizer for responsive spacing
                    left: 3.w,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp, // responsive font size
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
