import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import '../../../state/app_state.dart';
import '../../../l10n/strings.dart';
import '../common_widgets.dart';
import '../elements/profile_components.dart';
import '../../ui_helpers.dart';

void showMyProfile(BuildContext context) {
  final s = AppStrings.of(context);
  final state = context.read<AppState>();
  final profile = state.userProfile;
  if (profile == null) return;

  final TextEditingController nameCtrl = TextEditingController(text: profile.name);
  final TextEditingController accCtrl = TextEditingController(text: profile.accountNo ?? '');
  String? selectedBankBin = profile.bankId;
  String? currentBankQrPath = profile.bankQrUrl;

  showDialog(
    context: context,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: GlassContainer(
            width: 400,
            padding: const EdgeInsets.all(24),
            gradientColors: isDark 
              ? [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.05)]
              : [Colors.white.withValues(alpha: 0.95), Colors.white.withValues(alpha: 0.85)],
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.personalInfo,
                        style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, 
                                   color: isDark ? Colors.white54 : Colors.black45),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  StyledTextField(
                    controller: nameCtrl,
                    hint: s.name,
                    prefixIcon: const Icon(Icons.person_rounded, size: 20),
                  ),
                  const SizedBox(height: 24),
                  
                  SectionLabel(
                    label: s.defaultPayment, 
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  const SizedBox(height: 8),
                  
                  BankSelectorCard(
                    selectedBankBin: selectedBankBin,
                    s: s,
                    onTap: () async {
                      final bank = await UIHelpers.showBankPicker(context);
                      if (bank != null) {
                        setState(() => selectedBankBin = bank.bin);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  StyledTextField(
                    controller: accCtrl,
                    hint: s.accountNumber,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.credit_card_rounded, size: 20),
                  ),
                  const SizedBox(height: 24),

                  SectionLabel(
                    label: s.defaultBankQR, 
                    icon: Icons.qr_code_scanner_rounded,
                  ),
                  const SizedBox(height: 8),
                  
                  QrPreviewCard(
                    qrPath: currentBankQrPath,
                    s: s,
                    onTap: () async {
                      final picker = image_picker.ImagePicker();
                      final image_picker.XFile? image = await picker.pickImage(
                          source: image_picker.ImageSource.gallery);
                      if (image != null) {
                        setState(() => currentBankQrPath = image.path);
                      }
                    },
                    onClear: () => setState(() => currentBankQrPath = null),
                  ),
                  const SizedBox(height: 32),
                  
                  FilledButton(
                    onPressed: () {
                      state.updateGlobalUserProfile(
                        name: nameCtrl.text.trim(),
                        bankId: selectedBankBin,
                        accountNo: accCtrl.text.trim().isEmpty ? null : accCtrl.text.trim(),
                        bankQrUrl: currentBankQrPath,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.profileUpdated))
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(s.save, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

