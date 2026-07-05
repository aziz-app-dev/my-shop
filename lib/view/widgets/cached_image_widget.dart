import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../view_models/services/image_cache/image_cache_service.dart';

/// A widget that displays images with caching and offline fallback
/// Supports both network URLs and local file paths
class AppCachedImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final String? folder; // For organizing cached images

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.folder,
  });

  @override
  State<AppCachedImage> createState() => _AppCachedImageState();
}

class _AppCachedImageState extends State<AppCachedImage> {
  String? _localCachePath;
  bool _networkFailed = false;
  final _cacheService = ImageCacheService.instance;

  @override
  void initState() {
    super.initState();
    _checkLocalCache();
  }

  @override
  void didUpdateWidget(AppCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _localCachePath = null;
      _networkFailed = false;
      _checkLocalCache();
    }
  }

  Future<void> _checkLocalCache() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) return;

    // If it's already a local path, no need to cache
    if (!widget.imageUrl!.startsWith('http')) return;

    // Check if we have a local cached version
    final cachedPath = await _cacheService.getCachedImagePath(widget.imageUrl!);
    if (cachedPath != null && mounted) {
      setState(() {
        _localCachePath = cachedPath;
      });
    }
  }

  Future<void> _cacheImageOnLoad() async {
    if (widget.imageUrl == null || !widget.imageUrl!.startsWith('http')) return;

    // Download and cache the image for offline use
    await _cacheService.downloadAndCacheImage(
      widget.imageUrl!,
      folder: widget.folder,
    );
  }

  Widget _buildPlaceholder() {
    return widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[200],
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey[400],
            size: 32,
          ),
        );
  }

  Widget _buildImage(Widget image) {
    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: image,
      );
    }
    return image;
  }

  @override
  Widget build(BuildContext context) {
    // No image URL provided
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    final imageUrl = widget.imageUrl!;

    // Local file path
    if (!imageUrl.startsWith('http')) {
      final file = File(imageUrl);
      if (file.existsSync()) {
        return _buildImage(
          Image.file(
            file,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
          ),
        );
      }
      return _buildErrorWidget();
    }

    // Network failed and we have local cache - show cached version
    if (_networkFailed && _localCachePath != null) {
      final file = File(_localCachePath!);
      if (file.existsSync()) {
        return _buildImage(
          Image.file(
            file,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
          ),
        );
      }
    }

    // Network image with cached_network_image
    return _buildImage(
      CachedNetworkImage(
        imageUrl: imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) {
          // Network failed, try local cache
          if (_localCachePath != null) {
            final file = File(_localCachePath!);
            if (file.existsSync()) {
              return Image.file(
                file,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                errorBuilder: (context, error, stackTrace) =>
                    _buildErrorWidget(),
              );
            }
          }

          // Mark network as failed for future rebuilds
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_networkFailed) {
              setState(() {
                _networkFailed = true;
              });
            }
          });

          return _buildErrorWidget();
        },
        imageBuilder: (context, imageProvider) {
          // Image loaded successfully, cache it for offline use
          _cacheImageOnLoad();
          return Image(
            image: imageProvider,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        },
      ),
    );
  }
}

/// CircleAvatar with cached image support
class CachedCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String? folder;

  const CachedCircleAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.placeholder,
    this.errorWidget,
    this.folder,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: AppCachedImage(
        imageUrl: imageUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: placeholder,
        errorWidget: errorWidget ??
            Container(
              width: radius * 2,
              height: radius * 2,
              color: Colors.grey[300],
              child: Icon(
                Icons.person,
                size: radius,
                color: Colors.grey[600],
              ),
            ),
        folder: folder,
      ),
    );
  }
}

/// Product/Item image with cached support
class CachedProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const CachedProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AppCachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      folder: 'products',
      errorWidget: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.inventory_2_outlined,
          color: Colors.grey[400],
          size: 32,
        ),
      ),
    );
  }
}
