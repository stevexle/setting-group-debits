import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/strings.dart';

class BankInfo {
  final String id;
  final String name;
  final String bin;
  final String shortName;
  final String? logoUrl;

  const BankInfo({
    required this.id,
    required this.name,
    required this.bin,
    required this.shortName,
    this.logoUrl,
  });
}

class VietQRHelper {
  static const Map<String, String> bankSchemes = {
    '970436': 'vietcombank://|vcb.vn://', // Vietcombank
    '970418': 'bidvsmartbanking://|bidv.smartbanking://', // BIDV
    '970407': 'tcbmobile://|techcombank://|tcb-mobile://|tcbwm://|tcb://|tcbbusiness://|tcbbusinessmobile://', // Techcombank
    '970422': 'mbmobile://|mbbank://', // MBBank
    '970432': 'vpbankneo://', // VPBank
    '970423': 'tpbankmobile://', // TPBank
    '970415': 'vietinbankipays://', // VietinBank
    '970437': 'hdbank://', // HDBank
    '970443': 'shbmobile://', // SHB
    '970441': 'vibi://', // VIB
    '970416': 'acbmobile://', // ACB
    '970405': 'agribankmobile://', // Agribank
    '970448': 'ocbmobile://', // OCB
    '970426': 'msbmobile://', // MSB
    '970440': 'seamobile://', // SeABank
    '970431': 'eximbankmobile://', // Eximbank
    '970412': 'pvcombankapp://', // PVcomBank
    '970449': 'lpbankapp://', // LPBank
    '970425': 'abbankmobile://', // ABBank
    '970429': 'scbmobile://', // SCB
    '546034': 'cake://', // Cake
    '963388': 'timo://', // Timo
    '971011': 'vnpay://', // VNPay Wallet
  };

  static const List<BankInfo> popularBanks = [
    BankInfo(
        id: '970436', name: 'Vietcombank', bin: '970436', shortName: 'VCB'),
    BankInfo(id: '970418', name: 'BIDV', bin: '970418', shortName: 'BIDV'),
    BankInfo(
        id: '970407', name: 'Techcombank', bin: '970407', shortName: 'TCB'),
    BankInfo(id: '970415', name: 'VietinBank', bin: '970415', shortName: 'ICB'),
    BankInfo(id: '970422', name: 'MBBank', bin: '970422', shortName: 'MB'),
    BankInfo(id: '970432', name: 'VPBank', bin: '970432', shortName: 'VPB'),
    BankInfo(id: '970423', name: 'TPBank', bin: '970423', shortName: 'TPB'),
    BankInfo(id: '970416', name: 'ACB', bin: '970416', shortName: 'ACB'),
    BankInfo(id: '970403', name: 'Sacombank', bin: '970403', shortName: 'STB'),
    BankInfo(id: '970437', name: 'HDBank', bin: '970437', shortName: 'HDB'),
    BankInfo(id: '970441', name: 'VIB', bin: '970441', shortName: 'VIB'),
    BankInfo(id: '970443', name: 'SHB', bin: '970443', shortName: 'SHB'),
    BankInfo(id: '970426', name: 'MSB', bin: '970426', shortName: 'MSB'),
    BankInfo(id: '970448', name: 'OCB', bin: '970448', shortName: 'OCB'),
    BankInfo(id: '970440', name: 'SeABank', bin: '970440', shortName: 'SEAB'),
    BankInfo(id: '970449', name: 'LPBank', bin: '970449', shortName: 'LPB'),
    BankInfo(id: '970431', name: 'Eximbank', bin: '970431', shortName: 'EIB'),
    BankInfo(id: '970428', name: 'Nam A Bank', bin: '970428', shortName: 'NAB'),
    BankInfo(id: '970405', name: 'Agribank', bin: '970405', shortName: 'AGR'),
    BankInfo(id: '970425', name: 'ABBANK', bin: '970425', shortName: 'ABB'),
    BankInfo(id: '970412', name: 'PVcomBank', bin: '970412', shortName: 'PVCB'),
    BankInfo(id: '970409', name: 'Bac A Bank', bin: '970409', shortName: 'BAB'),
    BankInfo(id: '970433', name: 'VietBank', bin: '970433', shortName: 'VBA'),
    BankInfo(id: '970419', name: 'NCB', bin: '970419', shortName: 'NCB'),
    BankInfo(id: '546034', name: 'Cake', bin: '546034', shortName: 'CAKE'),
    BankInfo(id: '963388', name: 'Timo', bin: '963388', shortName: 'TIMO'),
    BankInfo(
        id: '971005', name: 'Viettel Money', bin: '971005', shortName: 'VTP'),
    BankInfo(id: '971011', name: 'VNPay', bin: '971011', shortName: 'VNP'),
  ];

  static List<BankInfo> getBanks() => popularBanks;

  static String generateQRUrl({
    required String bankBin,
    required String accountNo,
    required double amount,
    required String info,
  }) {
    // Official VietQR format via vietqr.io
    final cleanInfo = Uri.encodeComponent(info);
    return 'https://img.vietqr.io/image/$bankBin-$accountNo-compact2.png?amount=${amount.toInt()}&addInfo=$cleanInfo';
  }

  static String generateDeepLink({
    required String bankBin,
    required String accountNo,
    required double amount,
    required String info,
  }) {
    // Official NAPAS format that triggers bank apps
    final cleanInfo = Uri.encodeComponent(info);
    return 'https://qr.napas.vn/qr?bank=$bankBin&acc=$accountNo&amount=${amount.toInt()}&info=$cleanInfo';
  }

  static String _f(String tag, String value) =>
      '$tag${value.length.toString().padLeft(2, '0')}$value';

