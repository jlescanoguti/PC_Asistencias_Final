import 'package:intl/intl.dart';

class Sesion {
  final int? id;
  final String nombre;
  final DateTime? fecha;
  final bool finalizada;

  Sesion({
    this.id,
    required this.nombre,
    this.fecha,
    this.finalizada = false,
  });

  factory Sesion.fromJson(Map<String, dynamic> json) {
    return Sesion(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      fecha: json['fecha'] != null 
          ? DateTime.parse(json['fecha']) 
          : null,
      finalizada: json['finalizada'] == true || json['finalizada'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'fecha': fecha?.toIso8601String(),
      'finalizada': finalizada,
    };
  }

  Sesion copyWith({
    int? id,
    String? nombre,
    DateTime? fecha,
    bool? finalizada,
  }) {
    return Sesion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      fecha: fecha ?? this.fecha,
      finalizada: finalizada ?? this.finalizada,
    );
  }

  String get fechaFormateada {
    if (fecha == null) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha!);
  }

  String get fechaCorta {
    if (fecha == null) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy').format(fecha!);
  }

  String get estado {
    return finalizada ? 'Finalizada' : 'Activa';
  }

  @override
  String toString() {
    return 'Sesion(id: $id, nombre: $nombre, fecha: $fecha, finalizada: $finalizada)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sesion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 