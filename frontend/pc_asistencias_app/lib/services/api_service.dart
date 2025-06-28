import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/alumno.dart';
import '../models/sesion.dart';
import '../models/asistencia.dart';
import '../utils/api_utils.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  // Test de conexión
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await _dio.get(AppConstants.testDb);
      return response.data;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ========== GESTIÓN DE ALUMNOS ==========

  Future<Map<String, dynamic>> registrarAlumno({
    required String nombre,
    required String apellido,
    required String codigo,
    required String correo,
    required File foto,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'nombre': nombre,
        'apellido': apellido,
        'codigo': codigo,
        'correo': correo,
        'foto': await MultipartFile.fromFile(foto.path),
      });

      final response = await _dio.post(
        AppConstants.registrarAlumno,
        data: formData,
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          throw Exception(e.response?.data['detail'] ?? 'Error al registrar alumno');
        }
      }
      throw Exception('Error al registrar alumno: $e');
    }
  }

  Future<Map<String, dynamic>> editarAlumno({
    required int alumnoId,
    String? nombre,
    String? apellido,
    String? codigo,
    String? correo,
    File? foto,
  }) async {
    try {
      Map<String, dynamic> formData = {};
      
      if (nombre != null) formData['nombre'] = nombre;
      if (apellido != null) formData['apellido'] = apellido;
      if (codigo != null) formData['codigo'] = codigo;
      if (correo != null) formData['correo'] = correo;
      if (foto != null) {
        formData['foto'] = await MultipartFile.fromFile(foto.path);
      }

      final response = await _dio.put(
        '${AppConstants.editarAlumno}$alumnoId',
        data: FormData.fromMap(formData),
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          throw Exception(e.response?.data['detail'] ?? 'Error al editar alumno');
        }
      }
      throw Exception('Error al editar alumno: $e');
    }
  }

  Future<Map<String, dynamic>> eliminarAlumno(int alumnoId) async {
    try {
      final response = await _dio.delete('${AppConstants.eliminarAlumno}$alumnoId');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          throw Exception(e.response?.data['detail'] ?? 'Error al eliminar alumno');
        }
      }
      throw Exception('Error al eliminar alumno: $e');
    }
  }

  Future<List<Asistencia>> listarAsistenciasAlumno(int alumnoId) async {
    try {
      final response = await _dio.get('${AppConstants.asistenciasAlumno}$alumnoId/asistencias');
      
      if (isSuccess(response.data['success'])) {
        List<dynamic> data = response.data['asistencias'];
        return data.map((json) => Asistencia.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener asistencias');
      }
    } catch (e) {
      throw Exception('Error al obtener asistencias: $e');
    }
  }

  // ========== GESTIÓN DE SESIONES ==========

  Future<Map<String, dynamic>> crearSesion(String nombre) async {
    try {
      FormData formData = FormData.fromMap({
        'nombre': nombre,
      });

      final response = await _dio.post(
        AppConstants.crearSesion,
        data: formData,
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          throw Exception(e.response?.data['detail'] ?? 'Error al crear sesión');
        }
      }
      throw Exception('Error al crear sesión: $e');
    }
  }

  Future<List<Sesion>> listarSesiones() async {
    try {
      final response = await _dio.get(AppConstants.listarSesiones);
      
      if (isSuccess(response.data['success'])) {
        List<dynamic> data = response.data['sesiones'];
        return data.map((json) => Sesion.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener sesiones');
      }
    } catch (e) {
      throw Exception('Error al obtener sesiones: $e');
    }
  }

  Future<Map<String, dynamic>> detallesSesion(int sesionId) async {
    try {
      final response = await _dio.get('${AppConstants.detallesSesion}$sesionId');
      
      if (isSuccess(response.data['success'])) {
        return response.data;
      } else {
        throw Exception('Error al obtener detalles de sesión');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          throw Exception('Sesión no encontrada');
        }
      }
      throw Exception('Error al obtener detalles de sesión: $e');
    }
  }

  Future<Map<String, dynamic>> editarSesion(int sesionId, String nombre) async {
    try {
      FormData formData = FormData.fromMap({
        'nombre': nombre,
      });

      final response = await _dio.put(
        '${AppConstants.editarSesion}$sesionId',
        data: formData,
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          throw Exception(e.response?.data['detail'] ?? 'Error al editar sesión');
        }
      }
      throw Exception('Error al editar sesión: $e');
    }
  }

  Future<Map<String, dynamic>> eliminarSesion(int sesionId) async {
    try {
      final response = await _dio.delete('${AppConstants.eliminarSesion}$sesionId');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          throw Exception(e.response?.data['detail'] ?? 'Error al eliminar sesión');
        }
      }
      throw Exception('Error al eliminar sesión: $e');
    }
  }

  Future<Map<String, dynamic>> finalizarSesion(int sesionId) async {
    try {
      final response = await _dio.post('${AppConstants.finalizarSesion}$sesionId/finalizar');
      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          throw Exception(e.response?.data['detail'] ?? 'Error al finalizar sesión');
        }
      }
      throw Exception('Error al finalizar sesión: $e');
    }
  }

  // ========== GESTIÓN DE ASISTENCIAS ==========

  Future<Map<String, dynamic>> pasarAsistencia({
    required int sesionId,
    required File foto,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(foto.path),
      });

      final response = await _dio.post(
        '${AppConstants.pasarAsistencia}$sesionId/asistencia',
        data: formData,
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          throw Exception(e.response?.data['detail'] ?? 'Error al pasar asistencia');
        }
      }
      throw Exception('Error al pasar asistencia: $e');
    }
  }

  Future<Uint8List> generarReportePDF(int sesionId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.generarReporte}$sesionId/reporte-pdf'),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Error al generar reporte PDF');
      }
    } catch (e) {
      throw Exception('Error al generar reporte PDF: $e');
    }
  }

  // ========== UTILIDADES ==========

  Future<Map<String, dynamic>> reiniciarTablas() async {
    try {
      final response = await _dio.post(AppConstants.reiniciarTablas);
      return response.data;
    } catch (e) {
      throw Exception('Error al reiniciar tablas: $e');
    }
  }

  Future<List<Alumno>> listarAlumnos() async {
    try {
      final response = await _dio.get(AppConstants.listarAlumnos);
      if (isSuccess(response.data['success'])) {
        List<dynamic> data = response.data['alumnos'];
        return data.map((json) => Alumno.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener alumnos');
      }
    } catch (e) {
      throw Exception('Error al obtener alumnos: $e');
    }
  }
} 