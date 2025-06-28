import 'dart:io';
import 'package:flutter/material.dart';
import '../models/alumno.dart';
import '../services/api_service.dart';
import '../utils/api_utils.dart';

class AlumnosProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Alumno> _alumnos = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Alumno> get alumnos => _alumnos;
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

  // Registrar alumno
  Future<bool> registrarAlumno({
    required String nombre,
    required String apellido,
    required String codigo,
    required String correo,
    required File foto,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final result = await _apiService.registrarAlumno(
        nombre: nombre,
        apellido: apellido,
        codigo: codigo,
        correo: correo,
        foto: foto,
      );

      if (isSuccess(result['success'])) {
        // Recargar la lista de alumnos directamente
        await cargarAlumnos();
        return true;
      } else {
        _setError(result['message'] ?? 'Error al registrar alumno');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Editar alumno
  Future<bool> editarAlumno({
    required int alumnoId,
    String? nombre,
    String? apellido,
    String? codigo,
    String? correo,
    File? foto,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final result = await _apiService.editarAlumno(
        alumnoId: alumnoId,
        nombre: nombre,
        apellido: apellido,
        codigo: codigo,
        correo: correo,
        foto: foto,
      );

      if (isSuccess(result['success'])) {
        // Recargar la lista de alumnos
        await cargarAlumnos();
        return true;
      } else {
        _setError(result['message'] ?? 'Error al editar alumno');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Eliminar alumno
  Future<bool> eliminarAlumno(int alumnoId) async {
    try {
      _setLoading(true);
      _setError(null);

      final result = await _apiService.eliminarAlumno(alumnoId);

      if (isSuccess(result['success'])) {
        // Recargar la lista de alumnos desde el backend
        await cargarAlumnos();
        return true;
      } else {
        _setError(result['message'] ?? 'Error al eliminar alumno');
        return false;
      }
    } catch (e) {
      _setError('Error al eliminar alumno: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cargar alumnos (método auxiliar para recargar la lista)
  Future<void> cargarAlumnos() async {
    try {
      _setLoading(true);
      _setError(null);
      _alumnos = await _apiService.listarAlumnos();
    } catch (e) {
      _setError('Error al cargar alumnos: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Buscar alumno por ID
  Alumno? getAlumnoById(int id) {
    try {
      return _alumnos.firstWhere((alumno) => alumno.id == id);
    } catch (e) {
      return null;
    }
  }

  // Buscar alumno por código
  Alumno? getAlumnoByCodigo(String codigo) {
    try {
      return _alumnos.firstWhere((alumno) => alumno.codigo == codigo);
    } catch (e) {
      return null;
    }
  }

  // Filtrar alumnos
  List<Alumno> filtrarAlumnos(String query) {
    if (query.isEmpty) return _alumnos;
    
    return _alumnos.where((alumno) {
      final nombreCompleto = alumno.nombreCompleto.toLowerCase();
      final codigo = alumno.codigo.toLowerCase();
      final correo = alumno.correo.toLowerCase();
      final searchQuery = query.toLowerCase();
      
      return nombreCompleto.contains(searchQuery) ||
             codigo.contains(searchQuery) ||
             correo.contains(searchQuery);
    }).toList();
  }
} 