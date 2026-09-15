import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cart = CartService();
  final ApiService _api = ApiService();
  
  bool _isLoading = false;
  bool _isLoadingSucursales = true;
  List<dynamic> _sucursales = [];
  int? _selectedSucursalId;

  @override
  void initState() {
    super.initState();
    _loadSucursales();
  }

  Future<void> _loadSucursales() async {
    try {
      final sucursales = await _api.getSucursales();
      setState(() {
        _sucursales = sucursales;
        _isLoadingSucursales = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando sucursales: $e')),
      );
      setState(() => _isLoadingSucursales = false);
    }
  }

  void _confirmarReserva() async {
    if (_cart.items.isEmpty) return;
    
    if (_selectedSucursalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una sucursal para tu reserva.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _api.crearReserva(_cart.items, _selectedSucursalId!);
      if (!mounted) return;
      
      _cart.clear(); // Limpiamos el carrito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Reserva confirmada con éxito!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _cart,
      builder: (context, _) {
        if (_cart.items.isEmpty) {
          return const Center(
            child: Text('Tu bolsa de reservas está vacía.', style: TextStyle(fontSize: 16)),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _cart.items.length,
                itemBuilder: (context, index) {
                  final item = _cart.items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Cantidad: ${item.cantidad}  -  Unitario: Bs ${item.precioUnitario}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Bs ${item.subtotal}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _cart.removeItem(item.productoId),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Footer con selección de sucursal y total
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Selector de Sucursal
                    if (_isLoadingSucursales)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<int>(
                        value: _selectedSucursalId,
                        decoration: InputDecoration(
                          labelText: 'Selecciona una Sucursal',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: _sucursales.map<DropdownMenuItem<int>>((sucursal) {
                          return DropdownMenuItem<int>(
                            value: sucursal['id'],
                            child: Text('${sucursal['nombre']} - ${sucursal['direccion']}'),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            _selectedSucursalId = newValue;
                          });
                        },
                      ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Bs ${_cart.total}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _confirmarReserva,
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('CONFIRMAR RESERVA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
