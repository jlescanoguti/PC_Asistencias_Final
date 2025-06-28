import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../models/alumno.dart';
import '../../models/asistencia.dart';
import '../../providers/alumnos_provider.dart';
import '../../providers/asistencias_provider.dart';
import '../../providers/sesiones_provider.dart';

class AsistenciasAlumnoScreen extends StatefulWidget {
  const AsistenciasAlumnoScreen({super.key});

  @override
  State<AsistenciasAlumnoScreen> createState() => _AsistenciasAlumnoScreenState();
}

class _AsistenciasAlumnoScreenState extends State<AsistenciasAlumnoScreen> {
  Alumno? _selectedAlumno;
  List<Asistencia> _asistencias = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _cargarAsistencias(Alumno alumno) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _asistencias = [];
    });
    try {
      final asistenciasProvider = context.read<AsistenciasProvider>();
      final sesionesProvider = context.read<SesionesProvider>();
      final sesiones = sesionesProvider.sesiones;
      final asistencias = await asistenciasProvider.listarAsistenciasAlumno(alumno.id!);
      // Mapear asistencias por sesionId
      final asistenciasPorSesion = {for (var a in asistencias) a.sesionId: a};
      // Generar lista completa de asistencias para todas las sesiones
      List<Asistencia> asistenciasCompletas = sesiones.map((sesion) {
        if (asistenciasPorSesion.containsKey(sesion.id)) {
          return asistenciasPorSesion[sesion.id]!;
        } else {
          return Asistencia(
            id: null,
            sesionId: sesion.id!,
            alumnoId: alumno.id!,
            estado: 'Sin asistencia',
            nombreAlumno: alumno.nombre,
            apellidoAlumno: alumno.apellido,
            codigoAlumno: alumno.codigo,
            correoAlumno: alumno.correo,
            nombreSesion: sesion.nombre,
            fechaSesion: sesion.fecha,
            sesionFinalizada: sesion.finalizada,
          );
        }
      }).toList();
      setState(() {
        _asistencias = asistenciasCompletas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar asistencias: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final alumnos = context.watch<AlumnosProvider>().alumnos;
    final asistenciasProvider = context.watch<AsistenciasProvider>();
    final estadisticas = asistenciasProvider.getEstadisticasAlumno(_asistencias);
    final porcentaje = asistenciasProvider.getPorcentajeAsistencia(_asistencias);

    return Scaffold(
      backgroundColor: Color(AppConstants.backgroundColor),
      appBar: AppBar(
        title: const Text('Asistencias por Alumno'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de alumno
            DropdownButtonFormField<Alumno>(
              value: _selectedAlumno,
              decoration: const InputDecoration(
                labelText: 'Selecciona un alumno',
                prefixIcon: Icon(Icons.person),
              ),
              items: alumnos.map((alumno) {
                return DropdownMenuItem(
                  value: alumno,
                  child: Text(alumno.nombreCompleto),
                );
              }).toList(),
              onChanged: (Alumno? value) async {
                setState(() {
                  _selectedAlumno = value;
                  _isLoading = true;
                  _error = null;
                });
                if (value != null) {
                  try {
                    await _cargarAsistencias(value);
                  } catch (e) {
                    setState(() {
                      _error = 'Error al cargar asistencias: $e';
                    });
                  }
                } else {
                  setState(() {
                    _asistencias = [];
                  });
                }
                setState(() {
                  _isLoading = false;
                });
              },
            ),
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            if (_selectedAlumno != null) ...[
              if (_error != null) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_error!, style: GoogleFonts.poppins(color: Color(AppConstants.errorColor))),
                ),
              ] else ...[
                // Estadísticas
                Card(
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingLarge),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat('Total', estadisticas['total'] ?? 0, Colors.blueGrey),
                        _buildStat('Asistió', estadisticas['asistieron'] ?? 0, Color(AppConstants.successColor)),
                        _buildStat('Faltó', estadisticas['faltaron'] ?? 0, Color(AppConstants.errorColor)),
                        Column(
                          children: [
                            Text('${porcentaje.toStringAsFixed(1)}%', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Color(AppConstants.primaryColor))),
                            Text('Asistencia', style: GoogleFonts.poppins(fontSize: 12, color: Color(AppConstants.primaryColor))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Lista de asistencias
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _asistencias.isEmpty
                          ? Center(
                              child: Text('No hay sesiones registradas', style: GoogleFonts.poppins(color: Color(AppConstants.textSecondaryColor))),
                            )
                          : ListView.builder(
                              itemCount: _asistencias.length,
                              itemBuilder: (context, index) {
                                final asistencia = _asistencias[index];
                                return _buildAsistenciaCard(asistencia);
                              },
                            ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int value, Color color) {
    return Column(
      children: [
        Text('$value', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildAsistenciaCard(Asistencia asistencia) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
        leading: CircleAvatar(
          backgroundColor: asistencia.asistio ? Color(AppConstants.successColor).withOpacity(0.1) : Color(AppConstants.errorColor).withOpacity(0.1),
          child: Icon(
            asistencia.asistio ? Icons.check_circle : Icons.cancel,
            color: asistencia.asistio ? Color(AppConstants.successColor) : Color(AppConstants.errorColor),
          ),
        ),
        title: Text(
          asistencia.nombreSesion ?? '-',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(asistencia.fechaFormateada, style: GoogleFonts.poppins(color: Color(AppConstants.textSecondaryColor))),
        trailing: Text(
          asistencia.estadoFormateado,
          style: GoogleFonts.poppins(
            color: asistencia.asistio ? Color(AppConstants.successColor) : Color(AppConstants.errorColor),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 