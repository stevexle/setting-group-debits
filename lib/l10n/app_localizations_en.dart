// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Group Debt Settler';

  @override
  String get members => 'Members';

  @override
  String get addMember => 'Add';

  @override
  String get history => 'Expense History';

  @override
  String get settlement => 'Settle Up';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get deleteAll => 'Delete All';

  @override
  String get confirmDelete => 'Delete everything?';

  @override
  String get confirmDeleteMsg =>
      'This will delete all members and transactions.';

  @override
  String get deleteMember => 'Delete member?';

  @override
  String get deleteMemberMsg =>
      'All related transactions will also be deleted.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get add => 'Add';

  @override
  String get confirm => 'Confirm';

  @override
  String get noMembers => 'No members yet';

  @override
  String get noMembersSubtitle => 'Add friends to start splitting';

  @override
  String get noExpenses => 'No expenses yet';

  @override
  String get noExpensesSubtitle => 'Tap + to add your first expense!';

  @override
  String get allSettled => 'All settled up! 🎉';

  @override
  String get allSettledSubtitle => 'No outstanding debts';

  @override
  String get greedyAlgo => 'Greedy Algorithm';

  @override
  String get greedySubtitle => 'Minimizes number of transactions';

  @override
  String get transactions => 'transactions';

  @override
  String get times => 'transfers';

  @override
  String get payer => 'Paid by';

  @override
  String get participants => 'Split with';

  @override
  String get people => 'people';

  @override
  String get enterName => 'Enter name...';

  @override
  String get addMemberTitle => 'Add Member';

  @override
  String get addExpenseTitle => 'Add New Expense';

  @override
  String get description => 'Description (e.g. Team lunch)';

  @override
  String get amount => 'Amount (₫)';

  @override
  String get whoPays => 'Who paid?';

  @override
  String get whoSplits => 'Split bill with?';

  @override
  String get done => 'Done';

  @override
  String get settlementTitle => 'Settlement Plan';

  @override
  String get totalMembers => 'Members';

  @override
  String get totalTransactions => 'Expenses';

  @override
  String get totalSpent => 'Total';

  @override
  String get enterDescription => 'Please enter a description';

  @override
  String get enterAmount => 'Please enter an amount';

  @override
  String get invalidAmount => 'Invalid amount';
}
