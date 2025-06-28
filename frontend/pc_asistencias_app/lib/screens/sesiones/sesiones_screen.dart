import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../providers/sesiones_provider.dart';
import '../../models/sesion.dart';
import 'crear_sesion_screen.dart';
import 'detalle_sesion_screen.dart';
import 'editar_sesion_screen.dart';

class SesionesScreen extends StatefulWidget {
  const SesionesScreen({super.key});

  @override
  State<SesionesScreen> createState() => _SesionesScreenState();
}

class _SesionesScreenState extends State<SesionesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SesionesProvider>().cargarSesiones();
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
        title: const Text('Gestión de Sesiones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SesionesProvider>().cargarSesiones();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lista de sesiones actualizada'),
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
                hintText: 'Buscar sesiones...',
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
          
          // Lista de sesiones
          Expanded(
            child: Consumer<SesionesProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Color(AppConstants.errorColor)),
                        const SizedBox(height: 16),
                        Text('Error al cargar sesiones', style: GoogleFonts.poppins(fontSize: AppConstants.fontSizeLarge, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(provider.error!, style: GoogleFonts.poppins(color: Color(AppConstants.textSecondaryColor)), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            provider.clearError();
                            provider.cargarSesiones();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                final sesiones = provider.filtrarSesiones(_searchQuery);
                if (sesiones.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_searchQuery.isEmpty ? Icons.class_ : Icons.search_off, size: 64, color: Color(AppConstants.textLightColor)),
                        const SizedBox(height: 16),
                        Text(_searchQuery.isEmpty ? 'No hay sesiones creadas' : 'No se encontraron resultados', style: GoogleFonts.poppins(fontSize: AppConstants.fontSizeLarge, fontWeight: FontWeight.w600, color: Color(AppConstants.textSecondaryColor))),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Crea la primera sesión', style: GoogleFonts.poppins(color: Color(AppConstants.textLightColor))),
                        ],
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
                  itemCount: sesiones.length,
                  itemBuilder: (context, index) {
                    final sesion = sesiones[index];
                    return _buildSesionCard(sesion, provider);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrearSesionScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSesionCard(Sesion sesion, SesionesProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: sesion.finalizada ? Color(AppConstants.errorColor).withOpacity(0.1) : Color(AppConstants.primaryColor).withOpacity(0.1),
          child: Icon(
            sesion.finalizada ? Icons.lock : Icons.class_,
            color: sesion.finalizada ? Color(AppConstants.errorColor) : Color(AppConstants.primaryColor),
            size: 28,
          ),
        ),
        title: Text(
          sesion.nombre,
          style: GoogleFonts.poppins(fontSize: AppConstants.fontSizeLarge, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Fecha: ${sesion.fechaFormateada}', style: GoogleFonts.poppins(fontSize: AppConstants.fontSizeMedium, color: Color(AppConstants.textSecondaryColor))),
            Text('Estado: ${sesion.estado}', style: GoogleFonts.poppins(fontSize: AppConstants.fontSizeMedium, color: sesion.finalizada ? Color(AppConstants.errorColor) : Color(AppConstants.successColor))),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'detalle':
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetalleSesionScreen(sesion: sesion)),
                );
                if (result == true) {
                  await provider.cargarSesiones();
                }
                break;
              case 'edit':
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditarSesionScreen(sesion: sesion)),
                );
                if (result == true) {
                  await provider.cargarSesiones();
                }
                break;
              case 'delete':
                _showDeleteDialog(sesion, provider);
                break;
              case 'finalizar':
                _showFinalizarDialog(sesion, provider);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'detalle', child: Row(children: [Icon(Icons.info, size: 20), SizedBox(width: 8), Text('Ver Detalle')],)),
            if (!sesion.finalizada) ...[
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Editar')],)),
              const PopupMenuItem(value: 'finalizar', child: Row(children: [Icon(Icons.lock, size: 20), SizedBox(width: 8), Text('Finalizar')],)),
            ],
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.red))],)),
          ],
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DetalleSesionScreen(sesion: sesion)),
          );
          if (result == true) {
            await provider.cargarSesiones();
          }
        },
      ),
    );
  }

  void _showDeleteDialog(Sesion sesion, SesionesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Sesión', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('¿Estás seguro de que quieres eliminar la sesión "${sesion.nombre}"? Esta acción no se puede deshacer.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await provider.eliminarSesion(sesion.id!);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sesión eliminada correctamente'), backgroundColor: Color(AppConstants.successColor)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(AppConstants.errorColor)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showFinalizarDialog(Sesion sesion, SesionesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Finalizar Sesión', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('¿Deseas finalizar la sesión "${sesion.nombre}"? No se podrá pasar asistencia después.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await provider.finalizarSesion(sesion.id!);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sesión finalizada correctamente'), backgroundColor: Color(AppConstants.successColor)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(AppConstants.primaryColor)),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }
} 