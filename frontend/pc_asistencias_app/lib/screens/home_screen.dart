import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../providers/sesiones_provider.dart';
import '../widgets/menu_card.dart';
import 'alumnos/alumnos_screen.dart';
import 'sesiones/sesiones_screen.dart';
import 'asistencias/asistencias_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar sesiones al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SesionesProvider>().cargarSesiones();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppConstants.backgroundColor),
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SesionesProvider>().cargarSesiones();
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de bienvenida
              Text(
                'Bienvenido',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.textPrimaryColor),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Sistema de Control de Asistencias',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Color(AppConstants.textSecondaryColor),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Menú principal
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    return GridView.count(
                      crossAxisCount: isWide ? 3 : 2,
                      crossAxisSpacing: AppConstants.paddingLarge,
                      mainAxisSpacing: AppConstants.paddingLarge,
                      childAspectRatio: isWide ? 1.1 : 0.85,
                      children: [
                        // Gestión de Alumnos
                        MenuCard(
                          title: 'Gestión de\nAlumnos',
                          subtitle: 'Registrar, editar y eliminar alumnos',
                          icon: Icons.people,
                          color: Color(AppConstants.primaryColor),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AlumnosScreen(),
                              ),
                            );
                          },
                        ),
                        
                        // Gestión de Sesiones
                        MenuCard(
                          title: 'Gestión de\nSesiones',
                          subtitle: 'Crear y gestionar sesiones de clase',
                          icon: Icons.class_,
                          color: Color(AppConstants.secondaryColor),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SesionesScreen(),
                              ),
                            );
                          },
                        ),
                        
                        // Gestión de Asistencias
                        MenuCard(
                          title: 'Gestión de\nAsistencias',
                          subtitle: 'Pasar asistencia y generar reportes',
                          icon: Icons.assignment_turned_in,
                          color: Color(AppConstants.accentColor),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AsistenciasScreen(),
                              ),
                            );
                          },
                        ),
                        
                        // Información del sistema
                        MenuCard(
                          title: 'Información\ndel Sistema',
                          subtitle: 'Estado y estadísticas',
                          icon: Icons.info,
                          color: Color(AppConstants.warningColor),
                          onTap: () {
                            _showSystemInfo();
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              // Footer con información
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_done,
                      color: Color(AppConstants.successColor),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Conectado al servidor',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Color(AppConstants.textSecondaryColor),
                        ),
                      ),
                    ),
                    Text(
                      'v${AppConstants.appVersion}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Color(AppConstants.textLightColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSystemInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Información del Sistema',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Aplicación', AppConstants.appName),
            _buildInfoRow('Versión', AppConstants.appVersion),
            _buildInfoRow('Descripción', AppConstants.appDescription),
            const SizedBox(height: 16),
            _buildInfoRow('Servidor', 'Railway'),
            _buildInfoRow('Base de Datos', 'MySQL'),
            _buildInfoRow('Reconocimiento', 'InsightFace'),
            _buildInfoRow('Almacenamiento', 'Cloudinary'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(AppConstants.textPrimaryColor),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Color(AppConstants.textSecondaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 