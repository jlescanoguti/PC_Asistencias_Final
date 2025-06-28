# PC_Asistencias_Final - Frontend

Aplicación móvil desarrollada en **Flutter** para el sistema de control de asistencias con reconocimiento facial. Proporciona una interfaz intuitiva y moderna para gestionar alumnos, sesiones y asistencias desde dispositivos móviles.

## 🎯 Funcionalidades Principales

### Gestión de Alumnos
- **Registro de alumnos** con captura de fotos desde la cámara o galería
- **Listado de alumnos** con información detallada y fotos
- **Edición de datos** personales y fotos de alumnos
- **Eliminación** de registros de alumnos
- **Consulta de asistencias** por alumno con historial completo

### Gestión de Sesiones
- **Creación de sesiones** con nombres personalizados
- **Listado de sesiones** con estado y fechas
- **Edición de sesiones** (nombre y configuración)
- **Eliminación** de sesiones no finalizadas
- **Finalización** de sesiones para bloquear modificaciones

### Control de Asistencias
- **Pase de asistencia** mediante reconocimiento facial
- **Captura de fotos** en tiempo real para verificación
- **Visualización de asistencias** por sesión con estadísticas
- **Reportes detallados** con porcentajes de asistencia
- **Historial de asistencias** por alumno

## 🔧 Tecnologías Utilizadas

### Framework Principal
- **Flutter 3.2.3+**: Framework de desarrollo multiplataforma
- **Dart SDK**: Lenguaje de programación moderno y tipado

### Gestión de Estado
- **Provider 6.1.1**: Patrón de gestión de estado reactivo
- **ChangeNotifier**: Para notificaciones de cambios de estado

### Comunicación con API
- **Dio 5.3.2**: Cliente HTTP avanzado con interceptores
- **HTTP 1.1.0**: Cliente HTTP estándar para operaciones básicas

### Navegación
- **Go Router 12.1.3**: Sistema de navegación declarativo y tipado

### UI y Componentes
- **Material Design 3**: Sistema de diseño moderno
- **Google Fonts 6.1.0**: Tipografías personalizadas (Poppins)
- **Flutter Material Symbols 0.0.4**: Iconografía moderna
- **Flutter SVG 2.0.9**: Soporte para gráficos vectoriales

### Manejo de Imágenes
- **Image Picker 1.0.4**: Captura y selección de imágenes
- **Path Provider 2.1.1**: Gestión de rutas de archivos

### Almacenamiento Local
- **Shared Preferences 2.2.2**: Almacenamiento de configuraciones

### Utilidades
- **Intl 0.18.1**: Internacionalización y formateo
- **URL Launcher 6.2.1**: Apertura de URLs externas
- **Form Validator 2.1.1**: Validación de formularios
- **Flutter Toast 8.2.4**: Notificaciones toast
- **PDF 3.10.7**: Generación y visualización de PDFs
- **Open File 3.3.2**: Apertura de archivos locales

## 🏗️ Arquitectura de la Aplicación

