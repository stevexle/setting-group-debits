import 'package:flutter/material.dart';
import '../models.dart';

class AppStrings {
  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return locale == 'vi' ? _vi : _en;
  }

  static const _vi = AppStrings._(
    appTitle: 'BillShare',
    members: 'Thành viên',
    addMember: 'Thêm',
    history: 'Lịch sử chi tiêu',
    tabBill: 'Hạch toán',
    tabPay: 'Chi tiêu',
    settlement: 'Quyết toán',
    addExpense: 'Thêm chi tiêu',
    addTransaction: 'Thêm giao dịch',
    today: 'Hôm nay',
    yesterday: 'Hôm qua',
    deleteAll: 'Xóa tất cả',
    confirmDelete: 'Xóa toàn bộ?',
    confirmDeleteMsg: 'Hành động này sẽ xóa tất cả thành viên và giao dịch.',
    deleteMember: 'Xóa thành viên?',
    deleteMemberMsg: 'Không thể xóa thành viên đã tham gia vào giao dịch. Hãy xóa các giao dịch liên quan trước.',
    cancel: 'Hủy',
    delete: 'Xóa',
    add: 'Thêm',
    edit: 'Sửa',
    save: 'Lưu',
    noMembers: 'Chưa có thành viên',
    noMembersSubtitle: 'Hãy thêm bạn bè để bắt đầu chia sẻ chi phí',
    noExpenses: 'Chưa có chi tiêu',
    noExpensesSubtitle: 'Nhấn + để thêm giao dịch đầu tiên!',
    allSettled: 'Đã hoàn thành trả nợ! 🎉',
    allSettledSubtitle: 'Mọi người đã thanh toán hết nợ',
    greedyAlgo: 'Thanh toán Thông minh',
    greedySubtitle: 'Tối ưu hóa số lần chuyển khoản',
    times: 'lượt chuyển',
    paidBy: 'Người chi',
    people: 'người',
    enterName: 'Nhập tên...',
    addMemberTitle: 'Thêm Thành Viên',
    addExpenseTitle: 'Thêm Chi Tiêu Mới',
    addTransactionTitle: 'Thêm Giao Dịch Mới',
    editExpenseTitle: 'Sửa Chi Tiêu',
    deleteExpense: 'Xóa chi tiêu?',
    deleteExpenseMsg: 'Bạn có chắc chắn muốn xóa chi tiêu này?',
    descriptionHint: 'Nội dung (vD: Ăn trưa)',
    amountHint: 'Số tiền (₫)',
    whoPays: 'Ai đã chi?',
    whoSplits: 'Chia cho ai?',
    done: 'Xong',
    settlementTitle: 'Phương Án Quyết Toán',
    totalMembers: 'Thành viên',
    totalExpenses: 'Giao dịch',
    totalSpent: 'Tổng chi',
    totalPaid: 'Đã chi',
    yourShare: 'Phần chia',
    weeklyTotalLabel: 'Tuần này',
    monthlyTotalLabel: 'Tháng này',
    thisWeek: 'Tuần này',
    thisMonth: 'Tháng này',
    weeklyTotal: 'Tổng tuần',
    monthlyTotal: 'Tổng tháng',
    enterDescription: 'Vui lòng nhập nội dung',
    enterAmount: 'Vui lòng nhập số tiền',
    invalidAmount: 'Số tiền không hợp lệ',
    longPressHint: 'Nhấn giữ hoặc vuốt để sửa/xóa',
    dateTime: 'Ngày & Giờ',
    settleNow: 'Đã trả',
    sharePlan: 'Chia sẻ phương án',
    settleDone: 'Đã ghi nhận hạch toán!',
    category: 'Danh mục',
    categoryFood: 'Ăn uống',
    categoryDrink: 'Cà phê',
    categoryShopping: 'Mua sắm',
    categoryTransport: 'Di chuyển',
    categoryEntertainment: 'Giải trí',
    categoryHome: 'Sinh hoạt',
    categoryHealth: 'Sức khỏe',
    categoryTravel: 'Du lịch',
    categoryGrocery: 'Đi chợ',
    categoryBills: 'Hóa đơn',
    categoryEducation: 'Học tập',
    categoryOther: 'Khác',
    lockHistory: 'Xóa hạch toán trước khi sửa/xóa giao dịch này.',
    myGroups: 'Nhóm của tôi',
    addGroup: 'Thêm Nhóm',
    newGroupName: 'Tên nhóm mới',
    editName: 'Đổi tên',
    manageGroups: 'Quản lý nhóm',
    groupMembers: 'Thành viên',
    groupTransactions: 'Giao dịch',
    deleteGroupConfirm: 'Xóa nhóm?',
    deleteGroupMsg: 'Hành động này sẽ xóa vĩnh viễn nhóm và dữ liệu liên quan.',
    adminGroups: 'Quản lý Nhóm',
    switchedTo: 'Đã chuyển sang',
    splitEqual: 'Chia đều',
    splitCustom: 'Tùy chỉnh',
    totalMismatch: 'Tổng tiền không khớp!',
    remainingBalance: 'Còn lại',
    amountMismatch: 'Chênh lệch',
    receivingFrom: 'Nhận từ',
    settlingTo: 'Gửi đến',
    options: 'Tùy chọn',
    viewDetails: 'Xem chi tiết',
    editPermissionDenied: 'Chỉ người tạo mới có quyền sửa giao dịch này.',
    cannotEditConfirmed: 'Giao dịch đã xác nhận không thể sửa.',
    cannotEditHachToan: 'Giao dịch đã hạch toán vào ví không thể sửa.',
    cannotEditSettled: 'Giao dịch trước đợt thanh toán đã chốt sổ.',
    recordToWallet: 'Hạch toán vào ví của tôi',
    recordedTo: 'Đã hạch toán vào: ',
    edited: 'ĐÃ SỬA',
    editedAt: 'Sửa lúc',
    logout: 'Đăng xuất',
    oweLabel: 'Cần trả',
    clearHistory: 'Xóa',
    clearHistoryMsg: 'Hành động này sẽ CHỈ xóa lịch sử giao dịch. Danh sách thành viên sẽ được giữ nguyên.',
    resetGroup: 'Reset',
    resetGroupMsg: 'Hành động này sẽ xóa TOÀN BỘ thành viên và giao dịch. Bạn sẽ cần thêm lại thành viên từ đầu.',
    cannotClear: 'Chưa thể xóa',
    completeSettlementFirst: 'Bạn cần hoàn thành trả nợ (Balanced) hoặc chưa bắt đầu hạch toán mới có thể xóa lịch sử.',
    understood: 'Đã hiểu',
    inviteCode: 'Mã mời',
    joinGroup: 'Tham gia nhóm',
    createGroup: 'Tạo nhóm mới',
    loginGoogle: 'Đăng nhập với Google',
    welcome: 'Chào mừng!',
    welcomeSubtitle: 'Quản lý nợ nhóm dễ dàng và minh bạch hơn bao giờ hết.',
    groupResetSuccess: 'Đã reset nhóm thành công.',
    historyClearedSuccess: 'Đã xóa lịch sử giao dịch. Thành viên được giữ nguyên.',
    joinOrCreate: 'GIA NHẬP HOẶC TẠO MỚI',
    inviteCodeHint: 'Mã mời',
    join: 'Tham gia',
    failedToJoin: 'Không thể gia nhập: Mã không hợp lệ',
    noGroupsYet: 'Bạn chưa có nhóm nào.',
    membersCount: 'thành viên',
    codeCopied: 'Đã sao chép mã!',
    newGroup: 'Nhóm mới',
    groupNameHint: 'Ví dụ: Đi chơi Đà Lạt',
    create: 'Tạo',
    leaveGroupConfirm: 'Rời nhóm?',
    leaveGroupMsg: 'Bạn có chắc chắn muốn rời khỏi nhóm "{name}"?',
    cannotDeleteLastGroup: 'Không thể xóa nhóm cuối cùng.',
    selectPlan: 'Chọn kế hoạch',
    none: 'Không chọn',
    outstandingDebtsError: 'Nhóm này vẫn còn nợ chưa trả. Hãy hoàn tất hạch toán trước khi xóa nhóm.',
    deleteGroupTitle: 'Xóa nhóm?',
    deleteGroupConfirmMsg: 'Bạn có chắc chắn muốn xóa nhóm "{name}"? Hành động này không thể hoàn tác.',
    remindedUser: 'Đã nhắc nhở {name}',
    cannotDeleteSelf: 'Bạn không thể tự xóa chính mình khỏi nhóm.',
    walletTitle: 'Ví của tôi',
    accountsLabel: 'Tài khoản & Ví',
    planningTitle: 'Lập kế hoạch',
    addAccount: 'Thêm tài khoản',
    addPlan: 'Tạo kế hoạch',
    totalNetWorth: 'Tổng tài sản',
    totalNetWorthLabel: 'TỔNG TÀI SẢN RÒNG',
    addAccountTitle: 'Thêm Tài Khoản Mới',
    editAccountTitle: 'Chỉnh sửa tài khoản',
    accountNameHint: 'Tên tài khoản (vD: VCB, MoMo, Tiền mặt)',
    initialBalanceHint: 'Số dư hiện tại (₫)',
    accountTypeLabel: 'LOẠI TÀI KHOẢN',
    saveAccount: 'Lưu Tài Khoản',
    historyLabel: 'BIẾN ĐỘNG SỐ DƯ',
    currentBalanceLabel: 'SỐ DƯ HIỆN TẠI',
    noHistoryForAccount: 'Chưa có biến động số dư cho tài khoản này.',
    addPlanTitle: 'Lập Kế Hoạch Mới',
    planTitleHint: 'Tên kế hoạch (vD: Du lịch Đà Lạt, Mua ô tô)',
    budgetHint: 'Tổng dự trù ngân sách (₫)',
    linksHint: 'Link TikTok/Facebook (Cách nhau bằng dấu phẩy)',
    planTypeLabel: 'LOẠI DỰ ÁN',
    savePlan: 'Lưu Kế Hoạch',
    navBillShare: 'BillShare',
    navGroups: 'Nhóm',
    navWallet: 'Ví của tôi',
    navPlanning: 'Lập kế hoạch',
    navAnalysis: 'Phân tích',
    navLedger: 'Thu Chi',
    tabMovement: 'Biến động',
    tabAnalysis: 'Phân tích',
    incomeLabel: 'THU NHẬP',
    expenseLabel: 'CHI TIÊU',
    netBalanceLabel: 'Số dư ròng: ',
    categoryBreakdown: 'CHI TIÊU THEO DANH MỤC',
    inPlan: 'Trong kế hoạch',
    outPlan: 'Ngoài kế hoạch',
    noCashFlow: 'Chưa có dũ liệu dòng tiền. Mọi chi tiêu sẽ hiện ở đây!',
    groupTypeSettlement: 'Chia tiền',
    groupTypePlanning: 'Kế hoạch/Du lịch',
    groupTypeLabel: 'LOẠI NHÓM',
    noPlansMsg: 'Bạn chưa có kế hoạch nào. Hãy lập kế hoạch cho chuyến đi hoặc sự kiện sắp tới!',
    estimatedBudget: 'DỰ TRÙ',
    actualSpent: 'THỰC CHI',
    tripLabel: 'DU LỊCH',
    viewWallet: 'XEM VÍ',
    budgetProgress: 'TIẾN ĐỘ NGÂN SÁCH',
    referencesLabel: 'THAM KHẢO (TIKTOK/FB)',
    planExpensesLabel: 'CHI TIÊU CHO KẾ HOẠCH',
    noExpensesForPlan: 'Chưa có khoản chi nào cho kế hoạch này.',
    linkReview: 'Link review',
    planTypeTrip: 'Du lịch',
    planTypeEvent: 'Sự kiện',
    planTypeLiving: 'Sinh hoạt',
    planTypeOther: 'Khác',
    analysisOverview: 'BÁO CÁO TỔNG QUAN',
    planningOverview: 'QUẢN LÝ KẾ HOẠCH',
    vcbScan: 'Quét QR VCB',
    vcbScanHint: 'Tự động nhập từ mã QR ngân hàng',
    insufficientBalance: 'Số dư không đủ',
    insufficientBalanceMsg: 'Số tiền chi vượt quá số dư hiện tại của ví',
    continueAnyway: 'Bạn vẫn muốn tiếp tục?',
    proceed: 'Tiếp tục',
    chooseAction: 'Chọn hành động',
    deletedExpense: 'Đã xóa giao dịch',
    pleaseCreateGroup: 'Vui lòng tạo nhóm để bắt đầu sử dụng BillShare',
    needsConfirmation: 'Cần xác nhận',
    waitingForYou: 'Đang chờ bạn xác nhận',
    waitingForRecipient: 'Đang chờ người nhận...',
    reject: 'Từ chối',
    confirmBalance: 'Xác nhận',
    selectAccountIn: 'Chọn tài khoản nhận tiền',
    confirmWithoutAccount: 'Xác nhận (không vào ví)',
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
    addTransaction: 'Add Transaction',
    today: 'Today',
    yesterday: 'Yesterday',
    deleteAll: 'Delete All',
    confirmDelete: 'Delete everything?',
    confirmDeleteMsg: 'This will delete all members and transactions.',
    deleteMember: 'Delete member?',
    deleteMemberMsg: 'Cannot delete member with transaction history. Please clear or modify related transactions first.',
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
    addTransactionTitle: 'Add New Transaction',
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
    weeklyTotal: 'Weekly Total',
    monthlyTotal: 'Monthly Total',
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
    categoryTravel: 'Travel',
    categoryGrocery: 'Grocery',
    categoryBills: 'Bills',
    categoryEducation: 'Education',
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
    receivingFrom: 'Received from',
    settlingTo: 'Settled to',
    options: 'Options',
    viewDetails: 'View Details',
    editPermissionDenied: 'Only the creator can edit this transaction.',
    cannotEditConfirmed: 'Confirmed transactions cannot be edited.',
    cannotEditHachToan: 'Recorded transactions in wallet cannot be edited.',
    cannotEditSettled: 'Transactions before the last payment are locked.',
    recordToWallet: 'Record to my wallet',
    recordedTo: 'Recorded to: ',
    edited: 'EDITED',
    editedAt: 'Edited at',
    logout: 'Logout',
    oweLabel: 'Owes',
    clearHistory: 'Clear',
    clearHistoryMsg: 'This will ONLY delete the transaction history. Group members will be kept.',
    resetGroup: 'Reset',
    resetGroupMsg: 'This will delete ALL members and ALL transactions. You will need to add members again.',
    cannotClear: 'Cannot Clear',
    completeSettlementFirst: 'Please complete all repayments (Balanced) or ensure no settlement started before clearing.',
    understood: 'Got it',
    inviteCode: 'Invite Code',
    joinGroup: 'Join Group',
    createGroup: 'Create Group',
    loginGoogle: 'Sign in with Google',
    welcome: 'Welcome!',
    welcomeSubtitle: 'Manage group debts easily and transparently.',
    groupResetSuccess: 'Group reset successfully.',
    historyClearedSuccess: 'Transaction history cleared. Members kept.',
    joinOrCreate: 'JOIN OR CREATE',
    inviteCodeHint: 'Invite Code',
    join: 'Join',
    failedToJoin: 'Failed to join: Invalid ID',
    noGroupsYet: 'You have no groups yet.',
    membersCount: 'members',
    codeCopied: 'Code copied!',
    newGroup: 'New Group',
    groupNameHint: 'e.g. Travel',
    create: 'Create',
    leaveGroupConfirm: 'Leave group?',
    leaveGroupMsg: 'Are you sure you want to leave "{name}"?',
    cannotDeleteLastGroup: 'Cannot delete the last group.',
    selectPlan: 'Select plan',
    none: 'None',
    outstandingDebtsError: 'This group has outstanding debts. Please settle all expenses before deleting.',
    deleteGroupTitle: 'Delete Group?',
    deleteGroupConfirmMsg: 'Are you sure you want to delete "{name}"? This action cannot be undone.',
    remindedUser: 'Reminded {name}',
    cannotDeleteSelf: 'You cannot remove yourself from the group.',
    walletTitle: 'My Wallet',
    accountsLabel: 'Accounts & Wallets',
    planningTitle: 'Planning Hub',
    addAccount: 'Add Account',
    addPlan: 'Create Plan',
    totalNetWorth: 'Total Net Worth',
    totalNetWorthLabel: 'TOTAL NET WORTH',
    addAccountTitle: 'Add New Account',
    editAccountTitle: 'Edit Account',
    accountNameHint: 'Account name (e.g. VCB, Cash)',
    initialBalanceHint: 'Current balance (₫)',
    accountTypeLabel: 'ACCOUNT TYPE',
    saveAccount: 'Save Account',
    historyLabel: 'TRANSACTION HISTORY',
    currentBalanceLabel: 'CURRENT BALANCE',
    noHistoryForAccount: 'No transaction history for this account.',
    addPlanTitle: 'Create New Plan',
    planTitleHint: 'Plan title (e.g. Vacation, Car)',
    budgetHint: 'Total budget (₫)',
    linksHint: 'Reference links (comma separated)',
    planTypeLabel: 'PLAN TYPE',
    savePlan: 'Save Plan',
    navBillShare: 'BILLSHARE',
    navGroups: 'GROUPS',
    navWallet: 'MY WALLET',
    navPlanning: 'PLANNING',
    navAnalysis: 'Analysis',
    navLedger: 'Ledger',
    tabMovement: 'Movement',
    tabAnalysis: 'Analysis',
    incomeLabel: 'INCOME',
    expenseLabel: 'EXPENSE',
    netBalanceLabel: 'Net Balance: ',
    categoryBreakdown: 'CATEGORY BREAKDOWN',
    inPlan: 'In Plan',
    outPlan: 'Out of Plan',
    noCashFlow: 'No cash flow data yet. All transactions will appear here!',
    groupTypeSettlement: 'Settlement',
    groupTypePlanning: 'Planning/Trip',
    groupTypeLabel: 'GROUP TYPE',
    noPlansMsg: 'You have no plans yet. Let\'s plan for your next trip or event!',
    estimatedBudget: 'ESTIMATED',
    actualSpent: 'ACTUAL',
    tripLabel: 'TRIP',
    viewWallet: 'VIEW WALLET',
    budgetProgress: 'BUDGET PROGRESS',
    referencesLabel: 'REFERENCES (TIKTOK/FB)',
    planExpensesLabel: 'PLAN EXPENSES',
    noExpensesForPlan: 'No expenses for this plan yet.',
    linkReview: 'Link review',
    planTypeTrip: 'Trip',
    planTypeEvent: 'Event',
    planTypeLiving: 'Living',
    planTypeOther: 'Other',
    analysisOverview: 'OVERVIEW REPORT',
    planningOverview: 'PLAN MANAGEMENT',
    vcbScan: 'VCB QR Scan',
    vcbScanHint: 'Auto-fill from banking QR code',
    insufficientBalance: 'Insufficient Balance',
    insufficientBalanceMsg: 'The expense amount exceeds the current wallet balance',
    continueAnyway: 'Do you still want to proceed?',
    proceed: 'Proceed',
    chooseAction: 'Choose action',
    deletedExpense: 'Deleted transaction',
    pleaseCreateGroup: 'Please create a group to start using BillShare',
    needsConfirmation: 'Needs Confirmation',
    waitingForYou: 'Waiting for your confirmation',
    waitingForRecipient: 'Waiting for recipient...',
    reject: 'Reject',
    confirmBalance: 'Confirm',
    selectAccountIn: 'Select income account',
    confirmWithoutAccount: 'Confirm (no wallet)',
  );

  final String appTitle;
  final String members;
  final String addMember;
  final String history;
  final String tabBill;
  final String tabPay;
  final String settlement;
  final String addExpense;
  final String addTransaction;
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
  final String addTransactionTitle;
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
  final String weeklyTotal;
  final String monthlyTotal;
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
  final String categoryTravel;
  final String categoryGrocery;
  final String categoryBills;
  final String categoryEducation;
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
  final String receivingFrom;
  final String settlingTo;
  final String options;
  final String viewDetails;
  final String editPermissionDenied;
  final String cannotEditConfirmed;
  final String cannotEditHachToan;
  final String cannotEditSettled;
  final String recordToWallet;
  final String recordedTo;
  final String edited;
  final String editedAt;
  final String logout;
  final String oweLabel;
  final String clearHistory;
  final String clearHistoryMsg;
  final String resetGroup;
  final String resetGroupMsg;
  final String cannotClear;
  final String completeSettlementFirst;
  final String understood;
  final String inviteCode;
  final String joinGroup;
  final String createGroup;
  final String loginGoogle;
  final String welcome;
  final String welcomeSubtitle;
  final String groupResetSuccess;
  final String historyClearedSuccess;
  final String joinOrCreate;
  final String inviteCodeHint;
  final String join;
  final String failedToJoin;
  final String noGroupsYet;
  final String membersCount;
  final String codeCopied;
  final String newGroup;
  final String groupNameHint;
  final String create;
  final String leaveGroupConfirm;
  final String leaveGroupMsg;
  final String cannotDeleteLastGroup;
  final String selectPlan;
  final String none;
  final String outstandingDebtsError;
  final String deleteGroupTitle;
  final String deleteGroupConfirmMsg;
  final String remindedUser;
  final String cannotDeleteSelf;
  final String walletTitle;
  final String accountsLabel;
  final String planningTitle;
  final String addAccount;
  final String addPlan;
  final String totalNetWorth;
  final String totalNetWorthLabel;
  final String addAccountTitle;
  final String editAccountTitle;
  final String accountNameHint;
  final String initialBalanceHint;
  final String accountTypeLabel;
  final String saveAccount;
  final String historyLabel;
  final String currentBalanceLabel;
  final String noHistoryForAccount;
  final String addPlanTitle;
  final String planTitleHint;
  final String budgetHint;
  final String linksHint;
  final String planTypeLabel;
  final String savePlan;
  final String navBillShare;
  final String navGroups;
  final String navWallet;
  final String navPlanning;
  final String navAnalysis;
  final String navLedger;
  final String tabMovement;
  final String tabAnalysis;
  final String incomeLabel;
  final String expenseLabel;
  final String netBalanceLabel;
  final String categoryBreakdown;
  final String inPlan;
  final String outPlan;
  final String noCashFlow;
  final String groupTypeSettlement;
  final String groupTypePlanning;
  final String groupTypeLabel;
  final String noPlansMsg;
  final String estimatedBudget;
  final String actualSpent;
  final String tripLabel;
  final String viewWallet;
  final String budgetProgress;
  final String referencesLabel;
  final String planExpensesLabel;
  final String noExpensesForPlan;
  final String linkReview;
  final String planTypeTrip;
  final String planTypeEvent;
  final String planTypeLiving;
  final String planTypeOther;
  final String analysisOverview;
  final String planningOverview;
  final String vcbScan;
  final String vcbScanHint;
  final String insufficientBalance;
  final String insufficientBalanceMsg;
  final String continueAnyway;
  final String proceed;
  final String chooseAction;
  final String deletedExpense;
  final String pleaseCreateGroup;
  final String needsConfirmation;
  final String waitingForYou;
  final String waitingForRecipient;
  final String reject;
  final String confirmBalance;
  final String selectAccountIn;
  final String confirmWithoutAccount;

  const AppStrings._({
    required this.appTitle,
    required this.members,
    required this.addMember,
    required this.history,
    required this.tabBill,
    required this.tabPay,
    required this.settlement,
    required this.addExpense,
    required this.addTransaction,
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
    required this.addTransactionTitle,
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
    required this.weeklyTotal,
    required this.monthlyTotal,
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
    required this.categoryTravel,
    required this.categoryGrocery,
    required this.categoryBills,
    required this.categoryEducation,
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
    required this.receivingFrom,
    required this.settlingTo,
    required this.options,
    required this.viewDetails,
    required this.editPermissionDenied,
    required this.cannotEditConfirmed,
    required this.cannotEditHachToan,
    required this.cannotEditSettled,
    required this.recordToWallet,
    required this.recordedTo,
    required this.edited,
    required this.editedAt,
    required this.logout,
    required this.oweLabel,
    required this.clearHistory,
    required this.clearHistoryMsg,
    required this.resetGroup,
    required this.resetGroupMsg,
    required this.cannotClear,
    required this.completeSettlementFirst,
    required this.understood,
    required this.inviteCode,
    required this.joinGroup,
    required this.createGroup,
    required this.loginGoogle,
    required this.welcome,
    required this.welcomeSubtitle,
    required this.groupResetSuccess,
    required this.historyClearedSuccess,
    required this.joinOrCreate,
    required this.inviteCodeHint,
    required this.join,
    required this.failedToJoin,
    required this.noGroupsYet,
    required this.membersCount,
    required this.codeCopied,
    required this.newGroup,
    required this.groupNameHint,
    required this.create,
    required this.leaveGroupConfirm,
    required this.leaveGroupMsg,
    required this.cannotDeleteLastGroup,
    required this.selectPlan,
    required this.none,
    required this.outstandingDebtsError,
    required this.deleteGroupTitle,
    required this.deleteGroupConfirmMsg,
    required this.remindedUser,
    required this.cannotDeleteSelf,
    required this.walletTitle,
    required this.accountsLabel,
    required this.planningTitle,
    required this.addAccount,
    required this.addPlan,
    required this.totalNetWorth,
    required this.totalNetWorthLabel,
    required this.addAccountTitle,
    required this.editAccountTitle,
    required this.accountNameHint,
    required this.initialBalanceHint,
    required this.accountTypeLabel,
    required this.saveAccount,
    required this.historyLabel,
    required this.currentBalanceLabel,
    required this.noHistoryForAccount,
    required this.addPlanTitle,
    required this.planTitleHint,
    required this.budgetHint,
    required this.linksHint,
    required this.planTypeLabel,
    required this.savePlan,
    required this.navBillShare,
    required this.navGroups,
    required this.navWallet,
    required this.navPlanning,
    required this.navAnalysis,
    required this.navLedger,
    required this.tabMovement,
    required this.tabAnalysis,
    required this.incomeLabel,
    required this.expenseLabel,
    required this.netBalanceLabel,
    required this.categoryBreakdown,
    required this.inPlan,
    required this.outPlan,
    required this.noCashFlow,
    required this.groupTypeSettlement,
    required this.groupTypePlanning,
    required this.groupTypeLabel,
    required this.noPlansMsg,
    required this.estimatedBudget,
    required this.actualSpent,
    required this.tripLabel,
    required this.viewWallet,
    required this.budgetProgress,
    required this.referencesLabel,
    required this.planExpensesLabel,
    required this.noExpensesForPlan,
    required this.linkReview,
    required this.planTypeTrip,
    required this.planTypeEvent,
    required this.planTypeLiving,
    required this.planTypeOther,
    required this.analysisOverview,
    required this.planningOverview,
    required this.vcbScan,
    required this.vcbScanHint,
    required this.insufficientBalance,
    required this.insufficientBalanceMsg,
    required this.continueAnyway,
    required this.proceed,
    required this.chooseAction,
    required this.deletedExpense,
    required this.pleaseCreateGroup,
    required this.needsConfirmation,
    required this.waitingForYou,
    required this.waitingForRecipient,
    required this.reject,
    required this.confirmBalance,
    required this.selectAccountIn,
    required this.confirmWithoutAccount,
  });

  String getCategoryName(Category cat) {
    switch (cat) {
      case Category.food:
        return categoryFood;
      case Category.drink:
        return categoryDrink;
      case Category.shopping:
        return categoryShopping;
      case Category.transport:
        return categoryTransport;
      case Category.entertainment:
        return categoryEntertainment;
      case Category.home:
        return categoryHome;
      case Category.health:
        return categoryHealth;
      case Category.travel:
        return categoryTravel;
      case Category.grocery:
        return categoryGrocery;
      case Category.bills:
        return categoryBills;
      case Category.education:
        return categoryEducation;
      case Category.other:
        return categoryOther;
    }
  }

  String getPlanTypeName(PlanType type) {
    switch (type) {
      case PlanType.trip:
        return planTypeTrip;
      case PlanType.event:
        return planTypeEvent;
      case PlanType.living:
        return planTypeLiving;
      case PlanType.other:
        return planTypeOther;
    }
  }

  String getGroupTypeName(GroupType type) {
    switch (type) {
      case GroupType.settlement:
        return groupTypeSettlement;
      case GroupType.planning:
        return groupTypePlanning;
    }
  }
}
