import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class ReportPhotoViewer extends StatelessWidget {
  const ReportPhotoViewer({
    super.key,
    required this.imageUrl,
    required this.height,
  });

  final String imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildImageError(),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: IconButton.filled(
              tooltip: 'Perbesar foto',
              onPressed: () => _openFullScreen(context),
              icon: const Icon(Icons.zoom_out_map_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFullScreen(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => _buildImageError(),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: SafeArea(
                child: IconButton.filled(
                  tooltip: 'Tutup foto',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return const ColoredBox(
      color: AppColors.primarySoft,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.primary,
          size: 48,
        ),
      ),
    );
  }
}
