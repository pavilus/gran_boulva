import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gran_boulva/models/models.dart';
import 'package:gran_boulva/services/supabase_service.dart';
import 'package:gran_boulva/config/app_colors.dart';
import 'coin_celebration.dart';

// ─── Public entry point ─────────────────────────────────────
/// Opens the gifting bottom sheet for a creator or argument context.
/// Returns true if a gift was successfully sent.
Future<bool> showGiftingSheet(
  BuildContext context, {
  required String receiverUserId,
  required String receiverUsername,
  String? receiverAvatarUrl,
  String contextType = 'creator',
  String? contextId,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GiftingSheet(
      receiverUserId: receiverUserId,
      receiverUsername: receiverUsername,
      receiverAvatarUrl: receiverAvatarUrl,
      contextType: contextType,
      contextId: contextId,
    ),
  );
  return result == true;
}

// ─── Sheet widget ───────────────────────────────────────────
class _GiftingSheet extends StatefulWidget {
  final String receiverUserId;
  final String receiverUsername;
  final String? receiverAvatarUrl;
  final String contextType;
  final String? contextId;

  const _GiftingSheet({
    required this.receiverUserId,
    required this.receiverUsername,
    this.receiverAvatarUrl,
    required this.contextType,
    this.contextId,
  });

  @override
  State<_GiftingSheet> createState() => _GiftingSheetState();
}

