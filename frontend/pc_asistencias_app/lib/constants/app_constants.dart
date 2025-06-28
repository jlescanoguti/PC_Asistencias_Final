class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://pcasistenciasfinal-production.up.railway.app';
  
  // API Endpoints
  static const String testDb = '/test-db';
  static const String registrarAlumno = '/alumnos/registrar';
  static const String editarAlumno = '/alumnos/';
  static const String eliminarAlumno = '/alumnos/';
  static const String asistenciasAlumno = '/alumnos/';
  static const String crearSesion = '/sesiones/crear';
  static const String listarSesiones = '/sesiones';
  static const String detallesSesion = '/sesiones/';
  static const String editarSesion = '/sesiones/';
  static const String eliminarSesion = '/sesiones/';
  static const String finalizarSesion = '/sesiones/';
  static const String pasarAsistencia = '/sesiones/';
  static const String generarReporte = '/sesiones/';
  static const String reiniciarTablas = '/reiniciar-tablas';
  static const String listarAlumnos = '/alumnos';
  
  // App Colors
  static const int primaryColor = 0xFF2196F3;
  static const int secondaryColor = 0xFF1976D2;
  static const int accentColor = 0xFF64B5F6;
  static const int backgroundColor = 0xFFF5F5F5;
  static const int surfaceColor = 0xFFFFFFFF;
  static const int errorColor = 0xFFD32F2F;
  static const int successColor = 0xFF388E3C;
  static const int warningColor = 0xFFF57C00;
  
  // Text Colors
  static const int textPrimaryColor = 0xFF212121;
  static const int textSecondaryColor = 0xFF757575;
  static const int textLightColor = 0xFFBDBDBD;
  
  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  
  // Font Sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 24.0;
  
  // Animation Durations
  static const Duration animationDurationFast = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);
  
  // Validation Messages
  static const String requiredField = 'Este campo es obligatorio';
  static const String invalidEmail = 'Ingrese un correo válido';
  static const String invalidCode = 'El código debe tener al menos 3 caracteres';
  static const String invalidName = 'El nombre debe tener al menos 2 caracteres';
  
  // Success Messages
  static const String alumnoRegistrado = 'Alumno registrado correctamente';
  static const String alumnoEditado = 'Alumno editado correctamente';
  static const String alumnoEliminado = 'Alumno eliminado correctamente';
  static const String sesionCreada = 'Sesión creada correctamente';
  static const String sesionEditada = 'Sesión editada correctamente';
  static const String sesionEliminada = 'Sesión eliminada correctamente';
  static const String sesionFinalizada = 'Sesión finalizada correctamente';
  static const String asistenciaRegistrada = 'Asistencia registrada correctamente';
  
  // Error Messages
  static const String errorConexion = 'Error de conexión';
  static const String errorServidor = 'Error del servidor';
  static const String errorDesconocido = 'Error desconocido';
  static const String errorImagen = 'Error al procesar la imagen';
  static const String errorRostro = 'No se detectó un rostro en la imagen';
  static const String errorDuplicado = 'Ya existe un registro con estos datos';
  static const String errorSesionFinalizada = 'No se puede modificar una sesión finalizada';
  static const String errorAsistenciaDuplicada = 'La asistencia ya fue registrada';
  
  // App Info
  static const String appName = 'PC Asistencias';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Sistema de control de asistencias con reconocimiento facial';
} 