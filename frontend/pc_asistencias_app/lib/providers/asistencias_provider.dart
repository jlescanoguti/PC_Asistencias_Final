import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/asistencia.dart';
import '../services/api_service.dart';
import '../utils/api_utils.dart';

class AsistenciasProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _ultimoResultadoAsistencia;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get ultimoResultadoAsistencia => _ultimoResultadoAsistencia;

  // Métodos
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearUltimoResultado() {
    _ultimoResultadoAsistencia = null;
    notifyListeners();
  }

  // Pasar asistencia
  Future<bool> pasarAsistencia({
    required int sesionId,
    required File foto,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      clearUltimoResultado();

      final result = await _apiService.pasarAsistencia(
        sesionId: sesionId,
        foto: foto,
      );

      _ultimoResultadoAsistencia = result;

      if (isSuccess(result['success'])) {
        return true;
      } else {
        _setError(result['message'] ?? 'Error al pasar asistencia');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Generar reporte PDF
  Future<Uint8List?> generarReportePDF(int sesionId) async {
    try {
      _setLoading(true);
      _setError(null);

      final pdfBytes = await _apiService.generarReportePDF(sesionId);
      return pdfBytes;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Listar asistencias de un alumno
  Future<List<Asistencia>> listarAsistenciasAlumno(int alumnoId) async {
    try {
      _setLoading(true);
      _setError(null);

      final asistencias = await _apiService.listarAsistenciasAlumno(alumnoId);
      return asistencias;
    } catch (e) {
      _setError(e.toString());
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Obtener estadísticas de asistencias de un alumno
  Map<String, int> getEstadisticasAlumno(List<Asistencia> asistencias) {
    int asistieron = 0;
    int faltaron = 0;
    int total = asistencias.length;

    for (var asistencia in asistencias) {
      if (asistencia.asistio) {
        asistieron++;
      } else {
        faltaron++;
      }
    }

    return {
      'asistieron': asistieron,
      'faltaron': faltaron,
      'total': total,
    };
  }

  // Calcular porcentaje de asistencia
  double getPorcentajeAsistencia(List<Asistencia> asistencias) {
    if (asistencias.isEmpty) return 0.0;
    
    final estadisticas = getEstadisticasAlumno(asistencias);
    final total = estadisticas['total']!;
    final asistieron = estadisticas['asistieron']!;
    
    return total > 0 ? (asistieron / total) * 100 : 0.0;
  }

  // Obtener asistencias por mes
  Map<String, List<Asistencia>> getAsistenciasPorMes(List<Asistencia> asistencias) {
    Map<String, List<Asistencia>> asistenciasPorMes = {};
    
    for (var asistencia in asistencias) {
      if (asistencia.fechaSesion != null) {
        final mes = '${asistencia.fechaSesion!.year}-${asistencia.fechaSesion!.month.toString().padLeft(2, '0')}';
        
        if (!asistenciasPorMes.containsKey(mes)) {
          asistenciasPorMes[mes] = [];
        }
        asistenciasPorMes[mes]!.add(asistencia);
      }
    }
    
    return asistenciasPorMes;
  }

  // Obtener asistencias recientes
  List<Asistencia> getAsistenciasRecientes(List<Asistencia> asistencias, {int limit = 5}) {
    final asistenciasConFecha = asistencias.where((a) => a.fechaSesion != null).toList();
    asistenciasConFecha.sort((a, b) => b.fechaSesion!.compareTo(a.fechaSesion!));
    
    return asistenciasConFecha.take(limit).toList();
  }

  // Verificar si un alumno asistió a una sesión específica
  bool asistioASesion(List<Asistencia> asistencias, int sesionId) {
    try {
      final asistencia = asistencias.firstWhere((a) => a.sesionId == sesionId);
      return asistencia.asistio;
    } catch (e) {
      return false;
    }
  }

  // Obtener racha de asistencias
  int getRachaAsistencias(List<Asistencia> asistencias) {
    final asistenciasOrdenadas = asistencias
        .where((a) => a.fechaSesion != null)
        .toList()
      ..sort((a, b) => b.fechaSesion!.compareTo(a.fechaSesion!));

    int racha = 0;
    for (var asistencia in asistenciasOrdenadas) {
      if (asistencia.asistio) {
        racha++;
      } else {
        break;
      }
    }
    
    return racha;
  }

  // Obtener racha de faltas
  int getRachaFaltas(List<Asistencia> asistencias) {
    final asistenciasOrdenadas = asistencias
        .where((a) => a.fechaSesion != null)
        .toList()
      ..sort((a, b) => b.fechaSesion!.compareTo(a.fechaSesion!));

    int racha = 0;
    for (var asistencia in asistenciasOrdenadas) {
      if (!asistencia.asistio) {
        racha++;
      } else {
        break;
      }
    }
    
    return racha;
  }
} 