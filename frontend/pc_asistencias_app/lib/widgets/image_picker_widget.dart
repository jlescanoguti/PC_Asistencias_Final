import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

class ImagePickerWidget extends StatelessWidget {
  final File? selectedImage;
  final Function(ImageSource) onImagePicked;
  final String title;
  final String subtitle;

  const ImagePickerWidget({
    super.key,
    this.selectedImage,
    required this.onImagePicked,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(
          color: Color(AppConstants.textLightColor).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Título y subtítulo
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.fontSizeLarge,
              fontWeight: FontWeight.w600,
              color: Color(AppConstants.textPrimaryColor),
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.fontSizeSmall,
              color: Color(AppConstants.textSecondaryColor),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: AppConstants.paddingLarge),
          
          // Imagen seleccionada o placeholder
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
              border: Border.all(
                color: Color(AppConstants.textLightColor).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                    child: Image.file(
                      selectedImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholder();
                      },
                    ),
                  )
                : _buildPlaceholder(),
          ),
          
          const SizedBox(height: AppConstants.paddingLarge),
          
          // Botones de selección
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onImagePicked(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Cámara'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(AppConstants.primaryColor),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(width: AppConstants.paddingMedium),
              
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onImagePicked(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galería'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(AppConstants.secondaryColor),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          // Información adicional
          if (selectedImage != null) ...[
            const SizedBox(height: AppConstants.paddingMedium),
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: Color(AppConstants.successColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                border: Border.all(
                  color: Color(AppConstants.successColor).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Color(AppConstants.successColor),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Imagen seleccionada correctamente',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeSmall,
                        color: Color(AppConstants.successColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Color(AppConstants.backgroundColor),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 48,
            color: Color(AppConstants.textLightColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Seleccionar imagen',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.fontSizeMedium,
              color: Color(AppConstants.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }
} 