  static String generateRawVietQR({
    required String bankBin,
    required String accountNo,
    required double amount,
    required String info,
  }) {
    final buffer = StringBuffer();
    
    // Tag 38: Consumer Account Information
    final guid = _f('00', 'A000000727');
    final bankData = '${_f('00', bankBin)}${_f('01', accountNo)}';
    final tag38Content = '$guid${_f('01', bankData)}${_f('02', 'QRIBFT00')}';
    final tag38 = _f('38', tag38Content);

    buffer.write(_f('00', '01')); // Version
    buffer.write(_f('01', '11')); // Static
    buffer.write(tag38);
    buffer.write(_f('53', '704'));
    buffer.write(_f('54', amount.toInt().toString()));
    buffer.write(_f('58', 'VN'));
    buffer.write(_f('62', _f('08', removeDiacritics(info))));
    buffer.write('6304');

    final raw = buffer.toString();

    // Fast CRC16-CCITT implementation
    int crc = 0xFFFF;
    for (int i = 0; i < raw.length; i++) {
      crc ^= (raw.codeUnitAt(i) << 8);
      for (int j = 0; j < 8; j++) {
        crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : (crc << 1);
      }
    }
    
    final crcStr = (crc & 0xFFFF).toRadixString(16).toUpperCase().padLeft(4, '0');
    return '${raw.substring(0, raw.length - 4)}${_f('63', crcStr)}';
  }

  static Future<void> openBankApp(BuildContext context, String rawVietQR, 
      {String? accountNo, String? bankBin, double? amount, String? memo}) async {
    try {
      // 1. DATA PREP: Ensure account is copied first (highest reliability)
      if (accountNo != null) {
        await Clipboard.setData(ClipboardData(text: accountNo));
      }
      
      if (!context.mounted) return;
      final s = AppStrings.of(context);
      
      // 2. TARGETED LAUNCH ONLY
      if (bankBin != null && bankSchemes.containsKey(bankBin)) {
        final List<String> targetedSchemes = [];
        final bases = bankSchemes[bankBin]!.split('|');
        
        for (var base in bases) {
          // Data-enriched deep-links first
          if (rawVietQR.isNotEmpty) {
            final encoded = Uri.encodeComponent(rawVietQR);
            final String dataLink;
            
            // 1. SPECIFIC OVERRIDES (For banks with non-standard patterns)
            if (base.contains('vcb.vn') || base.contains('vietcombank')) {
              dataLink = 'vietcombank://vcb.vn?qrcode=$encoded';
            } else if (base.contains('bidv')) {
              dataLink = 'bidvsmartbanking://qr?data=$encoded';
            } 
            // 2. GENERAL PATTERN (Works for most standard apps: MB, TCB, VPB, etc.)
            else {
              // Most apps use scheme://qr?data=...
              dataLink = base.replaceFirst('://', '://qr?data=$encoded');
            }
            
            targetedSchemes.add(dataLink);
            
            // 3. EXTRA TCB OVERRIDES (Techcombank is particularly finicky)
            if (base.contains('tcb') || base.contains('techcombank')) {
              // Try without the 'qr' path
              targetedSchemes.add(base.replaceFirst('://', '://?data=$encoded'));
              // Try with 'scan' path
              targetedSchemes.add(base.replaceFirst('://', '://scan?data=$encoded'));
            }
          }
          targetedSchemes.add(base); // Base scheme fallback (just open the app)
        }

        // 4. NAPAS UNIVERSAL LINK (Very high success rate as a fallback)
        final napasLink = generateDeepLink(
          bankBin: bankBin, 
          accountNo: accountNo ?? '', 
          amount: amount ?? 0, 
          info: memo ?? ''
        );
        targetedSchemes.add(napasLink);

        for (var scheme in targetedSchemes) {
          try {
            final uri = Uri.parse(scheme);
            if (await canLaunchUrl(uri)) {
              if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                if (context.mounted) _showSuccessToast(context, s.copyAccAndOpeningApp);
                return;
              }
            }
          } catch (_) {}
        }
      }

      // 3. FALLBACK: If specific app was not found, show manual toast
      if (context.mounted) {
        _showSuccessToast(context, s.copyAccPleaseOpenBankApp);
      }

    } catch (e) {
      if (context.mounted) {
        final s = AppStrings.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${s.error}: $e')));
      }
    }
  }

  static void _showSuccessToast(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.deepPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static BankInfo? getBankByBin(String? bin) {
    if (bin == null) return null;
    try {
      return popularBanks.firstWhere((b) => b.bin == bin);
    } catch (_) {
      return null;
    }
  }

  static final Map<String, String> _diacriticsMap = {
    'àáạảãâầấậẩẫăằắặẳẵ': 'a',
    'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ': 'A',
    'èéẹẻẽêềếệểễ': 'e',
    'ÈÉẸẺẼÊỀẾỆỂỄ': 'E',
    'òóọỏõôồốộổỗơờớợởỡ': 'o',
    'ÒÓỌỎÕÔỒỐỘỔỐƠỜỚỢỞỠ': 'O',
    'ùúụủũưừứựửữ': 'u',
    'ÙÚỤỦŨƯỪỨỰỬỮ': 'U',
    'ìíịỉĩ': 'i',
    'ÌÍỊỈĨ': 'I',
    'đ': 'd',
    'Đ': 'D',
    'ỳýỵỷỹ': 'y',
    'ỲÝỴỶỸ': 'Y',
  };

  static String removeDiacritics(String str) {
    String result = str;
    _diacriticsMap.forEach((key, value) {
      for (int i = 0; i < key.length; i++) {
        result = result.replaceAll(key[i], value);
      }
    });
    return result;
  }
}
