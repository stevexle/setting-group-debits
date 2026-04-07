import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';
import '../../../models.dart';
import '../../../l10n/strings.dart';
import '../../ui_helpers.dart';
import '../../widgets/common_widgets.dart';

class SimpleTransactionModal extends StatefulWidget {
  final PersonalTransaction? initialTransaction;
  const SimpleTransactionModal({super.key, this.initialTransaction});

  @override
  State<SimpleTransactionModal> createState() => _SimpleTransactionModalState();
}

class _SimpleTransactionModalState extends State<SimpleTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late Category _category;
  String? _sourceAccountId;
  String? _planId;
  late bool _isPayment;

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    final tx = widget.initialTransaction;

    final initialAmount = tx?.amount ?? 0;
    _amountController = TextEditingController(
        text: initialAmount > 0
            ? NumberFormat('#,###', 'en_US').format(initialAmount)
            : '');
    _amountController.addListener(() => setState(() {}));

    _descriptionController = TextEditingController(text: tx?.description ?? '');
    _selectedDate = tx?.date ?? DateTime.now();
    _category = tx?.category ?? Category.food;
    _sourceAccountId = tx?.sourceAccountId ??
        (state.accounts.isNotEmpty ? state.accounts.first.id : null);
    _planId = tx?.planId;
    _isPayment = tx?.isPayment ?? false;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double get _totalInputAmount {
    final clean = _amountController.text.replaceAll(RegExp(r'\D'), '');
    return double.tryParse(clean) ?? 0;
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (time == null) return;

    if (!mounted) return;
    setState(() {
      _selectedDate =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E1E2E).withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.75),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, -10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Stack(
                children: [
                  Positioned(
                    top: -100,
                    right: -100,
                    child: AmbientGlow(
                        color: _isPayment ? Colors.green : cs.primary, 
                        size: 250, 
                        opacity: 0.12),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16,
                        MediaQuery.of(context).viewInsets.bottom + 16),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDragHandle(isDark),
                            _buildHeader(s, isDark, cs),
                            const SizedBox(height: 16),
                            _buildDescriptionField(s, isDark, cs),
                            const SizedBox(height: 12),
                            _buildAmountField(s, isDark, cs),
                            const SizedBox(height: 12),
                            _buildDateTimeButton(s, isDark, cs),
                            const SizedBox(height: 16),
                            _buildCategoryPicker(s, isDark, cs),
                            const SizedBox(height: 16),
                            _buildAccountPicker(state, s, isDark, cs),
                            const SizedBox(height: 16),
                            _buildPlanPicker(state, s, isDark, cs),
                            const SizedBox(height: 24),
                            _buildConfirmButton(cs, s, state),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(bool isDark) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
            color: isDark ? Colors.white24 : Colors.black12,
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildHeader(AppStrings s, bool isDark, ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _isEditing
                ? (_isPayment ? s.save : s.editExpenseTitle)
                : (_isPayment ? s.incomeLabel : s.addTransactionTitle),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _buildTypeToggle(isDark, cs, s),
      ],
    );
  }

  Widget _buildTypeToggle(bool isDark, ColorScheme cs, AppStrings s) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _typeBtn(s.expenseLabel, !_isPayment,
              () => setState(() => _isPayment = false), Colors.redAccent, isDark),
          _typeBtn(s.incomeLabel, _isPayment,
              () => setState(() => _isPayment = true), Colors.green, isDark),
        ],
      ),
    );
  }

  Widget _typeBtn(String label, bool active, VoidCallback onTap,
      Color activeColor, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10)),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                color: active
                    ? Colors.white
                    : (isDark ? Colors.white38 : Colors.black38))),
      ),
    );
  }

  Widget _buildDescriptionField(AppStrings s, bool isDark, ColorScheme cs) {
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      child: TextFormField(
        controller: _descriptionController,
        validator: (val) => (val == null || val.trim().isEmpty) ? s.enterDescription : null,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: s.descriptionHint,
          prefixIcon: Icon(Icons.edit_rounded,
              color: isDark ? Colors.white38 : Colors.black38, size: 18),
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          hintStyle: TextStyle(
              fontSize: 13, color: isDark ? Colors.white24 : Colors.black26),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _isPayment ? Colors.green : cs.primary, width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildAmountField(AppStrings s, bool isDark, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        border:
            Border.all(color: (_isPayment ? Colors.green : cs.primary).withValues(alpha: 0.1), width: 1.5),
      ),
      child: TextFormField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        inputFormatters: [CurrencyInputFormatter()],
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: _isPayment ? Colors.green : cs.primary,
        ),
        decoration: InputDecoration(
            hintText: s.amountHint,
            border: InputBorder.none,
            prefixIcon: Icon(Icons.bolt_rounded, 
                  color: _isPayment ? Colors.green : cs.primary, size: 20)),
        validator: (val) => _totalInputAmount <= 0 ? s.enterAmount : null,
      ),
    );
  }

  Widget _buildDateTimeButton(AppStrings s, bool isDark, ColorScheme cs) {
    return InkWell(
      onTap: _pickDateTime,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02)),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, size: 16, color: _isPayment ? Colors.green : cs.primary),
            const SizedBox(width: 10),
            Text(s.dateTime,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54)),
            const Spacer(),
            Text(DateFormat('dd/MM, HH:mm').format(_selectedDate),
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _isPayment ? Colors.green : cs.primary,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPicker(AppStrings s, bool isDark, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerLabel(s.category, Icons.grid_view_rounded, cs, isDark),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: Category.values.length,
            itemBuilder: (context, index) {
              final cat = Category.values[index];
              final isSelected = _category == cat;
              final color = UIHelpers.getCategoryColor(cat);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Icon(UIHelpers.getCategoryIcon(cat),
                      size: 12, color: isSelected ? Colors.white : color),
                  label: Text(s.getCategoryName(cat)),
                  selected: isSelected,
                  onSelected: (selected) => setState(() => _category = cat),
                  selectedColor: color,
                  labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white60 : Colors.black54),
                      fontSize: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide.none),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAccountPicker(AppState state, AppStrings s, bool isDark, ColorScheme cs) {
    if (state.accounts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerLabel(s.walletSource, Icons.account_balance_wallet_rounded, cs, isDark),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: state.accounts.length,
            itemBuilder: (context, index) {
              final acc = state.accounts[index];
              final isSelected = _sourceAccountId == acc.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(acc.name),
                  selected: isSelected,
                  onSelected: (selected) => setState(() => _sourceAccountId = selected ? acc.id : null),
                  selectedColor: _isPayment ? Colors.green : cs.primary,
                  labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white60 : Colors.black54),
                      fontSize: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide.none),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlanPicker(AppState state, AppStrings s, bool isDark, ColorScheme cs) {
    if (state.plans.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerLabel(s.attachToPlan, Icons.auto_awesome_motion_rounded, cs, isDark),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: state.plans.length,
            itemBuilder: (context, index) {
              final plan = state.plans[index];
              final isSelected = _planId == plan.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(plan.title),
                  selected: isSelected,
                  onSelected: (selected) => setState(() => _planId = selected ? plan.id : null),
                  selectedColor: Colors.blueAccent,
                  labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white60 : Colors.black54),
                      fontSize: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide.none),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(ColorScheme cs, AppStrings s, AppState state) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: () => _submitTransaction(state),
        style: FilledButton.styleFrom(
            backgroundColor: _isPayment ? Colors.green : cs.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
        child: Text(_isEditing ? s.save : s.done,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            )),
      ),
    );
  }

  void _submitTransaction(AppState state) {
    if (_formKey.currentState!.validate()) {
      final me = state.me;
      final newTx = PersonalTransaction(
        id: widget.initialTransaction?.id,
        description: _descriptionController.text,
        amount: _totalInputAmount,
        payerId: me?.id ?? (state.people.isNotEmpty ? state.people.first.id : ''),
        date: _selectedDate,
        category: _category,
        isPayment: _isPayment,
        sourceAccountId: _sourceAccountId,
        planId: _planId,
      );

      if (!_isPayment && _sourceAccountId != null) {
        final acc = state.accounts.firstWhere((a) => a.id == _sourceAccountId);
        if (_totalInputAmount > acc.currentBalance) {
          _showBalanceWarning(context, state, newTx, acc.name);
          return;
        }
      }

      _finalizeSubmit(state, newTx);
    }
  }

  void _finalizeSubmit(AppState state, PersonalTransaction tx) {
    if (_isEditing) {
      state.editPersonalTransaction(widget.initialTransaction!.id, tx);
    } else {
      state.addPersonalTransaction(tx);
    }
    Navigator.pop(context);
  }

  void _showBalanceWarning(BuildContext context, AppState state, PersonalTransaction tx, String accName) {
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.insufficientBalance, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("${s.insufficientBalanceMsg} '$accName'. ${s.continueAnyway}", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel.toUpperCase(), style: const TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finalizeSubmit(state, tx);
            }, 
            child: Text(s.proceed.toUpperCase(), style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  Widget _headerLabel(String text, IconData icon, ColorScheme cs, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 12, color: (_isPayment ? Colors.green : cs.primary).withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white60 : Colors.black54,
            )),
      ],
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    final value = double.parse(newValue.text.replaceAll(RegExp(r'\D'), ''));
    final formatter = NumberFormat('#,###', 'en_US');
    final newText = formatter.format(value);
    return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }
}
