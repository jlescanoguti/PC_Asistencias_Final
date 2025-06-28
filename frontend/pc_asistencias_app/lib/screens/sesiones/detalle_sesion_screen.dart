import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../models/sesion.dart';
import '../../models/asistencia.dart';
import '../../providers/sesiones_provider.dart';
import '../../providers/asistencias_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DetalleSesionScreen extends StatefulWidget {
  final Sesion sesion;
  const DetalleSesionScreen({super.key, required this.sesion});

  @override
  State<DetalleSesionScreen> createState() => _DetalleSesionScreenState();
}

class _DetalleSesionScreenState extends State<DetalleSesionScreen> {
  bool _isLoadingPDF = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SesionesProvider>().cargarDetallesSesion(widget.sesion.id!);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final sesionesProvider = context.watch<SesionesProvider>();
    final asistencias = sesionesProvider.getAsistenciasSesion(widget.sesion.id!);
    final estadisticas = sesionesProvider.getEstadisticasSesion(widget.sesion.id!);
    return Scaffold(
      backgroundColor: Color(AppConstants.backgroundColor),
      appBar: AppBar(
        title: Text('Detalle: ${widget.sesion.nombre}'),
        actions: [
          if (widget.sesion.finalizada)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Descargar reporte PDF',
              onPressed: _isLoadingPDF ? null : () => _generarReportePDF(context),
            ),
        ],
      ),
      body: sesionesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fecha:', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                          Text(widget.sesion.fechaFormateada, style: GoogleFonts.poppins()),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Estado:', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                          Text(widget.sesion.estado, style: GoogleFonts.poppins(color: widget.sesion.finalizada ? Color(AppConstants.errorColor) : Color(AppConstants.successColor))),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat('Total', estadisticas['total'] ?? 0, Colors.blueGrey),
                      _buildStat('Asistieron', estadisticas['asistieron'] ?? 0, Color(AppConstants.successColor)),
                      _buildStat('Faltaron', estadisticas['faltaron'] ?? 0, Color(AppConstants.errorColor)),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Expanded(
                  child: asistencias.isEmpty
                      ? Center(
                          child: Text('No hay alumnos registrados en esta sesión', style: GoogleFonts.poppins(color: Color(AppConstants.textSecondaryColor))),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
                          itemCount: asistencias.length,
                          itemBuilder: (context, index) {
                            final asistencia = asistencias[index];
                            return _buildAsistenciaCard(asistencia);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStat(String label, int value, Color color) {
    return Column(
      children: [
        Text('$value', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
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
          asistencia.nombreCompletoAlumno,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Código: ${asistencia.codigoAlumno ?? '-'}', style: GoogleFonts.poppins(color: Color(AppConstants.textSecondaryColor))),
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

  Future<void> _generarReportePDF(BuildContext context) async {
    setState(() { _isLoadingPDF = true; });
    try {
      final pdfBytes = await context.read<AsistenciasProvider>().generarReportePDF(widget.sesion.id!);
      if (pdfBytes != null) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/reporte_sesion_${widget.sesion.id}.pdf');
        await file.writeAsBytes(pdfBytes);
        await OpenFile.open(file.path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('No se pudo generar el PDF'), backgroundColor: Color(AppConstants.errorColor)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar PDF: $e'), backgroundColor: Color(AppConstants.errorColor)),
      );
    } finally {
      setState(() { _isLoadingPDF = false; });
    }
  }
} 