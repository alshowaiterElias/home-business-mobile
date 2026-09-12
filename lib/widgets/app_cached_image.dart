import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../core/network/api_client.dart';
import '../core/theme/app_theme.dart';

/// A centralized, high-performance cached image widget designed for:
/// 1. Slow network connections (disk caching via [CachedNetworkImage] + theme-aware shimmer placeholders)
/// 2. Low-memory devices (bounded [memCacheWidth] & [memCacheHeight] to prevent OOM and eliminate scroll jank)
/// 3. Automatic URL resolution through [ApiClient.getImageUrl]
class AppCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String? heroTag;
  final Duration fadeInDuration;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.errorWidget,
    this.heroTag,
    this.fadeInDuration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    final rawUrl = imageUrl?.trim() ?? '';
    final resolvedUrl = rawUrl.isNotEmpty ? ApiClient.getImageUrl(rawUrl) : '';

    // Calculate sensible bounded memory cache size if not explicitly provided
    final calculatedMemCacheWidth = memCacheWidth ??
        (width != null && width!.isFinite ? (width! * 2.5).round().clamp(100, 1200) : 600);

    Widget fallbackError = errorWidget ??
        Container(
          width: width,
          height: height,
          color: context.colors.background,
          alignment: Alignment.center,
          child: Icon(
            Icons.image_not_supported_outlined,
            size: (width != null && width! < 60) ? 20 : 32,
            color: context.colors.textHint,
          ),
        );

    Widget imageContent;

    if (resolvedUrl.isEmpty) {
      imageContent = fallbackError;
    } else {
      imageContent = CachedNetworkImage(
        imageUrl: resolvedUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: calculatedMemCacheWidth,
        memCacheHeight: memCacheHeight,
        fadeInDuration: fadeInDuration,
        placeholder: (_, __) =>
            placeholder ??
            Shimmer.fromColors(
              baseColor: context.colors.shimmerBase,
              highlightColor: context.colors.shimmerHighlight,
              child: Container(
                width: width,
                height: height,
                color: context.colors.surface,
              ),
            ),
        errorWidget: (_, __, ___) => fallbackError,
      );
    }

    if (borderRadius != null) {
      imageContent = ClipRRect(
        borderRadius: borderRadius!,
        child: imageContent,
      );
    }

    if (heroTag != null && heroTag!.isNotEmpty) {
      imageContent = Hero(tag: heroTag!, child: imageContent);
    }

    return imageContent;
  }
}

/// A circular avatar that caches images to disk, uses bounded memory decode,
/// and displays a smooth shimmer placeholder during slow network retrieval.
class AppCachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final IconData fallbackIcon;
  final Color? iconColor;
  final double? iconSize;
  final String? heroTag;
  final BoxBorder? border;

  const AppCachedAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 28,
    this.backgroundColor,
    this.fallbackIcon = Icons.storefront_rounded,
    this.iconColor,
    this.iconSize,
    this.heroTag,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final rawUrl = imageUrl?.trim() ?? '';
    final resolvedUrl = rawUrl.isNotEmpty ? ApiClient.getImageUrl(rawUrl) : '';
    final diameter = radius * 2;
    final memSize = (diameter * 2.5).round().clamp(60, 400);

    Widget fallbackWidget = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: backgroundColor ?? context.colors.background,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Icon(
        fallbackIcon,
        size: iconSize ?? (radius * 1.05),
        color: iconColor ?? context.colors.textHint,
      ),
    );

    Widget avatarContent;

    if (resolvedUrl.isEmpty) {
      avatarContent = fallbackWidget;
    } else {
      avatarContent = CachedNetworkImage(
        imageUrl: resolvedUrl,
        imageBuilder: (context, imageProvider) => Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: border,
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        memCacheWidth: memSize,
        memCacheHeight: memSize,
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: context.colors.shimmerBase,
          highlightColor: context.colors.shimmerHighlight,
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              color: context.colors.surface,
              shape: BoxShape.circle,
              border: border,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => fallbackWidget,
      );
    }

    if (heroTag != null && heroTag!.isNotEmpty) {
      avatarContent = Hero(tag: heroTag!, child: avatarContent);
    }

    return avatarContent;
  }
}
