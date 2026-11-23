import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/product.dart';

class ProductImageWidget extends StatelessWidget {
  final Product product;
  final double size;
  final double borderRadius;

  const ProductImageWidget({
    super.key,
    required this.product,
    this.size = 64,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.borderBlack, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImageContent(),
    );
  }

  Widget _buildImageContent() {
    final image = product.imageUrl;
    if (image != null && image.trim().isNotEmpty) {
      final trimmed = image.trim();
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return Image.network(
          trimmed,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _buildFallback(),
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: size * 0.35,
                height: size * 0.35,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        );
      } else if (trimmed.startsWith('data:image')) {
        try {
          final base64String = trimmed.split(',').last;
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (_, __, ___) => _buildFallback(),
          );
        } catch (_) {
          return _buildFallback();
        }
      } else if (trimmed.startsWith('assets/')) {
        return Image.asset(
          trimmed,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _buildFallback(),
        );
      } else {
        try {
          final bytes = base64Decode(trimmed);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (_, __, ___) => _buildFallback(),
          );
        } catch (_) {
          return _buildFallback();
        }
      }
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return Center(
      child: Icon(
        Icons.fastfood_outlined,
        size: size * 0.45,
        color: AppTheme.textMuted,
      ),
    );
  }
}
