import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../models.dart';
import '../../../l10n/strings.dart';
import '../../../logic/vietqr_helper.dart';
import '../../../state/app_state.dart';
import '../base/ambient_glow.dart';
import '../../ui_helpers.dart';

class VietQRModal extends StatefulWidget {
  final Person recipient;
  final double amount;
  final String memo;

  const VietQRModal({
    super.key,
    required this.recipient,
    required this.amount,
    required this.memo,
  });

  @override
  State<VietQRModal> createState() => _VietQRModalState();
}

class _VietQRModalState extends State<VietQRModal> {
  List<BankInfo> _banksToDisplay = [];
  String? _myBankId;
  String? _selectedSenderBankBin;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newBankId = Provider.of<AppState>(context).userProfile?.bankId;
    
    if (newBankId != _myBankId || _banksToDisplay.isEmpty) {
      _myBankId = newBankId;
      _selectedSenderBankBin ??= _myBankId; 
      
      final allBanks = List<BankInfo>.from(VietQRHelper.popularBanks);
      if (_myBankId != null) {
        final myIdx = allBanks.indexWhere((b) => b.bin == _myBankId);
        if (myIdx != -1) {
          final myBank = allBanks.removeAt(myIdx);
          allBanks.insert(0, myBank);
        }
      }
      _banksToDisplay = allBanks;
    }
  }

  void _onBankSelected(BuildContext context, BankInfo bank) {
    setState(() => _selectedSenderBankBin = bank.bin);
    HapticFeedback.lightImpact();
    VietQRHelper.openBankApp(
      context,
      VietQRHelper.generateRawVietQR(
        bankBin: widget.recipient.bankId!,
        accountNo: widget.recipient.accountNo!,
        amount: widget.amount,
        info: widget.memo,
      ),
      accountNo: widget.recipient.accountNo,
      bankBin: bank.bin,
      amount: widget.amount,
      memo: widget.memo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final hasBankInfo = widget.recipient.bankId != null && widget.recipient.accountNo != null;

    if (!hasBankInfo) {
      return _buildNoInfo(context, s, isDark);
    }

    String? qrUrl;
    String? deepLink;
    if (hasBankInfo) {
      qrUrl = VietQRHelper.generateQRUrl(
        bankBin: widget.recipient.bankId!,
        accountNo: widget.recipient.accountNo!,
        amount: widget.amount,
        info: widget.memo,
      );
      deepLink = VietQRHelper.generateDeepLink(
        bankBin: widget.recipient.bankId!,
        accountNo: widget.recipient.accountNo!,
        amount: widget.amount,
        info: widget.memo,
      );
    }

    final bank = VietQRHelper.getBankByBin(widget.recipient.bankId);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0E0E1A) : const Color(0xFFF8F9FE),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(isDark),
              const SizedBox(height: 24),
              Text(s.payViaVietQR, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(widget.recipient.name, style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary, fontSize: 13)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(bank?.shortName ?? s.bankName, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              Stack(
                alignment: Alignment.center,
                children: [
                  AmbientGlow(color: cs.primary, size: 260, opacity: 0.15),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.1), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: cs.primary.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 0, offset: const Offset(0, 10))
                      ],
                    ),
                    child: CachedNetworkImage(
                      imageUrl: qrUrl!,
                      width: 220,
                      height: 220,
                      placeholder: (context, url) => _Skeleton(),
                      errorWidget: (context, url, error) => const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              if (deepLink != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                       Container(
                        width: 32, height: 4, 
                        decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.black12, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(height: 16),
                      Text(s.openBankApp, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 100,
                        child: AnimationLimiter(
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _banksToDisplay.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 16),
                            itemBuilder: (ctx, idx) {
                              final b = _banksToDisplay[idx];
                              return AnimationConfiguration.staggeredList(
                                position: idx,
                                duration: const Duration(milliseconds: 300),
                                child: SlideAnimation(
                                  horizontalOffset: 30.0,
                                  child: FadeInAnimation(
                                    child: _QuickBankIcon(
                                      bin: b.bin,
                                      name: b.shortName,
                                      isHighlighted: b.bin == _selectedSenderBankBin,
                                      onTap: () => _onBankSelected(context, b),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: TextButton.icon(
                          onPressed: () async {
                            final bankPick = await UIHelpers.showBankPicker(context);
                            if (bankPick != null && context.mounted) {
                              setState(() => _selectedSenderBankBin = bankPick.bin);
                              VietQRHelper.openBankApp(
                                context,
                                VietQRHelper.generateRawVietQR(
                                  bankBin: widget.recipient.bankId!,
                                  accountNo: widget.recipient.accountNo!,
                                  amount: widget.amount,
                                  info: widget.memo,
                                ),
                                accountNo: widget.recipient.accountNo,
                                bankBin: bankPick.bin, 
                                amount: widget.amount,
                                memo: widget.memo,
                              );
                            }
                          },
                          icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                          label: Text(s.openOtherBankApp, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.white60 : Colors.black54,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (widget.recipient.accountNo != null)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: widget.recipient.accountNo!));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.accountCopied)));
                          },
                          icon: const Icon(Icons.copy_all_rounded, size: 18),
                          label: Text(widget.recipient.accountNo!, style: const TextStyle(fontWeight: FontWeight.w900, fontFamily: 'monospace', letterSpacing: 1.2)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: isDark ? Colors.white : Colors.black87,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              if (widget.amount > 0)
                Text(
                  s.qrPreFillHint.replaceAll('{amount}', widget.amount.toInt().toString()),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black38),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(bool isDark) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? Colors.white24 : Colors.black12,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildNoInfo(BuildContext context, AppStrings s, bool isDark) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                s.noPaymentInfo,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                s.noPaymentInfoMsg.replaceAll('{name}', widget.recipient.name),
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => Navigator.pop(context), child: Text(s.close)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(width: 220, height: 220, color: Colors.white),
  );
}

class _QuickBankIcon extends StatelessWidget {
  final String bin;
  final String name;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _QuickBankIcon({
    required this.bin, 
    required this.name, 
    this.isHighlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isHighlighted 
                  ? Theme.of(context).colorScheme.primary 
                  : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
                width: isHighlighted ? 2.5 : 1.5,
              ),
              boxShadow: [
                if (isHighlighted)
                  BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 0),
                if (!isHighlighted)
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: 'https://api.vietqr.io/img/$name.png',
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                placeholder: (_, __) => Container(width: 44, height: 44, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                errorWidget: (context, url, error) => Container(
                  width: 44, height: 44,
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  child: Center(
                    child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name, 
            style: TextStyle(
              fontSize: 11, 
              fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.bold, 
              color: isHighlighted ? Theme.of(context).colorScheme.primary : (isDark ? Colors.white38 : Colors.black45),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
