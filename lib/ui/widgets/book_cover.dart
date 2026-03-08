import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:reader_flutter/core/constants/app_constants.dart';

/// 书籍封面组件
///
/// 使用 CachedNetworkImage 实现图片缓存和占位符
class BookCover extends StatelessWidget {
  final String url;
  final double size;
  final double? borderRadius;
  final VoidCallback? onTap;

  const BookCover({
    super.key,
    required this.url,
    this.size = 120,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppConstants.borderRadius;

    Widget image = CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(radius),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(
          Icons.book,
          size: size * 0.5,
          color: Colors.grey[400],
        ),
      ),
      memCacheWidth: size.toInt() * 2, // 高清屏适配
      memCacheHeight: size.toInt() * 2,
    );

    if (onTap != null) {
      image = GestureDetector(
        onTap: onTap,
        child: image,
      );
    }

    return image;
  }
}
