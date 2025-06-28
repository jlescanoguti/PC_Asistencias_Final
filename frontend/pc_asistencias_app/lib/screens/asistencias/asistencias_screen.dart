import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../providers/sesiones_provider.dart';
import '../../providers/alumnos_provider.dart';
import 'pasar_asistencia_screen.dart';
import 'asistencias_alumno_screen.dart';

class AsistenciasScreen extends StatefulWidget {
  const AsistenciasScreen({super.key});

  @override
  State<AsistenciasScreen> createState() => _AsistenciasScreenState();
}

class _AsistenciasScreenState extends State<AsistenciasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SesionesProvider>().cargarSesiones();
      context.read<AlumnosProvider>().cargarAlumnos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppConstants.backgroundColor),
      appBar: AppBar(
        title: const Text('Gestión de Asistencias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SesionesProvider>().cargarSesiones();
              context.read<AlumnosProvider>().cargarAlumnos();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Datos actualizados'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Control de Asistencias',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(AppConstants.textPrimaryColor),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Pasa asistencia y consulta historiales',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Color(AppConstants.textSecondaryColor),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Opciones principales
            Expanded(
              child: Column(
                children: [
                  // Pasar Asistencia
                  _buildOptionCard(
                    title: 'Pasar Asistencia',
                    subtitle: 'Registra asistencia con reconocimiento facial',
                    icon: Icons.camera_alt,
                    color: Color(AppConstants.primaryColor),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PasarAsistenciaScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Consultar Asistencias por Alumno
                  _buildOptionCard(
                    title: 'Consultar Asistencias',
                    subtitle: 'Ver historial de asistencias por alumno',
                    icon: Icons.history,
                    color: Color(AppConstants.secondaryColor),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AsistenciasAlumnoScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Información adicional
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(AppConstants.primaryColor),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Información',
                              style: GoogleFonts.poppins(
                                fontSize: AppConstants.fontSizeLarge,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        _buildInfoRow('• Solo se puede pasar asistencia en sesiones activas'),
                        _buildInfoRow('• Se requiere una foto clara del rostro'),
                        _buildInfoRow('• El sistema usa reconocimiento facial automático'),
                        _buildInfoRow('• Los reportes PDF están disponibles en detalles de sesión'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: color,
                ),
              ),
              
              const SizedBox(width: AppConstants.paddingLarge),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    ),
                  ],
                ),
              ),
              
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: AppConstants.fontSizeSmall,
          color: Color(AppConstants.textSecondaryColor),
        ),
      ),
    );
  }
} 