import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../../logic/vietqr_helper.dart';
import '../../../models.dart';
import '../../../state/app_state.dart';
import '../../../l10n/strings.dart';
import '../../ui_helpers.dart';
import '../common_widgets.dart';
import '../elements/profile_components.dart';

void showAddMember(BuildContext context, AppStrings s,
    {Person? existingPerson}) {
  final ctrl = TextEditingController(text: existingPerson?.name);
  final accCtrl = TextEditingController(text: existingPerson?.accountNo);
  final state = context.read<AppState>();
  int selectedColor =
      existingPerson?.colorIndex ?? (DateTime.now().millisecondsSinceEpoch % 8);
  String currentAvatarPath = existingPerson?.avatarUrl ?? '';
  String? selectedBankBin = existingPerson?.bankId;
  String? currentBankQrPath = existingPerson?.bankQrUrl;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => UIHelpers.showLiquidDialogWidget(
        context: ctx,
        title: existingPerson == null ? s.addMemberTitle : s.edit,
        confirmLabel: existingPerson == null ? s.add : s.save,
        onConfirm: () {
          if (ctrl.text.trim().isNotEmpty) {
            final name = ctrl.text.trim();
            final accountNo = accCtrl.text.trim();
            if (existingPerson == null) {
              state.addPerson(name,
                  colorIndex: selectedColor, 
                  avatarUrl: currentAvatarPath,
                  bankId: selectedBankBin,
                  accountNo: accountNo.isEmpty ? null : accountNo,
                  bankQrUrl: currentBankQrPath
              );
            } else {
              state.updatePerson(existingPerson.id,
                  name: name,
                  colorIndex: selectedColor,
                  avatarUrl: currentAvatarPath,
                  bankId: selectedBankBin,
                  accountNo: accountNo.isEmpty ? null : accountNo,
                  bankQrUrl: currentBankQrPath
              );
            }
          }
        },
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarPicker(
                imagePath: currentAvatarPath,
                colorIndex: selectedColor,
                onTap: () async {
                  final picker = image_picker.ImagePicker();
                  final image_picker.XFile? image = await picker.pickImage(
                      source: image_picker.ImageSource.gallery);
                  if (image != null) {
                    setState(() => currentAvatarPath = image.path);
                  }
                },
              ),
              const SizedBox(height: 24),
              
              StyledTextField(
                controller: ctrl, 
                hint: s.enterName,
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              ),
              const SizedBox(height: 16),
              
              ColorPickerList(
                selectedColorIndex: selectedColor,
                onSelected: (i) => setState(() => selectedColor = i),
              ),
              const SizedBox(height: 32),
              
              SectionLabel(label: s.bankingDetails, icon: Icons.account_balance_rounded),
              const SizedBox(height: 8),
              
              BankSelectorCard(
                selectedBankBin: selectedBankBin,
                s: s,
                onTap: () async {
                  final bank = await UIHelpers.showBankPicker(ctx);
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
              const SizedBox(height: 20),

              SectionLabel(label: s.bankQrCodeStatic, icon: Icons.qr_code_scanner_rounded),
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
            ],
          ),
        ),
      ),
    ),
  );
}

void confirmRemovePerson(BuildContext context, Person person, AppStrings s) {
  final state = context.read<AppState>();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  UIHelpers.showLiquidDialog(
    context: context,
    title: s.deleteMember,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 14),
              children: [
                TextSpan(text: '${s.delete} '),
                TextSpan(
                    text: person.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: '?')
              ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2))),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.deleteMemberMsg,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.w600)),
              )
            ],
          ),
        )
      ],
    ),
    confirmLabel: s.delete,
    isDestructive: true,
    onConfirm: () => state.removePerson(person.id),
  );
}

void showPersonSummary(BuildContext context, Person person, double paid,
    double share, double net, AppStrings s, NumberFormat fmt,
    {bool hideStats = false}) {
  showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final accentColor = UIHelpers.getAvatarColor(person.colorIndex);

        return Container(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0E0E1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, -10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.15),
                  border: Border.all(
                      color: accentColor.withValues(alpha: 0.1), width: 1),
                  image: person.avatarUrl.isNotEmpty
                      ? (person.avatarUrl.startsWith('http')
                          ? DecorationImage(
                              image: NetworkImage(person.avatarUrl),
                              fit: BoxFit.cover)
                          : (File(person.avatarUrl).existsSync()
                              ? DecorationImage(
                                  image: FileImage(File(person.avatarUrl)),
                                  fit: BoxFit.cover)
                              : null))
                      : null,
                ),
                child: person.avatarUrl.isEmpty ||
                        (!person.avatarUrl.startsWith('http') &&
                            !File(person.avatarUrl).existsSync())
                    ? Center(
                        child: Text(
                          person.name.isNotEmpty
                              ? person.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              Text(person.name,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0E0E1A),
                    letterSpacing: -0.5,
                  )),
              const SizedBox(height: 12),
              if (person.accountNo != null && person.bankId != null)
                Text(
                    '${VietQRHelper.getBankByBin(person.bankId)?.shortName} - ${person.accountNo}',
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              if (!hideStats) ...[
                _buildStatRow(s.totalPaid, paid, const Color(0xFF66BB6A), fmt, s,
                    isDark),
                const SizedBox(height: 16),
                _buildStatRow(s.yourShare, share, const Color(0xFFFFA726), fmt,
                    s, isDark),
                const SizedBox(height: 16),
                Divider(
                    color: isDark ? Colors.white12 : Colors.black12, height: 1),
                const SizedBox(height: 16),
                _buildStatRow(
                    s.tabBill,
                    net,
                    isDark ? Colors.white : const Color(0xFF0E0E1A),
                    fmt,
                    s,
                    isDark,
                    isNet: true),
              ],
              if (context.read<AppState>().canEditPerson(person))
                Padding(
                  padding: EdgeInsets.only(top: hideStats ? 8 : 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        showAddMember(context, s, existingPerson: person);
                      },
                      icon:
                          Icon(Icons.edit_rounded, color: accentColor, size: 20),
                      label: Text(
                        s.edit.toUpperCase(),
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.2,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: accentColor.withValues(alpha: 0.3),
                            width: 1.5),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      });
}

Widget _buildStatRow(String label, double value, Color color, NumberFormat fmt,
    AppStrings s, bool isDark,
    {bool isNet = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        isNet ? s.netBalance : label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isNet ? FontWeight.w800 : FontWeight.w600,
          color: isNet
              ? (isDark ? Colors.white70 : Colors.black87)
              : (isDark ? Colors.white54 : Colors.black54),
        ),
      ),
      Text(
        fmt.format(value),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: color,
          decoration: isNet ? TextDecoration.underline : null,
          decorationColor: color,
        ),
      ),
    ],
  );
}
