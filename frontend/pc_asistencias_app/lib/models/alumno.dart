class Alumno {
  final int? id;
  final String nombre;
  final String apellido;
  final String codigo;
  final String correo;
  final String? foto;
  final String? embedding;

  Alumno({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.codigo,
    required this.correo,
    this.foto,
    this.embedding,
  });

  factory Alumno.fromJson(Map<String, dynamic> json) {
    return Alumno(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      foto: json['foto']?.toString(),
      embedding: json['embedding']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'codigo': codigo,
      'correo': correo,
      'foto': foto,
      'embedding': embedding,
    };
  }

  Alumno copyWith({
    int? id,
    String? nombre,
    String? apellido,
    String? codigo,
    String? correo,
    String? foto,
    String? embedding,
  }) {
    return Alumno(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      codigo: codigo ?? this.codigo,
      correo: correo ?? this.correo,
      foto: foto ?? this.foto,
      embedding: embedding ?? this.embedding,
    );
  }

  String get nombreCompleto => '$nombre $apellido';

  @override
  String toString() {
    return 'Alumno(id: $id, nombre: $nombre, apellido: $apellido, codigo: $codigo, correo: $correo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Alumno && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 