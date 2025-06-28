import 'package:intl/intl.dart';

class Asistencia {
  final int? id;
  final int sesionId;
  final int alumnoId;
  final String estado;
  final String? nombreAlumno;
  final String? apellidoAlumno;
  final String? codigoAlumno;
  final String? correoAlumno;
  final String? nombreSesion;
  final DateTime? fechaSesion;
  final bool? sesionFinalizada;

  Asistencia({
    this.id,
    required this.sesionId,
    required this.alumnoId,
    required this.estado,
    this.nombreAlumno,
    this.apellidoAlumno,
    this.codigoAlumno,
    this.correoAlumno,
    this.nombreSesion,
    this.fechaSesion,
    this.sesionFinalizada,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      id: json['id'],
      sesionId: json['sesion_id'] ?? json['sesionId'] ?? 0,
      alumnoId: json['alumno_id'] ?? json['alumnoId'] ?? 0,
      estado: json['estado'] ?? '',
      nombreAlumno: json['nombre'],
      apellidoAlumno: json['apellido'],
      codigoAlumno: json['codigo'],
      correoAlumno: json['correo'],
      nombreSesion: json['sesion_nombre'],
      fechaSesion: json['fecha'] != null 
          ? DateTime.parse(json['fecha']) 
          : null,
      sesionFinalizada: json['finalizada'] == true || json['finalizada'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sesion_id': sesionId,
      'alumno_id': alumnoId,
      'estado': estado,
      'nombre': nombreAlumno,
      'apellido': apellidoAlumno,
      'codigo': codigoAlumno,
      'correo': correoAlumno,
      'sesion_nombre': nombreSesion,
      'fecha': fechaSesion?.toIso8601String(),
      'finalizada': sesionFinalizada,
    };
  }

  String get nombreCompletoAlumno {
    if (nombreAlumno != null && apellidoAlumno != null) {
      return '$nombreAlumno $apellidoAlumno';
    }
    return nombreAlumno ?? apellidoAlumno ?? 'Sin nombre';
  }

  String get fechaFormateada {
    if (fechaSesion == null) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy HH:mm').format(fechaSesion!);
  }

  bool get asistio => estado.toLowerCase() == 'asistió';

  String get estadoFormateado {
    switch (estado.toLowerCase()) {
      case 'asistió':
        return 'Asistió';
      case 'faltó':
        return 'Faltó';
      default:
        return estado;
    }
  }

  @override
  String toString() {
    return 'Asistencia(id: $id, sesionId: $sesionId, alumnoId: $alumnoId, estado: $estado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Asistencia && 
           other.sesionId == sesionId && 
           other.alumnoId == alumnoId;
  }

  @override
  int get hashCode => sesionId.hashCode ^ alumnoId.hashCode;
} 