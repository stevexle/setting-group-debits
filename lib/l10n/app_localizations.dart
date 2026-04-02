import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quyết Toán Nhóm'**
  String get appTitle;

  /// No description provided for @members.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get members;

  /// No description provided for @addMember.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get addMember;

  /// No description provided for @history.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử chi tiêu'**
  String get history;

  /// No description provided for @settlement.
  ///
  /// In vi, this message translates to:
  /// **'Quyết toán'**
  String get settlement;

  /// No description provided for @addExpense.
  ///
  /// In vi, this message translates to:
  /// **'Thêm chi tiêu'**
  String get addExpense;

  /// No description provided for @today.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get yesterday;

  /// No description provided for @deleteAll.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tất cả'**
  String get deleteAll;

  /// No description provided for @confirmDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận xóa?'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteMsg.
  ///
  /// In vi, this message translates to:
  /// **'Hành động này sẽ xóa toàn bộ thành viên và giao dịch.'**
  String get confirmDeleteMsg;

  /// No description provided for @deleteMember.
  ///
  /// In vi, this message translates to:
  /// **'Xóa thành viên?'**
  String get deleteMember;

  /// No description provided for @deleteMemberMsg.
  ///
  /// In vi, this message translates to:
  /// **'Sẽ xóa toàn bộ giao dịch liên quan.'**
  String get deleteMemberMsg;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get delete;

  /// No description provided for @add.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get add;

  /// No description provided for @confirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get confirm;

  /// No description provided for @noMembers.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thành viên'**
  String get noMembers;

  /// No description provided for @noMembersSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm bạn bè để bắt đầu chia tiền'**
  String get noMembersSubtitle;

  /// No description provided for @noExpenses.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có chi tiêu'**
  String get noExpenses;

  /// No description provided for @noExpensesSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn + để thêm bữa trà đá đầu tiên!'**
  String get noExpensesSubtitle;

  /// No description provided for @allSettled.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả đã sòng phẳng! 🎉'**
  String get allSettled;

  /// No description provided for @allSettledSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Không có khoản nợ nào cần thanh toán'**
  String get allSettledSubtitle;

  /// No description provided for @greedyAlgo.
  ///
  /// In vi, this message translates to:
  /// **'Thuật toán Greedy'**
  String get greedyAlgo;

  /// No description provided for @greedySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tối ưu hóa số giao dịch ít nhất có thể'**
  String get greedySubtitle;

  /// No description provided for @transactions.
  ///
  /// In vi, this message translates to:
  /// **'giao dịch'**
  String get transactions;

  /// No description provided for @times.
  ///
  /// In vi, this message translates to:
  /// **'lần'**
  String get times;

  /// No description provided for @payer.
  ///
  /// In vi, this message translates to:
  /// **'Người thanh toán'**
  String get payer;

  /// No description provided for @participants.
  ///
  /// In vi, this message translates to:
  /// **'Chia cho'**
  String get participants;

  /// No description provided for @people.
  ///
  /// In vi, this message translates to:
  /// **'người'**
  String get people;

  /// No description provided for @enterName.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên...'**
  String get enterName;

  /// No description provided for @addMemberTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thành viên'**
  String get addMemberTitle;

  /// No description provided for @addExpenseTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm chi tiêu mới'**
  String get addExpenseTitle;

  /// No description provided for @description.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả (ví dụ: Trà đá sáng nay)'**
  String get description;

  /// No description provided for @amount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền (₫)'**
  String get amount;

  /// No description provided for @whoPays.
  ///
  /// In vi, this message translates to:
  /// **'Ai là người thanh toán?'**
  String get whoPays;

  /// No description provided for @whoSplits.
  ///
  /// In vi, this message translates to:
  /// **'Chia tiền cho những ai?'**
  String get whoSplits;

  /// No description provided for @done.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get done;

  /// No description provided for @settlementTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phương án quyết toán'**
  String get settlementTitle;

  /// No description provided for @totalMembers.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get totalMembers;

  /// No description provided for @totalTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch'**
  String get totalTransactions;

  /// No description provided for @totalSpent.
  ///
  /// In vi, this message translates to:
  /// **'Tổng chi'**
  String get totalSpent;

  /// No description provided for @enterDescription.
  ///
  /// In vi, this message translates to:
  /// **'Hãy nhập mô tả'**
  String get enterDescription;

  /// No description provided for @enterAmount.
  ///
  /// In vi, this message translates to:
  /// **'Hãy nhập số tiền'**
  String get enterAmount;

  /// No description provided for @invalidAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền không hợp lệ'**
  String get invalidAmount;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
