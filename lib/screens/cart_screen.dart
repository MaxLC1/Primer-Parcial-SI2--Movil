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
  bool _isLoading = false;

  void _confirmarReserva() async {
    if (_cart.items.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ApiService().crearReserva(_cart.items);
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
    // ListenableBuilder escucha los cambios de ChangeNotifier en CartService
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
            
            // Footer con el total y botón
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Bs ${_cart.total}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
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
