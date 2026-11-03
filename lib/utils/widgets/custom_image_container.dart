import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hyper_local/config/colors.dart';

import '../../config/helper.dart';

class CustomImageContainer extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool? isForCategoryTab;

  const CustomImageContainer({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
    this.placeholder,
    this.errorWidget,
    this.isForCategoryTab = false,
  });

  @override
  Widget build(BuildContext context) {
    // log('IMAGE ____ $imagePath');

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child:
            imagePath.endsWith('.svg')
                ? SvgPicture.asset(
                  imagePath,
                  width: width,
                  height: height,
                  colorMapper: const CustomColorMapper(
                    targetColor: Color(
                      0xFF006BD5,
                    ), // The exact color inside the SVG
                    replacementColor: AppColors.primaryColor,
                  ),
                  fit: fit,
                )
                : isNetworkImage(imagePath)
                ? CachedNetworkImage(
                  imageUrl: imagePath,
                  width: width,
                  height: height,
                  fit: fit,
                  filterQuality: FilterQuality.high,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  useOldImageOnUrlChange: true,
                  imageBuilder: (context, imageProvider) {
                    return Image(image: imageProvider, fit: fit);
                  },
                  errorWidget: (context, url, error) {
                    return errorWidget ??
                        Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 50,
                          ),
                        );
                  },
                )
                : Image.asset(
                  imagePath,
                  width: width,
                  height: height,
                  fit: fit,
                  errorBuilder: (context, error, stackTrace) {
                    return errorWidget ??
                        Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 100,
                          ),
                        );
                  },
                ),
      ),
    );
  }
}

class CustomAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Widget? fallbackIcon;

  const CustomAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24.0,
    this.backgroundColor,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          backgroundColor ??
          Theme.of(context).primaryColor.withValues(alpha: 0.1),
      backgroundImage:
          (imageUrl != null &&
                  imageUrl!.isNotEmpty &&
                  isNetworkImage(imageUrl!))
              ? CachedNetworkImageProvider(imageUrl!)
              : null,
      child:
          (imageUrl != null && imageUrl!.isNotEmpty)
              ? null
              : fallbackIcon ??
                  Icon(
                    Icons.person,
                    size: radius,
                    color: Theme.of(context).primaryColor,
                  ),
    );
  }
}
