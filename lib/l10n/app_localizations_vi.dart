// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Quyết Toán Nhóm';

  @override
  String get members => 'Thành viên';

  @override
  String get addMember => 'Thêm';

  @override
  String get history => 'Lịch sử chi tiêu';

  @override
  String get settlement => 'Quyết toán';

  @override
  String get addExpense => 'Thêm chi tiêu';

  @override
  String get today => 'Hôm nay';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get deleteAll => 'Xóa tất cả';

  @override
  String get confirmDelete => 'Xác nhận xóa?';

  @override
  String get confirmDeleteMsg =>
      'Hành động này sẽ xóa toàn bộ thành viên và giao dịch.';

  @override
  String get deleteMember => 'Xóa thành viên?';

  @override
  String get deleteMemberMsg => 'Sẽ xóa toàn bộ giao dịch liên quan.';

  @override
  String get cancel => 'Huỷ';

  @override
  String get delete => 'Xóa';

  @override
  String get add => 'Thêm';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get noMembers => 'Chưa có thành viên';

  @override
  String get noMembersSubtitle => 'Thêm bạn bè để bắt đầu chia tiền';

  @override
  String get noExpenses => 'Chưa có chi tiêu';

  @override
  String get noExpensesSubtitle => 'Nhấn + để thêm bữa trà đá đầu tiên!';

  @override
  String get allSettled => 'Tất cả đã sòng phẳng! 🎉';

  @override
  String get allSettledSubtitle => 'Không có khoản nợ nào cần thanh toán';

  @override
  String get greedyAlgo => 'Thuật toán Greedy';

  @override
  String get greedySubtitle => 'Tối ưu hóa số giao dịch ít nhất có thể';

  @override
  String get transactions => 'giao dịch';

  @override
  String get times => 'lần';

  @override
  String get payer => 'Người thanh toán';

  @override
  String get participants => 'Chia cho';

  @override
  String get people => 'người';

  @override
  String get enterName => 'Nhập tên...';

  @override
  String get addMemberTitle => 'Thêm thành viên';

  @override
  String get addExpenseTitle => 'Thêm chi tiêu mới';

  @override
  String get description => 'Mô tả (ví dụ: Trà đá sáng nay)';

  @override
  String get amount => 'Số tiền (₫)';

  @override
  String get whoPays => 'Ai là người thanh toán?';

  @override
  String get whoSplits => 'Chia tiền cho những ai?';

  @override
  String get done => 'Xong';

  @override
  String get settlementTitle => 'Phương án quyết toán';

  @override
  String get totalMembers => 'Thành viên';

  @override
  String get totalTransactions => 'Giao dịch';

  @override
  String get totalSpent => 'Tổng chi';

  @override
  String get enterDescription => 'Hãy nhập mô tả';

  @override
  String get enterAmount => 'Hãy nhập số tiền';

  @override
  String get invalidAmount => 'Số tiền không hợp lệ';
}
