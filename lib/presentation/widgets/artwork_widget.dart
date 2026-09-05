import 'dart:io';
import 'package:flutter/material.dart';

class ArtworkWidget extends StatelessWidget {
  final String? artworkPath;
  final double size;
  final double borderRadius;
  final IconData fallbackIcon;

  const ArtworkWidget({
    super.key,
    required this.artworkPath,
    this.size = 48,
    this.borderRadius = 8,
    this.fallbackIcon = Icons.music_note_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPath = artworkPath != null && artworkPath!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: theme.colorScheme.surfaceContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPath
          ? Image.file(
              File(artworkPath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildFallback(context),
            )
          : _buildFallback(context),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.secondary.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          size: size * 0.45,
          color: theme.colorScheme.primary.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
