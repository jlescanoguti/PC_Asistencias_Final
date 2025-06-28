import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../providers/alumnos_provider.dart';
import '../../models/alumno.dart';
import 'registrar_alumno_screen.dart';
import 'editar_alumno_screen.dart';

class AlumnosScreen extends StatefulWidget {
  const AlumnosScreen({super.key});

  @override
  State<AlumnosScreen> createState() => _AlumnosScreenState();
}

class _AlumnosScreenState extends State<AlumnosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlumnosProvider>().cargarAlumnos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppConstants.backgroundColor),
      appBar: AppBar(
        title: const Text('Gestión de Alumnos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AlumnosProvider>().cargarAlumnos();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lista actualizada'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar alumnos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Lista de alumnos
          Expanded(
            child: Consumer<AlumnosProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Color(AppConstants.errorColor),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar alumnos',
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.fontSizeLarge,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.error!,
                          style: GoogleFonts.poppins(
                            color: Color(AppConstants.textSecondaryColor),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            provider.clearError();
                            provider.cargarAlumnos();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final alumnos = provider.filtrarAlumnos(_searchQuery);

                if (alumnos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
                          size: 64,
                          color: Color(AppConstants.textLightColor),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'No hay alumnos registrados'
                              : 'No se encontraron resultados',
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.fontSizeLarge,
                            fontWeight: FontWeight.w600,
                            color: Color(AppConstants.textSecondaryColor),
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Agrega el primer alumno',
                            style: GoogleFonts.poppins(
                              color: Color(AppConstants.textLightColor),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLarge,
                  ),
                  itemCount: alumnos.length,
                  itemBuilder: (context, index) {
                    final alumno = alumnos[index];
                    return _buildAlumnoCard(alumno, provider);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegistrarAlumnoScreen(),
            ),
          );
          if (result == true) {
            final provider = context.read<AlumnosProvider>();
            await provider.cargarAlumnos();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Alumno registrado correctamente'), duration: Duration(seconds: 2)),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAlumnoCard(Alumno alumno, AlumnosProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Color(AppConstants.primaryColor).withOpacity(0.1),
          backgroundImage: alumno.foto != null ? NetworkImage(alumno.foto!) : null,
          child: alumno.foto == null
              ? Icon(
                  Icons.person,
                  size: 30,
                  color: Color(AppConstants.primaryColor),
                )
              : null,
        ),
        title: Text(
          alumno.nombreCompleto,
          style: GoogleFonts.poppins(
            fontSize: AppConstants.fontSizeLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Código: ${alumno.codigo}',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.fontSizeMedium,
                color: Color(AppConstants.textSecondaryColor),
              ),
            ),
            Text(
              alumno.correo,
              style: GoogleFonts.poppins(
                fontSize: AppConstants.fontSizeMedium,
                color: Color(AppConstants.textSecondaryColor),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditarAlumnoScreen(alumno: alumno),
                  ),
                );
                break;
              case 'delete':
                _showDeleteDialog(alumno, provider);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Alumno alumno, AlumnosProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Alumno'),
        content: Text('¿Estás seguro de eliminar a ${alumno.nombreCompleto}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final success = await provider.eliminarAlumno(alumno.id!);
              Navigator.of(context).pop();
              if (success) {
                await provider.cargarAlumnos();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alumno eliminado correctamente'), duration: Duration(seconds: 2)),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 