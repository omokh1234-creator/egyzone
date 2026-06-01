import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../widgets/custom_image_widget.dart';

class ProductImageCarouselWidget extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final String productId;

  const ProductImageCarouselWidget({
    super.key,
    required this.images,
    required this.productId,
  });

  @override
  State<ProductImageCarouselWidget> createState() =>
      _ProductImageCarouselWidgetState();
}

class _ProductImageCarouselWidgetState
    extends State<ProductImageCarouselWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  String _imageUrl(Map<String, dynamic> image) {
    final url = (image['url'] ?? image['imageUrl']) as String? ?? '';
    return url;
  }

  void _handleDoubleTap() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.0) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.diagonal3Values(2.0, 2.0, 2.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = widget.images;

    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: Stack(
        children: [
          // ── Image PageView ──────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _transformationController.value = Matrix4.identity();
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              final url = _imageUrl(images[index]);

              return GestureDetector(
                onTap: () => _showFullScreenImage(context, index),
                onDoubleTap: _handleDoubleTap,
                child: _CarouselImage(
                  url: url,
                  transformationController: _transformationController,
                ),
              );
            },
          ),

          // ── Page indicators ─────────────────────────────────────────────
          if (images.length > 1)
            Positioned(
              bottom: 2.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 1.w),
                    width: _currentPage == index ? 8.w : 2.w,
                    height: 1.h,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
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

  void _showFullScreenImage(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(
          images: widget.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

// ── Single carousel image ──────────────────────────────────────────────────────

class _CarouselImage extends StatelessWidget {
  const _CarouselImage({
    required this.url,
    required this.transformationController,
  });
  final String url;
  final TransformationController transformationController;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _placeholder();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          transformationController: transformationController,
          panEnabled: true,
          scaleEnabled: true,
          minScale: 0.8,
          maxScale: 5.0,
          clipBehavior: Clip.none,
          child: Center(
            child: CustomImageWidget(
              imageUrl: url,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              fit: BoxFit.contain,
              errorWidget: _placeholder(),
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        ),
      );
}

// ── Full-screen viewer ─────────────────────────────────────────────────────────

class _FullScreenImageViewer extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentPage;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  String _imageUrl(Map<String, dynamic> image) =>
      (image['url'] ?? image['imageUrl']) as String? ?? '';

  void _handleDoubleTap() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.0) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.diagonal3Values(2.0, 2.0, 2.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentPage + 1} / ${widget.images.length}',
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map, color: Colors.white, size: 24),
            onPressed: () => _transformationController.value = Matrix4.identity(),
            tooltip: 'Reset Zoom',
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
          _transformationController.value = Matrix4.identity();
        },
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          final url = _imageUrl(widget.images[index]);

          return LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 0.8,
                  maxScale: 5.0,
                  clipBehavior: Clip.none,
                  child: Center(
                    child: url.isNotEmpty
                        ? CustomImageWidget(
                            imageUrl: url,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            fit: BoxFit.contain,
                            errorWidget: const Icon(
                              Icons.image_not_supported,
                              color: Colors.white54,
                              size: 64,
                            ),
                          )
                        : const Icon(
                            Icons.image_not_supported,
                            color: Colors.white54,
                            size: 64,
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