### Estructura de Archivos
```
lib/
├── main.dart                    # Punto de entrada de la aplicación
├── constants/
│   └── app_constants.dart       # Constantes globales y configuración
├── models/
│   ├── alumno.dart              # Modelo de datos para alumnos
│   ├── sesion.dart              # Modelo de datos para sesiones
│   └── asistencia.dart          # Modelo de datos para asistencias
├── providers/
│   ├── alumnos_provider.dart    # Gestión de estado de alumnos
│   ├── sesiones_provider.dart   # Gestión de estado de sesiones
│   └── asistencias_provider.dart # Gestión de estado de asistencias
├── services/
│   └── api_service.dart         # Servicio de comunicación con API
├── screens/
│   ├── splash_screen.dart       # Pantalla de carga inicial
│   ├── home_screen.dart         # Pantalla principal con menú
│   ├── alumnos/
│   │   ├── alumnos_screen.dart      # Lista de alumnos
│   │   ├── registrar_alumno_screen.dart  # Registro de alumno
│   │   └── editar_alumno_screen.dart     # Edición de alumno
│   ├── sesiones/
│   │   ├── sesiones_screen.dart      # Lista de sesiones
│   │   ├── crear_sesion_screen.dart  # Creación de sesión
│   │   ├── detalle_sesion_screen.dart    # Detalles de sesión
│   │   └── editar_sesion_screen.dart     # Edición de sesión
│   └── asistencias/
│       ├── asistencias_screen.dart       # Lista de asistencias
│       ├── pasar_asistencia_screen.dart  # Pase de asistencia
│       └── asistencias_alumno_screen.dart # Asistencias por alumno
├── widgets/
│   ├── menu_card.dart           # Tarjeta de menú reutilizable
│   └── image_picker_widget.dart # Widget para selección de imágenes
└── utils/
    └── api_utils.dart           # Utilidades para manejo de API
```

### Patrón de Arquitectura
- **MVVM (Model-View-ViewModel)**: Separación clara de responsabilidades
- **Provider Pattern**: Gestión de estado reactivo y eficiente
- **Repository Pattern**: Abstracción de la capa de datos
- **Service Layer**: Lógica de negocio y comunicación con API

## 🎨 Diseño de Interfaz

