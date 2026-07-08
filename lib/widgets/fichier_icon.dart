import 'package:flutter/material.dart';

const _extensionsImage = {
  'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'heic', 'heif', 'tiff', 'tif',
};

/// Icône représentant un fichier joint selon son extension (PDF, tout type
/// d'image, ou générique).
IconData fichierIcon(String extension) {
  final ext = extension.toLowerCase();
  if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
  if (_extensionsImage.contains(ext)) return Icons.image_outlined;
  return Icons.insert_drive_file_outlined;
}
