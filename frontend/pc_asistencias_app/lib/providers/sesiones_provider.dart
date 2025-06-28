import 'package:flutter/material.dart';
import '../models/sesion.dart';
import '../models/asistencia.dart';
import '../models/alumno.dart';
import '../services/api_service.dart';
import '../utils/api_utils.dart';

class SesionesProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Sesion> _sesiones = [];
  Map<int, List<Asistencia>> _asistenciasPorSesion = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Sesion> get sesiones => _sesiones;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  // Cargar sesiones
  Future<void> cargarSesiones() async {
    try {
      _setLoading(true);
      _setError(null);

      final sesiones = await _apiService.listarSesiones();
      _sesiones = sesiones;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Crear sesión
  Future<bool> crearSesion(String nombre) async {
    try {
      _setLoading(true);
      _setError(null);

      final result = await _apiService.crearSesion(nombre);

      if (isSuccess(result['success'])) {
        await cargarSesiones();
        return true;
      } else {
        _setError(result['message'] ?? 'Error al crear sesión');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Editar sesión
  Future<bool> editarSesion(int sesionId, String nombre) async {
    try {
      _setLoading(true);
      _setError(null);

      final result = await _apiService.editarSesion(sesionId, nombre);

      if (isSuccess(result['success'])) {
        await cargarSesiones();
        return true;
      } else {
        _setError(result['message'] ?? 'Error al editar sesión');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Eliminar sesión
  Future<bool> eliminarSesion(int sesionId) async {
    try {
      _setLoading(true);
      _setError(null);

      final result = await _apiService.eliminarSesion(sesionId);

      if (isSuccess(result['success'])) {
        _sesiones.removeWhere((sesion) => sesion.id == sesionId);
        _asistenciasPorSesion.remove(sesionId);
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] ?? 'Error al eliminar sesión');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Finalizar sesión
  Future<bool> finalizarSesion(int sesionId) async {
    try {
      _setLoading(true);
      _setError(null);

      final result = await _apiService.finalizarSesion(sesionId);

      if (isSuccess(result['success'])) {
        await cargarSesiones();
        return true;
      } else {
        _setError(result['message'] ?? 'Error al finalizar sesión');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cargar detalles de sesión
  Future<Map<String, dynamic>?> cargarDetallesSesion(int sesionId) async {
    try {
      _setLoading(true);
      _setError(null);

      final detalles = await _apiService.detallesSesion(sesionId);

      if (isSuccess(detalles['success'])) {
        // Obtener todos los alumnos
        List<Alumno> todosAlumnos = await _apiService.listarAlumnos();
        List<dynamic> asistenciasData = detalles['alumnos'];
        List<Asistencia> asistenciasRegistradas = asistenciasData.map((json) => Asistencia.fromJson(json)).toList();

        // Mapear asistencias por alumnoId
        final asistenciasPorAlumno = {for (var a in asistenciasRegistradas) a.alumnoId: a};

        // Generar lista completa de asistencias para todos los alumnos
        List<Asistencia> asistenciasCompletas = todosAlumnos.map((alumno) {
          if (asistenciasPorAlumno.containsKey(alumno.id)) {
            return asistenciasPorAlumno[alumno.id]!;
          } else {
            return Asistencia(
              id: null,
              sesionId: sesionId,
              alumnoId: alumno.id!,
              estado: 'Faltó',
              nombreAlumno: alumno.nombre,
              apellidoAlumno: alumno.apellido,
              codigoAlumno: alumno.codigo,
              correoAlumno: alumno.correo,
              nombreSesion: detalles['nombre'] ?? '',
              fechaSesion: detalles['fecha'] != null ? DateTime.parse(detalles['fecha']) : null,
              sesionFinalizada: detalles['finalizada'] == true || detalles['finalizada'] == 1,
            );
          }
        }).toList();

        _asistenciasPorSesion[sesionId] = asistenciasCompletas;
        return detalles;
      } else {
        _setError('Error al cargar detalles de sesión');
        return null;
      }
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Obtener asistencias de una sesión
  List<Asistencia> getAsistenciasSesion(int sesionId) {
    return _asistenciasPorSesion[sesionId] ?? [];
  }

  // Buscar sesión por ID
  Sesion? getSesionById(int id) {
    try {
      return _sesiones.firstWhere((sesion) => sesion.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtener sesiones activas
  List<Sesion> get sesionesActivas {
    return _sesiones.where((sesion) => !sesion.finalizada).toList();
  }

  // Obtener sesiones finalizadas
  List<Sesion> get sesionesFinalizadas {
    return _sesiones.where((sesion) => sesion.finalizada).toList();
  }

  // Filtrar sesiones
  List<Sesion> filtrarSesiones(String query) {
    if (query.isEmpty) return _sesiones;
    
    return _sesiones.where((sesion) {
      final nombre = sesion.nombre.toLowerCase();
      final searchQuery = query.toLowerCase();
      
      return nombre.contains(searchQuery);
    }).toList();
  }

  // Obtener estadísticas de una sesión
  Map<String, int> getEstadisticasSesion(int sesionId) {
    final asistencias = getAsistenciasSesion(sesionId);
    int asistieron = 0;
    int faltaron = 0;

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
      'total': asistencias.length,
    };
  }
} 