### Sistema de Diseño
- **Material Design 3**: Componentes modernos y accesibles
- **Paleta de colores**: Azul primario (#2196F3) con variaciones
- **Tipografía**: Poppins para mejor legibilidad
- **Iconografía**: Material Symbols para consistencia visual

### Componentes Reutilizables
- **MenuCard**: Tarjetas de navegación con iconos y títulos
- **ImagePickerWidget**: Selector de imágenes con preview
- **CustomAppBar**: Barra de navegación personalizada
- **LoadingWidget**: Indicadores de carga consistentes
- **ErrorWidget**: Manejo de errores con mensajes claros

### Responsive Design
- **Adaptable**: Funciona en diferentes tamaños de pantalla
- **Orientación**: Soporte para portrait y landscape
- **Accesibilidad**: Contraste adecuado y tamaños de toque

## 📱 Flujo de Usuario

### Registro de Alumnos
1. **Navegación**: Menú principal → Gestión de Alumnos → Registrar
2. **Captura de datos**: Formulario con validaciones en tiempo real
3. **Selección de foto**: Cámara o galería con preview
4. **Envío**: Validación y registro en el backend
5. **Confirmación**: Mensaje de éxito y redirección

### Pase de Asistencia
1. **Selección de sesión**: Lista de sesiones activas
2. **Captura de foto**: Interfaz optimizada para reconocimiento
3. **Procesamiento**: Envío al backend para reconocimiento
4. **Resultado**: Confirmación de asistencia marcada
5. **Actualización**: Lista de asistencias actualizada

### Gestión de Sesiones
1. **Creación**: Formulario simple con nombre de sesión
2. **Configuración**: Inicialización automática de asistencias
3. **Monitoreo**: Estado en tiempo real de la sesión
4. **Finalización**: Bloqueo de modificaciones posteriores

## 🔗 Integración con Backend

### Configuración de API
- **Base URL**: Configurada en `AppConstants`
- **Endpoints**: Mapeados a métodos del `ApiService`
- **Autenticación**: Preparado para implementación futura
- **CORS**: Configurado para comunicación cross-origin

### Manejo de Respuestas
- **Formato consistente**: `{"success": bool, "data": ...}`
- **Error handling**: Manejo centralizado de errores
- **Loading states**: Indicadores de carga apropiados
- **Retry logic**: Reintentos automáticos en fallos de red

### Sincronización de Datos
- **Estado local**: Cache de datos en providers
- **Actualización**: Refresh automático después de operaciones
- **Consistencia**: Validación de datos antes de envío
- **Offline**: Preparado para funcionalidad offline futura

## 🚀 Configuración y Despliegue

### Requisitos del Sistema
- **Flutter SDK**: 3.2.3 o superior
- **Dart SDK**: Compatible con Flutter
- **Android Studio / VS Code**: IDE recomendado
- **Dispositivo/Emulador**: Android 5.0+ o iOS 11.0+

### Instalación y Configuración
```bash
# Clonar repositorio
git clone <repo_url>
cd PC_Asistencias_Final/frontend/pc_asistencias_app

# Obtener dependencias
flutter pub get

# Configurar variables de entorno
# Editar lib/constants/app_constants.dart con tu API URL

# Ejecutar en modo debug
flutter run

# Construir APK de release
flutter build apk --release
```

### Configuración de Plataformas

#### Android
- **Target SDK**: API 33 (Android 13)
- **Min SDK**: API 21 (Android 5.0)
- **Permisos**: Cámara, almacenamiento, internet
- **Iconos**: Adaptive icons configurados

#### iOS
- **Target**: iOS 11.0+
- **Permisos**: Cámara, fotos, micrófono
- **Configuración**: Info.plist configurado
- **Certificados**: Preparado para App Store

## 🔒 Seguridad y Validaciones

### Validaciones de Entrada
- **Formularios**: Validación en tiempo real
- **Tipos de datos**: Verificación de formatos
- **Longitudes**: Límites apropiados para campos
- **Caracteres especiales**: Sanitización de entrada

### Manejo de Errores
- **Errores de red**: Mensajes informativos
- **Errores de API**: Traducción de códigos de error
- **Errores de validación**: Feedback inmediato al usuario
- **Errores críticos**: Fallback graceful

### Privacidad
- **Permisos**: Solicitud explícita de permisos
- **Datos sensibles**: No almacenamiento local de información crítica
- **Imágenes**: Procesamiento temporal sin persistencia
- **Logs**: Sin información sensible en logs

## 📊 Rendimiento y Optimización

### Optimizaciones Implementadas
- **Lazy loading**: Carga de datos bajo demanda
- **Image caching**: Cache de imágenes para mejor rendimiento
- **State management**: Actualizaciones eficientes de UI
- **Memory management**: Liberación apropiada de recursos

### Monitoreo
- **Performance**: Métricas de rendimiento integradas
- **Crash reporting**: Preparado para herramientas de monitoreo
- **Analytics**: Eventos de usuario para análisis
- **Logs**: Sistema de logging estructurado

## 🔮 Características Futuras

### Mejoras Planificadas
- **Autenticación**: Sistema de login y registro
- **Notificaciones push**: Alertas en tiempo real
- **Modo offline**: Funcionalidad sin conexión
- **Sincronización**: Sync automático de datos
- **Analytics**: Dashboard de estadísticas avanzadas

### Expansión de Plataformas
- **Web**: Versión web responsive
- **Desktop**: Aplicación de escritorio
- **Wearables**: Soporte para smartwatches
- **Tablets**: Optimización para pantallas grandes

### Integraciones
- **Calendario**: Sincronización con calendarios
- **Email**: Envío de reportes por correo
- **Cloud storage**: Backup automático de datos
- **Third-party APIs**: Integración con sistemas educativos

## 📈 Métricas de Usuario

### KPIs Principales
- **Tiempo de registro**: < 30 segundos por alumno
- **Precisión de reconocimiento**: > 95%
- **Tiempo de respuesta**: < 2 segundos
- **Tasa de error**: < 1%

### Experiencia de Usuario
- **Onboarding**: Tutorial interactivo para nuevos usuarios
- **Feedback**: Mensajes claros y útiles
- **Accesibilidad**: Soporte para lectores de pantalla
- **Internacionalización**: Preparado para múltiples idiomas

---

**Desarrollado con ❤️ para simplificar la gestión de asistencias académicas**
