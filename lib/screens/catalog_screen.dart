import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import 'ar_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ApiService _api = ApiService();
  List<dynamic> productos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    try {
      final data = await _api.getProductos();
      setState(() {
        productos = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar catálogo: $e')),
      );
      setState(() => isLoading = false);
    }
  }

  void _abrirAR(String? url3d, String nombreProducto) {
    if (url3d == null || url3d.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este producto no tiene modelo 3D aún.')),
      );
      return;
    }
    
    // Navegar a la pantalla del Simulador AR
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ARScreen(
          url3d: url3d,
          nombreProducto: nombreProducto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda AR', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFEA580C),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF4F3EF),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C)))
          : productos.isEmpty
              ? const Center(child: Text('No hay ropa en el catálogo.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final p = productos[index];
                    final tieneAR = p['modelo_3d_url'] != null && p['modelo_3d_url'].toString().isNotEmpty;

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              child: const Icon(Icons.image, size: 50, color: Colors.grey),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['nombre'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text('Bs ${p['precio'] ?? 0}', style: const TextStyle(color: Color(0xFFEA580C), fontWeight: FontWeight.bold)),
                                // Botones de Acción
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: p['modelo_3d_url'] != null ? Colors.black : Colors.grey,
                                          side: BorderSide(color: p['modelo_3d_url'] != null ? Colors.black : Colors.grey.shade300),
                                        ),
                                        icon: const Icon(Icons.view_in_ar, size: 16),
                                        label: const Text('Ver en AR', style: TextStyle(fontSize: 12)),
                                        onPressed: () => _abrirAR(p['modelo_3d_url'], p['nombre']),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.add_shopping_cart, color: Colors.orange),
                                      onPressed: () {
                                        CartService().addItem(
                                          p['id'], 
                                          p['nombre'], 
                                          (p['precio'] ?? 0).toDouble()
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${p['nombre']} añadido a tu reserva'), 
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
