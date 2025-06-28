import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_constants.dart';
import '../../models/sesion.dart';
import '../../providers/sesiones_provider.dart';
import '../../providers/asistencias_provider.dart';
import '../../widgets/image_picker_widget.dart';

class PasarAsistenciaScreen extends StatefulWidget {
  const PasarAsistenciaScreen({super.key});

  @override
  State<PasarAsistenciaScreen> createState() => _PasarAsistenciaScreenState();
}

class _PasarAsistenciaScreenState extends State<PasarAsistenciaScreen> {
  Sesion? _selectedSesion;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppConstants.backgroundColor),
      appBar: AppBar(
        title: const Text('Pasar Asistencia'),
      ),
      body: Consumer2<SesionesProvider, AsistenciasProvider>(
        builder: (context, sesionesProvider, asistenciasProvider, child) {
          final sesionesActivas = sesionesProvider.sesionesActivas;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Selector de sesión
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                    border: Border.all(
                      color: Color(AppConstants.textLightColor).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar Sesión',
                        style: GoogleFonts.poppins(
                          fontSize: AppConstants.fontSizeLarge,
                          fontWeight: FontWeight.w600,
                          color: Color(AppConstants.textPrimaryColor),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Elige la sesión donde pasarás asistencia',
                        style: GoogleFonts.poppins(
                          fontSize: AppConstants.fontSizeSmall,
                          color: Color(AppConstants.textSecondaryColor),
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.paddingLarge),
                      
                      if (sesionesActivas.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(AppConstants.paddingMedium),
                          decoration: BoxDecoration(
                            color: Color(AppConstants.warningColor).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                            border: Border.all(
                              color: Color(AppConstants.warningColor).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Color(AppConstants.warningColor),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No hay sesiones activas disponibles',
                                  style: GoogleFonts.poppins(
                                    color: Color(AppConstants.warningColor),
                                    fontSize: AppConstants.fontSizeSmall,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<Sesion>(
                          value: _selectedSesion,
                          decoration: const InputDecoration(
                            labelText: 'Sesión',
                            prefixIcon: Icon(Icons.class_),
                          ),
                          items: sesionesActivas.map((sesion) {
                            return DropdownMenuItem(
                              value: sesion,
                              child: Text(sesion.nombre),
                            );
                          }).toList(),
                          onChanged: (Sesion? value) {
                            setState(() {
                              _selectedSesion = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Por favor selecciona una sesión';
                            }
                            return null;
                          },
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Selector de imagen (solo si hay sesión seleccionada)
                if (_selectedSesion != null) ...[
                  ImagePickerWidget(
                    selectedImage: _selectedImage,
                    onImagePicked: _pickImage,
                    title: 'Foto del Alumno',
                    subtitle: 'Toma una foto clara del rostro para el reconocimiento',
                  ),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Botón para pasar asistencia
                  ElevatedButton(
                    onPressed: _isLoading || asistenciasProvider.isLoading || _selectedImage == null
                        ? null
                        : _pasarAsistencia,
                    child: _isLoading || asistenciasProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Pasar Asistencia'),
                  ),
                  
                  // Mostrar resultado del reconocimiento
                  if (asistenciasProvider.ultimoResultadoAsistencia != null) ...[
                    const SizedBox(height: AppConstants.paddingMedium),
                    _buildResultadoCard(asistenciasProvider.ultimoResultadoAsistencia!),
                  ],
                  
                  // Mostrar error si existe
                  if (asistenciasProvider.error != null) ...[
                    const SizedBox(height: AppConstants.paddingMedium),
                    Container(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      decoration: BoxDecoration(
                        color: Color(AppConstants.errorColor).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        border: Border.all(
                          color: Color(AppConstants.errorColor).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Color(AppConstants.errorColor),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              asistenciasProvider.error!,
                              style: GoogleFonts.poppins(
                                color: Color(AppConstants.errorColor),
                                fontSize: AppConstants.fontSizeSmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: Color(AppConstants.errorColor),
        ),
      );
    }
  }

  Future<void> _pasarAsistencia() async {
    if (_selectedSesion == null || _selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<AsistenciasProvider>();
      final success = await provider.pasarAsistencia(
        sesionId: _selectedSesion!.id!,
        foto: _selectedImage!,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Asistencia registrada correctamente'),
            backgroundColor: Color(AppConstants.successColor),
          ),
        );
        // Limpiar imagen seleccionada para siguiente uso
        setState(() {
          _selectedImage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Color(AppConstants.errorColor),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildResultadoCard(Map<String, dynamic> resultado) {
    final success = resultado['success'] == true;
    final alumno = resultado['alumno'];
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: success 
            ? Color(AppConstants.successColor).withOpacity(0.1)
            : Color(AppConstants.errorColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: success 
              ? Color(AppConstants.successColor).withOpacity(0.3)
              : Color(AppConstants.errorColor).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error_outline,
            color: success 
                ? Color(AppConstants.successColor)
                : Color(AppConstants.errorColor),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resultado['message'] ?? 'Resultado del reconocimiento',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: success 
                        ? Color(AppConstants.successColor)
                        : Color(AppConstants.errorColor),
                  ),
                ),
                if (success && alumno != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Alumno: ${alumno['nombre']} (${alumno['codigo']})',
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.fontSizeSmall,
                      color: Color(AppConstants.textSecondaryColor),
                    ),
                  ),
                  Text(
                    'Similitud: ${(alumno['similitud'] * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.fontSizeSmall,
                      color: Color(AppConstants.textSecondaryColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
} 