class _GiftingSheetState extends State<_GiftingSheet>
    with SingleTickerProviderStateMixin {
  final _coinService = CoinService();
  final _customCtrl = TextEditingController();

  List<SupportLevelModel> _levels = SupportLevelModel.defaults;
  SupportLevelModel? _selected;
  int _customAmount = 0;
  int _balance = 0;
  bool _loadingLevels = true;
  bool _sending = false;
  bool _success = false;
  String _successEmoji = '💙';
  String _successColor = '#3B82F6';
  int _successIntensity = 1;
  String _errorMsg = '';

  late final AnimationController _sheetCtrl;
  late final Animation<double> _sheetAnim;

  @override
  void initState() {
    super.initState();
    _sheetCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _sheetAnim = CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic);
    _sheetCtrl.forward();
    _loadData();
  }

  @override
  void dispose() {
    _sheetCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final levels = await _coinService.getSupportLevels();
    final user = await UserService().getProfile();
    if (mounted) {
      setState(() {
        _levels = levels.isNotEmpty ? levels : SupportLevelModel.defaults;
        _selected = _levels.first;
        _balance = user?.coinBalance ?? 0;
        _loadingLevels = false;
      });
    }
  }

  int get _effectiveAmount =>
      _customAmount > 0 ? _customAmount : (_selected?.coins ?? 0);

  bool get _canSend =>
      _effectiveAmount > 0 && _effectiveAmount <= _balance && !_sending;

  SupportLevelModel? get _matchingLevel {
    SupportLevelModel? match;
    for (final l in _levels) {
      if (l.coins <= _effectiveAmount) match = l;
    }
    return match;
  }

  // ─── Send gift ────────────────────────────────────────────
  Future<void> _send() async {
    HapticFeedback.mediumImpact();
    setState(() { _sending = true; _errorMsg = ''; });

    try {
      final result = await _coinService.giftCoins(
        receiverUserId: widget.receiverUserId,
        coins: _effectiveAmount,
        contextType: widget.contextType,
        contextId: widget.contextId,
      );

      final lvl = _matchingLevel;
      HapticFeedback.heavyImpact();

      setState(() {
        _success = true;
        _successEmoji = result['level_emoji'] as String? ?? lvl?.emoji ?? '💙';
        _successColor = lvl?.colorHex ?? '#3B82F6';
        _successIntensity = (result['animation_intensity'] as int?) ?? lvl?.animationIntensity ?? 1;
        _sending = false;
        _balance -= _effectiveAmount;
      });

      // Close after celebration
      await Future.delayed(const Duration(milliseconds: 1800));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      HapticFeedback.lightImpact();
      setState(() {
        _errorMsg = e.toString().contains('Balans')
            ? 'Balans ou pa sifi'
            : e.toString().contains('tèt ou')
                ? 'Ou pa ka voye coins bay tèt ou'
                : 'Erè — eseye ankò';
        _sending = false;
      });
    }
  }

  // ─── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sheetAnim,
      builder: (context, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(_sheetAnim),
        child: child,
      ),
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60),
        decoration: const BoxDecoration(
          color: Color(0xFF0e0f1e),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _success ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  // ─── Success state ────────────────────────────────────────
  Widget _buildSuccess() {
    return SizedBox(
      height: 300,
      child: Center(
        child: CoinCelebration(
          intensity: _successIntensity,
          emoji: _successEmoji,
          colorHex: _successColor,
        ),
      ),
    );
  }

  // ─── Form state ───────────────────────────────────────────
  Widget _buildForm() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Receiver info
          _ReceiverHeader(
            username: widget.receiverUsername,
            avatarUrl: widget.receiverAvatarUrl,
          ),
          const SizedBox(height: 20),

          if (_loadingLevels)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.purpleLight, strokeWidth: 2),
            )
          else ...[
            // Support level pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _levels.map((lvl) {
                    final isSelected = _customAmount == 0 && _selected?.coins == lvl.coins;
                    final color = _hexColor(lvl.colorHex);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selected = lvl;
                          _customAmount = 0;
                          _customCtrl.clear();
                          _errorMsg = '';
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isSelected ? color.withAlpha(40) : Colors.white.withAlpha(8),
                          border: Border.all(
                            color: isSelected ? color : Colors.white12,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withAlpha(60), blurRadius: 12)]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Text(lvl.emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 4),
                            Text(
                              '${lvl.coins}',
                              style: TextStyle(
                                color: isSelected ? color : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              lvl.labelHt,
                              style: TextStyle(
                                color: isSelected ? color.withAlpha(200) : Colors.white38,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Custom amount
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: (v) {
                        setState(() {
                          _customAmount = int.tryParse(v) ?? 0;
                          _errorMsg = '';
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Montan pèsonalize…',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                        prefixIcon: const Icon(Icons.monetization_on_outlined,
                            color: AppColors.purpleLight, size: 18),
                        filled: true,
                        fillColor: Colors.white.withAlpha(8),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.purpleLight),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Level label + balance
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_matchingLevel != null) ...[
                    Text(
                      _matchingLevel!.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _matchingLevel!.labelHt,
                      style: TextStyle(
                        color: _hexColor(_matchingLevel!.colorHex),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ] else
                    const Text('Chwazi yon montan',
                        style: TextStyle(color: Colors.white38, fontSize: 13)),
                  const Spacer(),
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 14, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    '$_balance coins',
                    style: TextStyle(
                      color: _effectiveAmount > _balance
                          ? const Color(0xFFEF4444)
                          : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Error
            if (_errorMsg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 6),
                child: Text(_errorMsg,
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
              ),

            const SizedBox(height: 16),

            // Send button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SendButton(
                amount: _effectiveAmount,
                canSend: _canSend,
                sending: _sending,
                level: _matchingLevel,
                onTap: _send,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

// ─── Receiver header ─────────────────────────────────────────
class _ReceiverHeader extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  const _ReceiverHeader({required this.username, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.purple, AppColors.pink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ClipOval(
                child: avatarUrl != null
                    ? Image.network(avatarUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initials(username))
                    : _initials(username),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@$username',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Text('Voye Boulva Coins',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _initials(String name) => Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      );
}

// ─── Send button ──────────────────────────────────────────────
class _SendButton extends StatelessWidget {
  final int amount;
  final bool canSend;
  final bool sending;
  final SupportLevelModel? level;
  final VoidCallback onTap;

  const _SendButton({
    required this.amount,
    required this.canSend,
    required this.sending,
    required this.level,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = level != null ? _hexColor(level!.colorHex) : AppColors.purpleLight;
    return GestureDetector(
      onTap: canSend ? onTap : null,
      child: AnimatedOpacity(
        opacity: canSend ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: canSend
                ? LinearGradient(
                    colors: [color, color.withAlpha(180)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: canSend ? null : Colors.white12,
            boxShadow: canSend
                ? [BoxShadow(color: color.withAlpha(80), blurRadius: 16, offset: const Offset(0, 4))]
                : [],
          ),
          alignment: Alignment.center,
          child: sending
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      level?.emoji ?? '💙',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      amount > 0 ? 'Voye $amount Coins' : 'Chwazi yon montan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

Color _hexColor(String hex) {
  final h = hex.replaceAll('#', '');
  if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
  return AppColors.purpleLight;
}
