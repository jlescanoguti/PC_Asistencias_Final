import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_constants.dart';
import '../../providers/alumnos_provider.dart';
import '../../widgets/image_picker_widget.dart';

class RegistrarAlumnoScreen extends StatefulWidget {
  const RegistrarAlumnoScreen({super.key});

  @override
  State<RegistrarAlumnoScreen> createState() => _RegistrarAlumnoScreenState();
}

class _RegistrarAlumnoScreenState extends State<RegistrarAlumnoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _codigoController = TextEditingController();
  final _correoController = TextEditingController();
  
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _codigoController.dispose();
    _correoController.dispose();
    super.dispose();
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor selecciona una foto del alumno'),
          backgroundColor: Color(AppConstants.errorColor),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<AlumnosProvider>();
      final success = await provider.registrarAlumno(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        codigo: _codigoController.text.trim(),
        correo: _correoController.text.trim(),
        foto: _selectedImage!,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Alumno registrado correctamente'),
            backgroundColor: Color(AppConstants.successColor),
          ),
        );
        Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppConstants.backgroundColor),
      appBar: AppBar(
        title: const Text('Registrar Alumno'),
      ),
      body: Consumer<AlumnosProvider>(
        builder: (context, provider, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Selector de imagen
                  ImagePickerWidget(
                    selectedImage: _selectedImage,
                    onImagePicked: _pickImage,
                    title: 'Foto del Alumno',
                    subtitle: 'Selecciona una foto clara del rostro',
                  ),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Formulario
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ingresa el nombre',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppConstants.requiredField;
                      }
                      if (value.trim().length < 2) {
                        return AppConstants.invalidName;
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  TextFormField(
                    controller: _apellidoController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido',
                      hintText: 'Ingresa el apellido',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppConstants.requiredField;
                      }
                      if (value.trim().length < 2) {
                        return AppConstants.invalidName;
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  TextFormField(
                    controller: _codigoController,
                    decoration: const InputDecoration(
                      labelText: 'Código',
                      hintText: 'Ingresa el código del alumno',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppConstants.requiredField;
                      }
                      if (value.trim().length < 3) {
                        return AppConstants.invalidCode;
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  TextFormField(
                    controller: _correoController,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      hintText: 'ejemplo@correo.com',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppConstants.requiredField;
                      }
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return AppConstants.invalidEmail;
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Botón de registro
                  ElevatedButton(
                    onPressed: _isLoading || provider.isLoading ? null : _submitForm,
                    child: _isLoading || provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Registrar Alumno'),
                  ),
                  
                  // Mostrar error si existe
                  if (provider.error != null) ...[
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
                              provider.error!,
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
              ),
            ),
          );
        },
      ),
    );
  }
} 