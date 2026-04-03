import 'package:flutter/material.dart';
import '../models.dart';

class AppStrings {
  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return locale == 'vi' ? _vi : _en;
  }

  static const _vi = AppStrings._(
    appTitle: 'Chia Tiền Nhóm',
    members: 'Thành viên',
    addMember: 'Thêm',
    history: 'Lịch sử',
    tabBill: 'Quyết toán',
    tabPay: 'Chi tiêu',
    settlement: 'Quyết toán',
    addExpense: 'Thêm chi tiêu',
    today: 'Hôm nay',
    yesterday: 'Hôm qua',
    deleteAll: 'Xóa tất cả',
    confirmDelete: 'Xác nhận xóa?',
    confirmDeleteMsg: 'Hành động này sẽ xóa toàn bộ thành viên và giao dịch.',
    deleteMember: 'Xóa thành viên?',
    deleteMemberMsg: 'Sẽ xóa toàn bộ giao dịch liên quan đến thành viên này.',
    cancel: 'Huỷ',
    delete: 'Xóa',
    add: 'Thêm',
    edit: 'Sửa',
    save: 'Lưu',
    noMembers: 'Chưa có thành viên',
    noMembersSubtitle: 'Thêm bạn bè để bắt đầu chia tiền',
    noExpenses: 'Chưa có chi tiêu',
    noExpensesSubtitle: 'Nhấn + để thêm bữa trà đá đầu tiên!',
    allSettled: 'Tất cả đã sòng phẳng! 🎉',
    allSettledSubtitle: 'Không có khoản nợ nào cần thanh toán',
    greedyAlgo: 'Tối ưu hóa',
    greedySubtitle: 'Gợi ý phương án thanh toán nhanh nhất',
    times: 'lần',
    paidBy: 'Người trả',
    people: 'người',
    enterName: 'Nhập tên...',
    addMemberTitle: 'Thêm thành viên',
    addExpenseTitle: 'Thêm chi tiêu mới',
    editExpenseTitle: 'Chỉnh sửa chi tiêu',
    deleteExpense: 'Xóa chi tiêu?',
    deleteExpenseMsg: 'Bạn có chắc chắn muốn xóa chi tiêu này?',
    descriptionHint: 'Mô tả (ví dụ: Trà đá sáng nay)',
    amountHint: 'Số tiền (₫)',
    whoPays: 'Ai là người thanh toán?',
    whoSplits: 'Chia tiền cho những ai?',
    done: 'Xong',
    settlementTitle: 'Phương án quyết toán',
    totalMembers: 'Thành viên',
    totalExpenses: 'Giao dịch',
    totalSpent: 'Tổng chi',
    totalPaid: 'Đã chi',
    yourShare: 'Phần cần trả',
    weeklyTotalLabel: 'Tuần này',
    monthlyTotalLabel: 'Tháng này',
    thisWeek: 'Tuần này',
    thisMonth: 'Tháng này',
    enterDescription: 'Hãy nhập mô tả',
    enterAmount: 'Hãy nhập số tiền',
    invalidAmount: 'Số tiền không hợp lệ',
    longPressHint: 'Giữ hoặc vuốt để sửa/xóa',
    dateTime: 'Ngày giờ',
    settleNow: 'Đã trả',
    sharePlan: 'Chia sẻ phương án',
    settleDone: 'Đã thanh toán xong!',
    category: 'Danh mục',
    categoryFood: 'Ăn uống',
    categoryDrink: 'Café/Trà đá',
    categoryShopping: 'Mua sắm',
    categoryTransport: 'Di chuyển',
    categoryEntertainment: 'Giải trí',
    categoryHome: 'Sinh hoạt',
    categoryHealth: 'Sức khỏe',
    categoryOther: 'Khác',
    lockHistory: 'Cần xóa các quyết toán trước khi sửa/xóa chi tiêu.',
    myGroups: 'Nhóm của tôi',
    addGroup: 'Thêm nhóm',
    newGroupName: 'Tên nhóm mới',
    editName: 'Sửa tên',
    manageGroups: 'Quản lý nhóm',
    groupMembers: 'Thành viên',
    groupTransactions: 'Giao dịch',
    deleteGroupConfirm: 'Xóa nhóm?',
    deleteGroupMsg: 'Hành động này sẽ xóa vĩnh viễn nhóm và toàn bộ dữ liệu liên quan.',
    adminGroups: 'Quản lý nhóm',
    switchedTo: 'Đã chuyển sang',
    splitEqual: 'Chia đều',
    splitCustom: 'Nhập tay',
    totalMismatch: 'Tổng tiền không khớp!',
    remainingBalance: 'Còn lại',
    amountMismatch: 'Chưa khớp',
    edited: 'CHỈNH SỬA',
    editedAt: 'Sửa lúc',
  );

  static const _en = AppStrings._(
    appTitle: 'BillShare',
    members: 'Members',
    addMember: 'Add',
    history: 'Expense History',
    tabBill: 'Settle',
    tabPay: 'Expenses',
    settlement: 'Settle Up',
    addExpense: 'Add Expense',
    today: 'Today',
    yesterday: 'Yesterday',
    deleteAll: 'Delete All',
    confirmDelete: 'Delete everything?',
    confirmDeleteMsg: 'This will delete all members and transactions.',
    deleteMember: 'Delete member?',
    deleteMemberMsg: 'All related transactions will also be deleted.',
    cancel: 'Cancel',
    delete: 'Delete',
    add: 'Add',
    edit: 'Edit',
    save: 'Save',
    noMembers: 'No members yet',
    noMembersSubtitle: 'Add friends to start splitting',
    noExpenses: 'No expenses yet',
    noExpensesSubtitle: 'Tap + to add your first expense!',
    allSettled: 'All settled up! 🎉',
    allSettledSubtitle: 'No outstanding debts to pay',
    greedyAlgo: 'Smart Repayment',
    greedySubtitle: 'Optimized payment suggestions',
    times: 'transfers',
    paidBy: 'Paid by',
    people: 'people',
    enterName: 'Enter name...',
    addMemberTitle: 'Add Member',
    addExpenseTitle: 'Add New Expense',
    editExpenseTitle: 'Edit Expense',
    deleteExpense: 'Delete expense?',
    deleteExpenseMsg: 'Are you sure you want to delete this expense?',
    descriptionHint: 'Description (e.g. Team lunch)',
    amountHint: 'Amount (₫)',
    whoPays: 'Who paid?',
    whoSplits: 'Split with?',
    done: 'Done',
    settlementTitle: 'Settlement Plan',
    totalMembers: 'Members',
    totalExpenses: 'Expenses',
    totalSpent: 'Total',
    totalPaid: 'Paid',
    yourShare: 'Share',
    weeklyTotalLabel: 'This Week',
    monthlyTotalLabel: 'This Month',
    thisWeek: 'This week',
    thisMonth: 'This month',
    enterDescription: 'Please enter a description',
    enterAmount: 'Please enter an amount',
    invalidAmount: 'Invalid amount',
    longPressHint: 'Hold or swipe to edit/delete',
    dateTime: 'Date & Time',
    settleNow: 'Paid',
    sharePlan: 'Share Plan',
    settleDone: 'Settlement Recorded!',
    category: 'Category',
    categoryFood: 'Food',
    categoryDrink: 'Drink',
    categoryShopping: 'Shopping',
    categoryTransport: 'Transport',
    categoryEntertainment: 'Entertainment',
    categoryHome: 'Home',
    categoryHealth: 'Health',
    categoryOther: 'Other',
    lockHistory: 'Delete settlement records before editing/deleting expenses.',
    myGroups: 'My Groups',
    addGroup: 'Add Group',
    newGroupName: 'New Group Name',
    editName: 'Edit Name',
    manageGroups: 'Manage Groups',
    groupMembers: 'Members',
    groupTransactions: 'Transactions',
    deleteGroupConfirm: 'Delete group?',
    deleteGroupMsg: 'This will permanently delete the group and all its data.',
    adminGroups: 'Manage Groups',
    switchedTo: 'Switched to',
    splitEqual: 'Equal',
    splitCustom: 'Custom',
    totalMismatch: 'Total amount mismatch!',
    remainingBalance: 'Remaining',
    amountMismatch: 'Mismatch',
    edited: 'EDITED',
    editedAt: 'Edited at',
  );

  final String appTitle;
  final String members;
  final String addMember;
  final String history;
  final String tabBill;
  final String tabPay;
  final String settlement;
  final String addExpense;
  final String today;
  final String yesterday;
  final String deleteAll;
  final String confirmDelete;
  final String confirmDeleteMsg;
  final String deleteMember;
  final String deleteMemberMsg;
  final String cancel;
  final String delete;
  final String add;
  final String edit;
  final String save;
  final String noMembers;
  final String noMembersSubtitle;
  final String noExpenses;
  final String noExpensesSubtitle;
  final String allSettled;
  final String allSettledSubtitle;
  final String greedyAlgo;
  final String greedySubtitle;
  final String times;
  final String paidBy;
  final String people;
  final String enterName;
  final String addMemberTitle;
  final String addExpenseTitle;
  final String editExpenseTitle;
  final String deleteExpense;
  final String deleteExpenseMsg;
  final String descriptionHint;
  final String amountHint;
  final String whoPays;
  final String whoSplits;
  final String done;
  final String settlementTitle;
  final String totalMembers;
  final String totalExpenses;
  final String totalSpent;
  final String totalPaid;
  final String yourShare;
  final String weeklyTotalLabel;
  final String monthlyTotalLabel;
  final String thisWeek;
  final String thisMonth;
  final String enterDescription;
  final String enterAmount;
  final String invalidAmount;
  final String longPressHint;
  final String dateTime;
  final String settleNow;
  final String sharePlan;
  final String settleDone;
  final String category;
  final String categoryFood;
  final String categoryDrink;
  final String categoryShopping;
  final String categoryTransport;
  final String categoryEntertainment;
  final String categoryHome;
  final String categoryHealth;
  final String categoryOther;
  final String lockHistory;
  final String myGroups;
  final String addGroup;
  final String newGroupName;
  final String editName;
  final String manageGroups;
  final String groupMembers;
  final String groupTransactions;
  final String deleteGroupConfirm;
  final String deleteGroupMsg;
  final String adminGroups;
  final String switchedTo;
  final String splitEqual;
  final String splitCustom;
  final String totalMismatch;
  final String remainingBalance;
  final String amountMismatch;
  final String edited;
  final String editedAt;

  const AppStrings._({
    required this.appTitle,
    required this.members,
    required this.addMember,
    required this.history,
    required this.tabBill,
    required this.tabPay,
    required this.settlement,
    required this.addExpense,
    required this.today,
    required this.yesterday,
    required this.deleteAll,
    required this.confirmDelete,
    required this.confirmDeleteMsg,
    required this.deleteMember,
    required this.deleteMemberMsg,
    required this.cancel,
    required this.delete,
    required this.add,
    required this.edit,
    required this.save,
    required this.noMembers,
    required this.noMembersSubtitle,
    required this.noExpenses,
    required this.noExpensesSubtitle,
    required this.allSettled,
    required this.allSettledSubtitle,
    required this.greedyAlgo,
    required this.greedySubtitle,
    required this.times,
    required this.paidBy,
    required this.people,
    required this.enterName,
    required this.addMemberTitle,
    required this.addExpenseTitle,
    required this.editExpenseTitle,
    required this.deleteExpense,
    required this.deleteExpenseMsg,
    required this.descriptionHint,
    required this.amountHint,
    required this.whoPays,
    required this.whoSplits,
    required this.done,
    required this.settlementTitle,
    required this.totalMembers,
    required this.totalExpenses,
    required this.totalSpent,
    required this.totalPaid,
    required this.yourShare,
    required this.weeklyTotalLabel,
    required this.monthlyTotalLabel,
    required this.thisWeek,
    required this.thisMonth,
    required this.enterDescription,
    required this.enterAmount,
    required this.invalidAmount,
    required this.longPressHint,
    required this.dateTime,
    required this.settleNow,
    required this.sharePlan,
    required this.settleDone,
    required this.category,
    required this.categoryFood,
    required this.categoryDrink,
    required this.categoryShopping,
    required this.categoryTransport,
    required this.categoryEntertainment,
    required this.categoryHome,
    required this.categoryHealth,
    required this.categoryOther,
    required this.lockHistory,
    required this.myGroups,
    required this.addGroup,
    required this.newGroupName,
    required this.editName,
    required this.manageGroups,
    required this.groupMembers,
    required this.groupTransactions,
    required this.deleteGroupConfirm,
    required this.deleteGroupMsg,
    required this.adminGroups,
    required this.switchedTo,
    required this.splitEqual,
    required this.splitCustom,
    required this.totalMismatch,
    required this.remainingBalance,
    required this.amountMismatch,
    required this.edited,
    required this.editedAt,
  });

  String getCategoryName(Category c) {
    switch (c) {
      case Category.food: return categoryFood;
      case Category.drink: return categoryDrink;
      case Category.shopping: return categoryShopping;
      case Category.transport: return categoryTransport;
      case Category.entertainment: return categoryEntertainment;
      case Category.home: return categoryHome;
      case Category.health: return categoryHealth;
      case Category.other: return categoryOther;
    }
  }
}
