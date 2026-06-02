import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/app_export.dart';
import '../core/services/auth_service.dart';

extension ImageTypeExtension on String {
  ImageType get imageType {
    if (startsWith('http') || startsWith('https') || startsWith('/')) {
      return ImageType.network;
    } else if (endsWith('.svg')) {
      return ImageType.svg;
    } else if (startsWith('file: //')) {
      return ImageType.file;
    } else {
      return ImageType.png;
    }
  }
}

enum ImageType { svg, png, network, file, unknown }

// ignore_for_file: must_be_immutable
class CustomImageWidget extends StatelessWidget {
  const CustomImageWidget({
    super.key,
    this.imageUrl,
    this.height,
    this.width,
    this.color,
    this.fit,
    this.alignment,
    this.onTap,
    this.radius,
    this.margin,
    this.border,
    this.placeHolder = 'assets/images/no-image.jpg',
    this.errorWidget,
    this.semanticLabel,
  });

  ///[imageUrl] is required parameter for showing image
  final String? imageUrl;

  final double? height;

  final double? width;

  final BoxFit? fit;

  final String placeHolder;

  final Color? color;

  final Alignment? alignment;

  final VoidCallback? onTap;

  final BorderRadius? radius;

  final EdgeInsetsGeometry? margin;

  final BoxBorder? border;

  /// Optional widget to show when the image fails to load.
  /// If null, a default asset image is shown.
  final Widget? errorWidget;

  /// Semantic label for the image to improve accessibility
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(alignment: alignment!, child: _buildWidget())
        : _buildWidget();
  }

  Widget _buildWidget() {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: InkWell(onTap: onTap, child: _buildCircleImage()),
    );
  }

  ///build the image with border radius
  dynamic _buildCircleImage() {
    if (radius != null) {
      return ClipRRect(
        borderRadius: radius ?? BorderRadius.zero,
        child: _buildImageWithBorder(),
      );
    } else {
      return _buildImageWithBorder();
    }
  }

  ///build the image with border and border radius style
  Widget _buildImageWithBorder() {
    if (border != null) {
      return Container(
        decoration: BoxDecoration(border: border, borderRadius: radius),
        child: _buildImageView(),
      );
    } else {
      return _buildImageView();
    }
  }

  Widget _buildImageView() {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      // Handle relative URLs by prepending base URL
      String finalImageUrl = imageUrl!;
      if (imageUrl!.startsWith('/')) {
        finalImageUrl = '${AuthService.baseUrl}$imageUrl';
      }
      
      switch (imageUrl!.imageType) {
        case ImageType.svg:
          return SizedBox(
            height: height,
            width: width,
            child: SvgPicture.asset(
              imageUrl!,
              height: height,
              width: width,
              fit: fit ?? BoxFit.contain,
              colorFilter: color != null
                  ? ColorFilter.mode(
                      color ?? Colors.transparent,
                      BlendMode.srcIn,
                    )
                  : null,
              semanticsLabel: semanticLabel,
            ),
          );
        case ImageType.file:
          // File images are not supported on web
          if (kIsWeb) return _placeholder();
          return Image.asset(
            imageUrl!,
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            color: color,
            semanticLabel: semanticLabel,
          );
        case ImageType.network:
          if (kIsWeb) {
            // Simplified for Web to maximize compatibility with CORS/Edge
            return Image.network(
              finalImageUrl,
              height: height,
              width: width,
              fit: fit ?? BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.grey.shade400),
                      if (imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            imageUrl!,
                            style: const TextStyle(fontSize: 8, color: Colors.grey),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          }
          return CachedNetworkImage(
            height: height,
            width: width,
            fit: fit,
            imageUrl: finalImageUrl,
            color: color,
            placeholder: (context, url) => SizedBox(
              height: 30,
              width: 30,
              child: LinearProgressIndicator(
                color: Colors.grey.shade200,
                backgroundColor: Colors.grey.shade100,
              ),
            ),
            errorWidget: (context, url, error) =>
                errorWidget ?? _placeholder(),
          );
        case ImageType.png:
        default:
          return Image.asset(
            imageUrl!,
            height: height,
            width: width,
            fit: fit ?? BoxFit.cover,
            color: color,
            semanticLabel: semanticLabel,
          );
      }
    }
    return _placeholder();
  }

  Widget _placeholder() => Image.asset(
        placeHolder,
        height: height,
        width: width,
        fit: fit ?? BoxFit.cover,
        semanticLabel: semanticLabel,
      );
}
