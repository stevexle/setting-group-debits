import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../models.dart';
import '../../l10n/strings.dart';
import '../ui_helpers.dart';
import '../widgets/common_widgets.dart';

class AddTransactionModal extends StatefulWidget {
  final GroupTransaction? initialTransaction;
  const AddTransactionModal({super.key, this.initialTransaction});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;

  late String _payerId;
  late Set<String> _participants;
  late Category _category;
  String? _sourceAccountId;
  String? _planId;

  bool _isCustomSplit = false;
  final Map<String, TextEditingController> _customControllers = {};

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
    _payerId =
        tx?.payerId ?? (state.people.isNotEmpty ? state.people.first.id : '');
    _participants = tx != null
        ? tx.participants.toSet()
        : state.people.map((p) => p.id).toSet();

    _category = tx?.category ?? Category.food;
    _isCustomSplit = tx?.customAmounts != null;
    
    if (tx != null) {
      _sourceAccountId = tx.sourceAccountId;
    } else {
      // Default account logic for new transactions
      if (_payerId == state.me?.id) {
        _sourceAccountId = _getDefaultAccountId(state);
      } else {
        _sourceAccountId = state.accounts.isNotEmpty ? state.accounts.first.id : null;
      }
    }
    _planId = tx?.planId;

    for (var person in state.people) {
      double val = 0;
      if (tx?.customAmounts?.containsKey(person.id) ?? false) {
        val = tx!.customAmounts![person.id]!;
      }
      _customControllers[person.id] = TextEditingController(
          text: val > 0 ? NumberFormat('#,###', 'en_US').format(val) : '');
      _customControllers[person.id]!.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    for (var controller in _customControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _totalInputAmount {
    final clean = _amountController.text.replaceAll(RegExp(r'\D'), '');
    return double.tryParse(clean) ?? 0;
  }

  double get _assignedSum {
    double sum = 0;
    for (var pid in _participants) {
      final val = double.tryParse(
              _customControllers[pid]!.text.replaceAll(RegExp(r'\D'), '')) ??
          0;
      sum += val;
    }
    return sum;
  }

  Future<void> _pickDateTime() async {
    if (!mounted) return;
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
    final fmt = NumberFormat('#,###', 'en_US');

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
                        color: cs.primary, size: 250, opacity: 0.12),
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
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black12,
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            Text(
                              _isEditing
                                  ? s.editExpenseTitle
                                  : s.addExpenseTitle,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _descriptionController,
                              hint: s.descriptionHint,
                              icon: Icons.edit_rounded,
                              isDark: isDark,
                              cs: cs,
                              height: 60,
                              validator: (val) =>
                                  (val == null || val.trim().isEmpty)
                                      ? s.enterDescription
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            _buildMainAmountField(isDark: isDark, cs: cs, s: s),
                            const SizedBox(height: 12),
                            _buildDateTimeButton(isDark: isDark, cs: cs, s: s),
                            const SizedBox(height: 16),
                            _headerLabel(
                                s.whoPays, Icons.person_rounded, cs, isDark),
                            const SizedBox(height: 8),
                            _buildPayerPicker(state, isDark, cs),
                            if (_payerId == (state.me?.id ?? '')) ...[
                              const SizedBox(height: 12),
                              _headerLabel(s.accountsLabel, Icons.account_balance_wallet_rounded, cs, isDark),
                              const SizedBox(height: 8),
                              _buildAccountPicker(state.accounts, isDark, cs, s),
                            ] else ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, size: 14, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        s.debtOnlyWarning,
                                        style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            _headerLabel(s.category, Icons.grid_view_rounded,
                                cs, isDark),
                            const SizedBox(height: 8),
                            _buildCategoryPicker(s, isDark, cs),
                            if (state.plans.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _headerLabel(s.selectPlan, Icons.assignment_rounded, cs, isDark),
                              const SizedBox(height: 8),
                              _buildPlanPicker(state.plans, isDark, cs, s),
                            ],
                            const SizedBox(height: 16),
                            _buildSplitSection(s, isDark, cs, state, fmt),
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


  Widget _headerLabel(String text, IconData icon, ColorScheme cs, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 12, color: cs.primary.withValues(alpha: 0.5)),
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

  Widget _buildMainAmountField(
      {required bool isDark, required ColorScheme cs, required AppStrings s}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        border:
            Border.all(color: cs.primary.withValues(alpha: 0.1), width: 1.5),
      ),
      child: TextFormField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        inputFormatters: [CurrencyInputFormatter()],
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: cs.primary,
        ),
        decoration: InputDecoration(
            hintText: s.amountHint,
            border: InputBorder.none,
            prefixIcon: Icon(Icons.bolt_rounded, color: cs.primary, size: 20)),
        validator: (val) => _totalInputAmount <= 0 ? s.enterAmount : null,
      ),
    );
  }

  Widget _buildDateTimeButton(
      {required bool isDark, required ColorScheme cs, required AppStrings s}) {
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
            Icon(Icons.calendar_month_rounded, size: 16, color: cs.primary),
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
                    color: cs.primary,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Person p, double size, bool isSelected) {
    final color = UIHelpers.getAvatarColor(p.colorIndex);
    final hasImage = p.avatarUrl.isNotEmpty;
    final isNetwork = p.avatarUrl.startsWith('http');
    final fileExists = !isNetwork && p.avatarUrl.isNotEmpty && File(p.avatarUrl).existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))
        ] : [],
      ),
      child: ClipOval(
        child: hasImage
            ? (isNetwork
                ? CachedNetworkImage(
                    imageUrl: p.avatarUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: color.withValues(alpha: 0.1)),
                    errorWidget: (context, url, error) => _fallbackAvatar(p, color, isSelected),
                  )
                : (fileExists
                    ? Image.file(File(p.avatarUrl), fit: BoxFit.cover)
                    : _fallbackAvatar(p, color, isSelected)))
            : _fallbackAvatar(p, color, isSelected),
      ),
    );
  }

  Widget _fallbackAvatar(Person p, Color color, bool isSelected) {
    return Container(
      color: color.withValues(alpha: isSelected ? 0.2 : 0.05),
      alignment: Alignment.center,
      child: Text(
        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? color : Colors.grey,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildPayerPicker(AppState state, bool isDark, ColorScheme cs) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.people.length,
        itemBuilder: (context, index) {
          final person = state.people[index];
          final isSelected = _payerId == person.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: _buildAvatar(person, 20, isSelected),
              label: Text(person.name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _payerId = person.id;
                    // If switching to 'me', try to default to a bank account
                    if (_payerId == state.me?.id && !_isEditing) {
                      _sourceAccountId = _getDefaultAccountId(state);
                    } else {
                      _sourceAccountId = null;
                    }
                  });
                }
              },
              selectedColor: cs.primary,
              labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white60 : Colors.black54),
                  fontSize: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide.none),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanPicker(List<BudgetPlan> plans, bool isDark, ColorScheme cs, AppStrings s) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: plans.length + 1,
        itemBuilder: (context, index) {
          final isNone = index == 0;
          final plan = isNone ? null : plans[index - 1];
          final isSelected = isNone ? (_planId == null) : (_planId == plan!.id);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(isNone ? s.none : plan?.title ?? ''),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _planId = isNone ? null : plan?.id);
              },
              selectedColor: cs.primary.withValues(alpha: 0.8),
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
    );
  }

  Widget _buildCategoryPicker(AppStrings s, bool isDark, ColorScheme cs) {
    return SizedBox(
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
    );
  }

  Widget _buildAccountPicker(List<Account> accounts, bool isDark, ColorScheme cs, AppStrings s) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final acc = accounts[index];
          final isSelected = _sourceAccountId == acc.id;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                acc.type == AccountType.bank ? Icons.account_balance_rounded : Icons.wallet_rounded,
                size: 12,
                color: isSelected ? Colors.white : cs.primary,
              ),
              label: Text(acc.name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _sourceAccountId = acc.id);
              },
              selectedColor: cs.primary.withValues(alpha: 0.8),
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
    );
  }

  /* Account and Plan pickers removed for cleaner UI in BillShare */

  Widget _buildSplitSection(AppStrings s, bool isDark, ColorScheme cs,
      AppState state, NumberFormat fmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _headerLabel(s.whoSplits, Icons.pie_chart_rounded, cs, isDark),
            _buildModeSwitch(isDark, cs, s),
          ],
        ),
        const SizedBox(height: 12),
        if (_isCustomSplit) _buildBalanceIndicator(s, isDark, cs, fmt),
        const SizedBox(height: 8),
        ...state.people.map((p) => _buildSplitRow(p, isDark, cs, s)),
      ],
    );
  }

  Widget _buildModeSwitch(bool isDark, ColorScheme cs, AppStrings s) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeToggleBtn(s.splitEqual, !_isCustomSplit,
              () => setState(() => _isCustomSplit = false), cs, isDark),
          _modeToggleBtn(s.splitCustom, _isCustomSplit,
              () => setState(() => _isCustomSplit = true), cs, isDark),
        ],
      ),
    );
  }

  Widget _modeToggleBtn(String label, bool active, VoidCallback onTap,
      ColorScheme cs, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: active ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10)),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                color: active
                    ? Colors.white
                    : (isDark ? Colors.white38 : Colors.black38))),
      ),
    );
  }

  Widget _buildBalanceIndicator(
      AppStrings s, bool isDark, ColorScheme cs, NumberFormat fmt) {
    final diff = _totalInputAmount - _assignedSum;
    final isMatch = diff.abs() < 1;
    final statusColor =
        isMatch ? Colors.green : (diff > 0 ? cs.primary : Colors.red);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withValues(alpha: 0.2))),
      child: Row(
        children: [
          Icon(
              isMatch
                  ? Icons.check_circle_rounded
                  : (diff > 0 ? Icons.info_rounded : Icons.warning_rounded),
              size: 12,
              color: statusColor),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
                  isMatch
                      ? s.done
                      : (diff > 0
                          ? '${s.remainingBalance}: ${fmt.format(diff)} ₫'
                          : '${s.amountMismatch}: ${fmt.format(diff.abs())} ₫'),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor),
                  overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text('${fmt.format(_assignedSum)} / ${fmt.format(_totalInputAmount)}',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildSplitRow(Person p, bool isDark, ColorScheme cs, AppStrings s) {
    final isIncluded = _participants.contains(p.id);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isIncluded
            ? (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white)
            : (isDark
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.black.withValues(alpha: 0.02)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isIncluded
                ? cs.primary.withValues(alpha: 0.3)
                : Colors.transparent),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => setState(() {
                if (isIncluded) {
                  if (_participants.length > 1) _participants.remove(p.id);
                } else {
                  _participants.add(p.id);
                }
              }),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildAvatar(p, 36, isIncluded),
                  if (isIncluded)
                    Positioned(
                        bottom: -1,
                        right: -1,
                        child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.blue),
                            child: const Icon(Icons.check,
                                size: 8, color: Colors.white))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(p.name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isIncluded ? FontWeight.w900 : FontWeight.w600,
                        color: isIncluded
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.grey))),
            if (_isCustomSplit && isIncluded)
              Container(
                width: 100,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: cs.primary.withValues(alpha: 0.15))),
                child: TextFormField(
                  controller: _customControllers[p.id] ??=
                      TextEditingController(text: '0'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                  ),
                  decoration: const InputDecoration(
                      suffixText: ' ₫',
                      suffixStyle:
                          TextStyle(fontSize: 9, fontWeight: FontWeight.normal),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(ColorScheme cs, AppStrings s, AppState state) {
    final isUnbalanced =
        _isCustomSplit && (_totalInputAmount - _assignedSum).abs() >= 1;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: isUnbalanced ? null : () => _submitTransaction(state),
        style: FilledButton.styleFrom(
            backgroundColor: isUnbalanced ? Colors.grey : cs.primary,
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
      Map<String, double>? customAmounts;
      if (_isCustomSplit) {
        customAmounts = {};
        for (var pid in _participants) {
          final pVal = double.tryParse(_customControllers[pid]!
                  .text
                  .replaceAll(RegExp(r'\D'), '')) ??
              0;
          customAmounts[pid] = pVal;
        }
      }

      final newTx = GroupTransaction(
        id: widget.initialTransaction?.id,
        description: _descriptionController.text,
        amount: _totalInputAmount,
        payerId: _payerId,
        participants: _participants.toList(),
        date: _selectedDate,
        category: _category,
        isPayment: widget.initialTransaction?.isPayment ?? false,
        customAmounts: customAmounts,
        sourceAccountId: (_payerId == (state.me?.id ?? '')) ? _sourceAccountId : null,
        planId: _planId,
      );

      // Check balance if current user is the payer
      if (_payerId == (state.me?.id ?? '') && _sourceAccountId != null) {
        final acc = state.accounts.firstWhere((a) => a.id == _sourceAccountId, orElse: () => state.accounts.first);
        if (_totalInputAmount > acc.currentBalance) {
          _showBalanceWarning(context, state, newTx, acc.name);
          return;
        }
      }

      _finalizeSubmit(state, newTx);
    }
  }

  void _finalizeSubmit(AppState state, GroupTransaction tx) {
    if (_isEditing) {
      state.editGroupTransaction(widget.initialTransaction!.id, tx);
    } else {
      state.addGroupTransaction(tx);
    }
    Navigator.pop(context);
  }

  void _showBalanceWarning(BuildContext context, AppState state, GroupTransaction tx, String accName) {
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

  String? _getDefaultAccountId(AppState state) {
    try {
      return state.accounts.firstWhere((a) => a.type == AccountType.bank).id;
    } catch (_) {
      return state.accounts.isNotEmpty ? state.accounts.first.id : null;
    }
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      required bool isDark,
      required ColorScheme cs,
      required double height,
      String? Function(String?)? validator}) {
    return Container(
      constraints: BoxConstraints(minHeight: height),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon,
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
              borderSide: BorderSide(color: cs.primary, width: 1.5)),
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String cleaned = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return const TextEditingValue(text: '');
    final number = int.parse(cleaned);
    final formatted = NumberFormat('#,###', 'en_US').format(number);
    return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length));
  }
}
