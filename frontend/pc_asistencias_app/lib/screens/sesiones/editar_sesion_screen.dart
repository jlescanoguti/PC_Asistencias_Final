import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../models/sesion.dart';
import '../../providers/sesiones_provider.dart';

class EditarSesionScreen extends StatefulWidget {
  final Sesion sesion;
  const EditarSesionScreen({super.key, required this.sesion});

  @override
  State<EditarSesionScreen> createState() => _EditarSesionScreenState();
}

class _EditarSesionScreenState extends State<EditarSesionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.sesion.nombre);
    _nombreController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {
      _hasChanges = _nombreController.text != widget.sesion.nombre;
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      final provider = context.read<SesionesProvider>();
      final success = await provider.editarSesion(widget.sesion.id!, _nombreController.text.trim());
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sesión actualizada correctamente'),
            backgroundColor: Color(AppConstants.successColor),
          ),
        );
        Navigator.of(context).pop();
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
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppConstants.backgroundColor),
      appBar: AppBar(
        title: Text('Editar Sesión'),
        actions: [
          if (_hasChanges && !widget.sesion.finalizada)
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
      body: Consumer<SesionesProvider>(
        builder: (context, provider, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.sesion.finalizada) ...[
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
                          Icon(Icons.warning, color: Color(AppConstants.warningColor), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No se puede editar una sesión finalizada',
                              style: GoogleFonts.poppins(
                                color: Color(AppConstants.warningColor),
                                fontSize: AppConstants.fontSizeSmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                  ],
                  TextFormField(
                    controller: _nombreController,
                    enabled: !widget.sesion.finalizada,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la sesión',
                      hintText: 'Ejemplo: Clase 01 - 2024',
                      prefixIcon: Icon(Icons.class_),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppConstants.requiredField;
                      }
                      if (value.trim().length < 3) {
                        return 'El nombre debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  if (!widget.sesion.finalizada)
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
                          : const Text('Actualizar Sesión'),
                    ),
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
                          Icon(Icons.error_outline, color: Color(AppConstants.errorColor), size: 20),
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