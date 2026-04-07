import 'dart:io';
import 'package:flutter/material.dart';
import '../../../logic/vietqr_helper.dart';
import '../../ui_helpers.dart';
import '../../../l10n/strings.dart';

class AvatarPicker extends StatelessWidget {
  final String? imagePath;
  final int colorIndex;
  final VoidCallback onTap;
  final double size;

  const AvatarPicker({
    super.key,
    required this.imagePath,
    required this.colorIndex,
    required this.onTap,
    this.size = 90,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = UIHelpers.getAvatarColor(colorIndex);
    final hasLocalImage = imagePath != null && imagePath!.isNotEmpty && !imagePath!.startsWith('http') && File(imagePath!).existsSync();
    final hasRemoteImage = imagePath != null && imagePath!.startsWith('http');

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarColor.withValues(alpha: 0.15),
                border: Border.all(
                    color: avatarColor.withValues(alpha: 0.3),
                    width: 2),
                image: hasRemoteImage
                    ? DecorationImage(image: NetworkImage(imagePath!), fit: BoxFit.cover)
                    : (hasLocalImage
                        ? DecorationImage(image: FileImage(File(imagePath!)), fit: BoxFit.cover)
                        : null),
              ),
              child: (!hasRemoteImage && !hasLocalImage)
                  ? Icon(Icons.person_rounded,
                      size: size * 0.53,
                      color: avatarColor)
                  : null,
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BankSelectorCard extends StatelessWidget {
  final String? selectedBankBin;
  final VoidCallback onTap;
  final AppStrings s;

  const BankSelectorCard({
    super.key,
    required this.selectedBankBin,
    required this.onTap,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final bank = VietQRHelper.getBankByBin(selectedBankBin);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.account_balance_rounded, color: primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.bankName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.grey : Colors.black45, letterSpacing: 0.5)),
                  Text(
                    bank?.name ?? s.selectBank,
                    style: TextStyle(
                      fontSize: 15,
                      color: selectedBankBin != null ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                      fontWeight: selectedBankBin != null ? FontWeight.w800 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class ColorPickerList extends StatelessWidget {
  final int selectedColorIndex;
  final Function(int) onSelected;

  const ColorPickerList({
    super.key,
    required this.selectedColorIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(8, (i) {
          final color = UIHelpers.getAvatarColor(i);
          final selected = selectedColorIndex == i;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                    color: selected ? Colors.white : Colors.transparent,
                    width: 2.5),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2)
                      ]
                    : [],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class QrPreviewCard extends StatelessWidget {
  final String? qrPath;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final AppStrings s;

  const QrPreviewCard({
    super.key,
    required this.qrPath,
    required this.onTap,
    required this.onClear,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasQr = qrPath != null && qrPath!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primary.withValues(alpha: 0.1),
            style: BorderStyle.solid,
          ),
        ),
        child: !hasQr
            ? Column(
                children: [
                  Icon(Icons.add_photo_alternate_outlined, color: primary.withValues(alpha: 0.5), size: 32),
                  const SizedBox(height: 8),
                  Text(s.bankQR, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                ],
              )
            : IntrinsicHeight(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: (qrPath!.startsWith('http')
                          ? Image.network(qrPath!, width: 60, height: 60, fit: BoxFit.cover)
                          : (File(qrPath!).existsSync()
                              ? Image.file(File(qrPath!), width: 60, height: 60, fit: BoxFit.cover)
                              : Container(width: 60, height: 60, color: Colors.black26, child: const Icon(Icons.broken_image)))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text(s.myStaticQR, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded, size: 20, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
