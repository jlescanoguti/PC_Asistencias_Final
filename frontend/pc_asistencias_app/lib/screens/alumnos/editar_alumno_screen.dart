import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_constants.dart';
import '../../providers/alumnos_provider.dart';
import '../../models/alumno.dart';
import '../../widgets/image_picker_widget.dart';

class EditarAlumnoScreen extends StatefulWidget {
  final Alumno alumno;

  const EditarAlumnoScreen({
    super.key,
    required this.alumno,
  });

  @override
  State<EditarAlumnoScreen> createState() => _EditarAlumnoScreenState();
}

class _EditarAlumnoScreenState extends State<EditarAlumnoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _codigoController;
  late final TextEditingController _correoController;
  
  File? _selectedImage;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.alumno.nombre);
    _apellidoController = TextEditingController(text: widget.alumno.apellido);
    _codigoController = TextEditingController(text: widget.alumno.codigo);
    _correoController = TextEditingController(text: widget.alumno.correo);
    
    // Escuchar cambios en los campos
    _nombreController.addListener(_onFieldChanged);
    _apellidoController.addListener(_onFieldChanged);
    _codigoController.addListener(_onFieldChanged);
    _correoController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {
      _hasChanges = _nombreController.text != widget.alumno.nombre ||
                    _apellidoController.text != widget.alumno.apellido ||
                    _codigoController.text != widget.alumno.codigo ||
                    _correoController.text != widget.alumno.correo ||
                    _selectedImage != null;
    });
  }

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
          _hasChanges = true;
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

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<AlumnosProvider>();
      final success = await provider.editarAlumno(
        alumnoId: widget.alumno.id!,
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        codigo: _codigoController.text.trim(),
        correo: _correoController.text.trim(),
        foto: _selectedImage ?? (widget.alumno.foto != null ? File('') : null),
      );

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alumno actualizado correctamente'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
        title: Text('Editar ${widget.alumno.nombreCompleto}'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Guardar',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
        ],
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
                    subtitle: 'Selecciona una nueva foto (opcional)',
                  ),
                  
                  // Mostrar imagen actual si no se ha seleccionado una nueva
                  if (_selectedImage == null && widget.alumno.foto != null) ...[
                    const SizedBox(height: AppConstants.paddingMedium),
                    Container(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        border: Border.all(
                          color: Color(AppConstants.textLightColor).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Foto actual',
                            style: GoogleFonts.poppins(
                              fontSize: AppConstants.fontSizeMedium,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingMedium),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                            child: Image.network(
                              widget.alumno.foto!,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: Color(AppConstants.backgroundColor),
                                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Color(AppConstants.textLightColor),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
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
                  
                  // Botón de actualización
                  ElevatedButton(
                    onPressed: _isLoading || provider.isLoading || !_hasChanges ? null : _submitForm,
                    child: _isLoading || provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Actualizar Alumno'),
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