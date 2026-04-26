// lib/widgets/pc_list_widget.dart
import 'package:flutter/material.dart';
import 'package:test1/models/booking.dart';

class PcListWidget extends StatelessWidget {
  final Room room;
  final PricesResponse? pricesResponse;
  final bool Function(PC pc) isPcAvailable;
  final bool Function(Product product) isPackageAvailable;
  final void Function(PC pc) onPcTap;
  final void Function(Product product) onPackageTap;
  final bool isDateTimeSelected;
  final void Function(String message) showMessage;

  const PcListWidget({
    super.key,
    required this.room,
    required this.pricesResponse,
    required this.isPcAvailable,
    required this.isPackageAvailable,
    required this.onPcTap,
    required this.onPackageTap,
    required this.isDateTimeSelected,
    required this.showMessage,
  });

  List<Product> _getDisplayProducts() {
    final realProducts = pricesResponse?.products
            .where((p) => p.groupName == room.areaName)
            .toList() ??
        [];
    if (realProducts.isEmpty) {
      return [
        Product(
          id: -1,
          name: 'Пакет',
          price: '0',
          totalPrice: '0',
          duration: '0',
          durationMin: '0',
          isCalcDuration: false,
          showTimeStart: '',
          showTimeEnd: '',
          groupName: room.areaName,
        )
      ];
    }
    return realProducts;
  }

  @override
  Widget build(BuildContext context) {
    final products = _getDisplayProducts();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...room.pcs.map((pc) {
          final isAvailable = isPcAvailable(pc);
          return _PcItem(
            pc: pc,
            isAvailable: isAvailable,
            isDateTimeSelected: isDateTimeSelected,
            onTap: () {
              if (!isDateTimeSelected) {
                showMessage('Сначала выберите дату и время');
                return;
              }
              onPcTap(pc);
            },
          );
        }),

        // В методе build класса PcListWidget
        ...products.map((product) {
          final isReal = product.id != -1;
          final isAvailable = isReal && isPackageAvailable(product);
          return _PackageItem(
            product: product,
            isAvailable: isAvailable,
            isDateTimeSelected: isDateTimeSelected,
            onTap: () {
              if (!isDateTimeSelected) {
                showMessage('Сначала выберите дату и время');
                return;
              }
              // Всегда вызываем onPackageTap, даже для недоступного/фиктивного пакета
              onPackageTap(product);
            },
          );
        }),
      ],
    );
  }
}

class _PcItem extends StatelessWidget {
  final PC pc;
  final bool isAvailable;
  final bool isDateTimeSelected;
  final VoidCallback onTap;

  const _PcItem({
    required this.pc,
    required this.isAvailable,
    required this.isDateTimeSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDateTimeSelected
        ? (isAvailable ? const Color(0xFF4CAF50) : const Color(0xFF7B0D8F))
        : const Color(0xFF4CAF50);

    return InkWell(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: pc.enabled == 1 ? const Color(0xFF1D1D1D) : Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.computer,
              color: pc.enabled == 1 ? Colors.white : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              pc.name,
              style: TextStyle(
                color: pc.enabled == 1 ? Colors.white : Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            if (pc.enabled == 0)
              const Text(
                'Выкл',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}

class _PackageItem extends StatelessWidget {
  final Product product;
  final bool isAvailable;
  final bool isDateTimeSelected;
  final VoidCallback onTap;

  const _PackageItem({
    required this.product,
    required this.isAvailable,
    required this.isDateTimeSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isReal = product.id != -1;
    final borderColor = !isDateTimeSelected
        ? const Color(0xFF4CAF50)
        : (isReal && isAvailable ? const Color(0xFF4CAF50) : const Color(0xFF7B0D8F));

    //final priceText = isReal ? '${product.totalPrice} ₽' : '—';
    final nameText = isReal ? product.name : 'Пакет';

    return InkWell(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1D1D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.card_giftcard,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              nameText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                decoration: TextDecoration.none, // явно убираем подчёркивание
              ),
              textAlign: TextAlign.center,
              maxLines: 10,
              overflow: TextOverflow.ellipsis,
            ),
            /*Text(
              priceText,
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 10,
                decoration: TextDecoration.none,
              ),
            ),*/
          ],
        ),
      ),
    );
  }
}