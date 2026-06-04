import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gran_boulva/models/models.dart';
import 'package:gran_boulva/services/supabase_service.dart';
import 'package:gran_boulva/config/app_colors.dart';
import 'package:gran_boulva/widgets/common/app_back_button.dart';

// ─── Tier config ────────────────────────────────────────────
const _tierColors = [
  Color(0xFF64748B), // 0 — User (slate)
  Color(0xFF22C55E), // 1 — Rising (green)
  Color(0xFF3B82F6), // 2 — Verified Creator (blue)
  Color(0xFFA855F7), // 3 — Elite (purple)
  Color(0xFFF59E0B), // 4 — Cultural Icon (gold)
];

const _tierIcons = ['👤', '🌱', '✅', '⚡', '👑'];

// ─── Main screen ────────────────────────────────────────────
class CreatorDashboardScreen extends StatefulWidget {
  const CreatorDashboardScreen({super.key});

  @override
  State<CreatorDashboardScreen> createState() => _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState extends State<CreatorDashboardScreen> {
  final _service = CreatorService();
  CreatorDashboardModel? _dashboard;
  CreatorProfileModel? _creatorProfile;
  List<CreatorRevenueEventModel> _events = [];
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await _service.getDashboard();
    final e = await _service.getRevenueEvents(limit: 20);
    final p = await _service.getMyProfile();
    if (mounted) {
      setState(() {
        _dashboard = d;
        _events = e;
        _creatorProfile = p;
        _loading = false;
      });
      _checkConsentIfNeeded();
    }
  }

  void _checkConsentIfNeeded() {
    final profile = _creatorProfile;
    if (profile == null || profile.creatorTier < 1) return;
    if (profile.hasAcceptedTerms) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _CreatorAgreementModal(
          onAccepted: () async {
            await _service.acceptCreatorTerms();
            final updated = await _service.getMyProfile();
            if (mounted) setState(() => _creatorProfile = updated);
          },
        ),
      );
    });
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await _service.refreshTier();
    await _load();
    setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        elevation: 0,
        title: const Text(
          'Panèl Kreyatè',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: AppBackButton(onTap: () => Navigator.of(context).pop()),
        actions: [
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.purpleLight)),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh,
                  color: AppColors.purpleLight, size: 20),
              onPressed: _refresh,
              tooltip: 'Aktyalize',
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purpleLight))
          : _dashboard == null
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppColors.purpleLight,
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TierCard(dashboard: _dashboard!),
                        const SizedBox(height: 16),
                        _ScoreCard(dashboard: _dashboard!),
                        const SizedBox(height: 16),
                        if (_dashboard!.isMonetizationEnabled) ...[
                          _RevenueCard(dashboard: _dashboard!),
                          const SizedBox(height: 16),
                        ],
                        _StatsGrid(dashboard: _dashboard!),
                        const SizedBox(height: 16),
                        if (_dashboard!.isMonetizationEnabled &&
                            _events.isNotEmpty) ...[
                          _RevenueHistory(events: _events),
                          const SizedBox(height: 16),
                        ],
                        if (!_dashboard!.isMonetizationEnabled)
                          _MonetizationUnlockCard(dashboard: _dashboard!),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('Pa gen done disponib',
              style: TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _refresh,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purpleLight),
            child:
                const Text('Eseye ankò', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}

// ─── Tier hero card ─────────────────────────────────────────
class _TierCard extends StatelessWidget {
  final CreatorDashboardModel dashboard;
  const _TierCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final tier = dashboard.creatorTier;
    final color = _tierColors[tier.clamp(0, 4)];
    final icon = _tierIcons[tier.clamp(0, 4)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color.withAlpha(50), color.withAlpha(15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tierLabel(tier),
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  Text(
                    'Nivo $tier nan 4',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              if (dashboard.isMonetizationEnabled)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF22C55E).withAlpha(80)),
                  ),
                  child: Text(
                    '${dashboard.revenueSharePercent}% revni',
                    style: const TextStyle(
                        color: Color(0xFF22C55E),
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          if (tier < 4) ...[
            const SizedBox(height: 16),
            _NextTierHint(currentTier: tier, dashboard: dashboard),
          ],
        ],
      ),
    );
  }

  String _tierLabel(int t) {
    switch (t) {
      case 1:
        return 'Kreyatè Entèmedyè';
      case 2:
        return 'Kreyatè Verifye';
      case 3:
        return 'Kreyatè Elit';
      case 4:
        return 'Ikòn Kiltirèl';
      default:
        return 'Itilizatè';
    }
  }
}

class _NextTierHint extends StatelessWidget {
  final int currentTier;
  final CreatorDashboardModel dashboard;
  const _NextTierHint({required this.currentTier, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    String hint;
    switch (currentTier) {
      case 0:
        hint = 'Rive 15 pwen ak 10+ abòne pou tounen Kreyatè Entèmedyè';
        break;
      case 1:
        hint =
            'Jwenn verifikasyon "trusted_creator" ak 35+ pwen pou tounen Kreyatè Verifye';
        break;
      case 2:
        hint = 'Rive 70+ pwen pou reklame Nivo Elit (admin konfime)';
        break;
      case 3:
        hint = 'Ikòn Kiltirèl akòde pa ekip Gran Boulva';
        break;
      default:
        hint = '';
    }
    if (hint.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: Colors.white38),
          const SizedBox(width: 6),
          Expanded(
            child: Text(hint,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

// ─── Creator Score card ──────────────────────────────────────
class _ScoreCard extends StatelessWidget {
  final CreatorDashboardModel dashboard;
  const _ScoreCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final score = dashboard.creatorScore;
    return _Card(
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    score >= 70
                        ? AppColors.purpleLight
                        : score >= 35
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF22C55E),
                  ),
                ),
                Text(
                  '$score',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pwen Kreyatè',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Text('Sou 100 — Nivo: ${_scoreLabel(score)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              _ScoreBar(
                  label: 'Enfliyans',
                  value: dashboard.influenceScore / 1000,
                  color: AppColors.purpleLight),
              _ScoreBar(
                  label: 'Abòne',
                  value: dashboard.followersCount / 500,
                  color: const Color(0xFF3B82F6)),
              _ScoreBar(
                  label: 'Patisipasyon',
                  value: dashboard.participationCount / 200,
                  color: const Color(0xFF22C55E)),
            ],
          ),
        ],
      ),
    );
  }

  String _scoreLabel(int s) {
    if (s >= 70) return 'Elit';
    if (s >= 35) return 'Konfime';
    if (s >= 15) return 'Entèmedyè';
    return 'Debitan';
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ScoreBar(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ),
          SizedBox(
            width: 100,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Revenue card (only for monetized creators) ─────────────
class _RevenueCard extends StatelessWidget {
  final CreatorDashboardModel dashboard;
  const _RevenueCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revni',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              _RevStat(
                  label: '7 jou',
                  coins: dashboard.revenueLast7d,
                  color: AppColors.purpleLight,
                  usd: dashboard.usdLast7d),
              const SizedBox(width: 12),
              _RevStat(
                  label: '30 jou',
                  coins: dashboard.revenueLast30d,
                  color: const Color(0xFF3B82F6),
                  usd: dashboard.usdLast30d),
              const SizedBox(width: 12),
              _RevStat(
                  label: 'Total',
                  coins: dashboard.totalEarnedCoins,
                  color: const Color(0xFFF59E0B),
                  usd: dashboard.totalEarnedUsd),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.pending_outlined,
                  size: 14, color: Colors.white38),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${dashboard.pendingPayoutCoins} coins an atant peman',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  if (dashboard.walletUsdBalance > 0)
                    Text(
                      '≈ \$${dashboard.walletUsdBalance.toStringAsFixed(2)} USD',
                      style: const TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              const Spacer(),
              if (dashboard.pendingPayoutCoins > 0)
                GestureDetector(
                  onTap: () =>
                      _showPayoutDialog(context, dashboard.pendingPayoutCoins),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.purpleLight.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.purpleLight.withAlpha(80)),
                    ),
                    child: const Text('Reklame',
                        style: TextStyle(
                            color: AppColors.purpleLight,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPayoutDialog(BuildContext context, int coins) {
    showDialog(
      context: context,
      builder: (ctx) => _PayoutDialog(coins: coins),
    );
  }
}

class _RevStat extends StatelessWidget {
  final String label;
  final int coins;
  final Color color;
  final double? usd;
  const _RevStat(
      {required this.label,
      required this.coins,
      required this.color,
      this.usd});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text('$coins',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            if (usd != null && usd! > 0)
              Text(
                '\$${usd!.toStringAsFixed(2)}',
                style: TextStyle(
                    color: color.withAlpha(180),
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
            const Text('monè',
                style: TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ─── Stats grid ──────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final CreatorDashboardModel dashboard;
  const _StatsGrid({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estatistik',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(
                  label: 'Abòne',
                  value: '${dashboard.followersCount}',
                  icon: Icons.people_outline),
              _Stat(
                  label: 'Patisipasyon',
                  value: '${dashboard.participationCount}',
                  icon: Icons.how_to_vote_outlined),
              _Stat(
                  label: 'Viktwa',
                  value: '${dashboard.victoryCount}',
                  icon: Icons.emoji_events_outlined),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Stat(
                  label: 'Sipò resevwa',
                  value: '${dashboard.totalSupportReceived}',
                  icon: Icons.favorite_border),
              _Stat(
                  label: 'Sipòtè (30j)',
                  value: '${dashboard.uniqueSupporters30d}',
                  icon: Icons.star_border),
              _Stat(
                  label: 'Enfliyans',
                  value: '${dashboard.influenceScore}',
                  icon: Icons.trending_up),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Stat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.purpleLight, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Revenue history ──────────────────────────────────────────
class _RevenueHistory extends StatelessWidget {
  final List<CreatorRevenueEventModel> events;
  const _RevenueHistory({required this.events});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Istwa Revni',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 8),
          ...events.map((e) => _EventRow(event: e)),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final CreatorRevenueEventModel event;
  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final label =
        event.eventType == 'argument_support' ? 'Sipò agiman' : event.eventType;
    final date = '${event.createdAt.day}/${event.createdAt.month}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.monetization_on_outlined,
              color: Color(0xFFF59E0B), size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12))),
          Text('+${event.creatorCoins}',
              style: const TextStyle(
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(width: 8),
          Text(date,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Monetization unlock hint ────────────────────────────────
class _MonetizationUnlockCard extends StatelessWidget {
  final CreatorDashboardModel dashboard;
  const _MonetizationUnlockCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🔒', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('Monetizasyon pa aktive',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Pou kòmanse touche revni sou Gran Boulva, ou bezwen:',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _Step(
              done: dashboard.creatorScore >= 35,
              text: 'Rive 35 pwen kreyatè (${dashboard.creatorScore}/35)'),
          _Step(
              done: dashboard.followersCount >= 10,
              text: '10+ abòne (${dashboard.followersCount}/10)'),
          const _Step(
              done: false,
              text: 'Jwenn verifikasyon Kreyatè Serye oswa Pèsonalite Piblik'),
          const SizedBox(height: 10),
          const Text(
            'Lè ou satisfè kondisyon yo, sistèm nan ap aktyalize nivo ou otomatikman.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final bool done;
  final String text;
  const _Step({required this.done, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 14, color: done ? const Color(0xFF22C55E) : Colors.white24),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: done ? Colors.white70 : Colors.white38,
                      fontSize: 12))),
        ],
      ),
    );
  }
}

// ─── Payout dialog (with settings-driven USD estimate + phone) ──
class _PayoutDialog extends StatefulWidget {
  final int coins;
  const _PayoutDialog({required this.coins});

  @override
  State<_PayoutDialog> createState() => _PayoutDialogState();
}

class _PayoutDialogState extends State<_PayoutDialog> {
  String _method = 'moncash';
  bool _loading = true;
  bool _submitting = false;
  final _phoneCtrl = TextEditingController();

  // Settings loaded from app_settings
  double _coinToUsdRate = 0.001;
  int _minPayoutCoins = 1000;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final supabase = Supabase.instance.client;
      final row = await supabase
          .from('app_settings')
          .select('value')
          .eq('key', 'payout_settings')
          .maybeSingle();
      if (row != null && mounted) {
        final v = row['value'] as Map<String, dynamic>;
        setState(() {
          _coinToUsdRate = (v['coinToUsdRate'] as num?)?.toDouble() ?? 0.001;
          _minPayoutCoins = (v['minPayoutCoins'] as num?)?.toInt() ?? 1000;
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _estimatedUsd => widget.coins * _coinToUsdRate;
  bool get _belowMin => widget.coins < _minPayoutCoins;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0e0f1e),
      title: const Text('Reklame Revni',
          style: TextStyle(color: Colors.white, fontSize: 16)),
      content: _loading
          ? const SizedBox(
              height: 60,
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.purpleLight, strokeWidth: 2)))
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount + USD estimate
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.purpleLight.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.purpleLight.withAlpha(40)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.coins} coins',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        Text(
                          '≈ \$${_estimatedUsd.toStringAsFixed(2)} USD',
                          style: const TextStyle(
                              color: Color(0xFF22C55E),
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        if (_belowMin) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Minimòm: $_minPayoutCoins coins — ou pa rive toujou.',
                            style: const TextStyle(
                                color: Color(0xFFEF4444), fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Phone number field
                  const Text('Nimewo telefòn pou resevwa peman:',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '+509 XXXX XXXX',
                      hintStyle:
                          const TextStyle(color: Colors.white24, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withAlpha(8),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Method selector
                  const Text('Metòd peman:',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  _methodBtn(
                      'MonCash', 'moncash', (v) => setState(() => _method = v)),
                  _methodBtn(
                      'NatCash', 'natcash', (v) => setState(() => _method = v)),
                  _methodBtn(
                      'Stripe', 'stripe', (v) => setState(() => _method = v)),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anile', style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          onPressed: (_submitting || _belowMin || _loading) ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _belowMin ? Colors.grey.shade800 : AppColors.purpleLight,
          ),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Soumèt', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _methodBtn(String label, String value, void Function(String) onTap) {
    final selected = _method == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.purpleLight.withAlpha(30)
              : Colors.white.withAlpha(5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppColors.purpleLight : Colors.white12),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? AppColors.purpleLight : Colors.white54,
                fontSize: 13)),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await CreatorService().requestPayout(
        coinsAmount: widget.coins,
        payoutMethod: _method,
        payoutPhone:
            _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        estimatedUsd: _estimatedUsd,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demann peman soumèt! Ekip nou ap trete li.'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (_) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erè — eseye ankò'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ─── Creator Agreement consent modal ────────────────────────
class _CreatorAgreementModal extends StatefulWidget {
  final Future<void> Function() onAccepted;
  const _CreatorAgreementModal({required this.onAccepted});

  @override
  State<_CreatorAgreementModal> createState() =>
      _CreatorAgreementModalState();
}

class _CreatorAgreementModalState extends State<_CreatorAgreementModal> {
  bool _checked = false;
  bool _submitting = false;

  Future<void> _confirm() async {
    setState(() => _submitting = true);
    try {
      await widget.onAccepted();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erè — eseye ankò'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0e0f1e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Text('🌱', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Akò Kreyatè',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ou fèk tounen yon Kreyatè Gran Boulva. Anvan ou ka komanse touche revni, ou dwe aksepte Akò Kreyatè a.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 14),
            const _TermPoint(
              icon: Icons.attach_money_rounded,
              text: 'Ou resevwa 60–80% revni sou kontni ou, depan sou nivo ou.',
            ),
            const _TermPoint(
              icon: Icons.copyright_rounded,
              text: 'Ou kenbe pwopriyete kontni ou, men ou bay Gran Boulva lisans pou afiche li.',
            ),
            const _TermPoint(
              icon: Icons.gavel_rounded,
              text: 'Ou responsab pou rapòte taks sou revni ou ranmase.',
            ),
            const _TermPoint(
              icon: Icons.rule_rounded,
              text: 'Vyolasyon règ ka anile estatit Kreyatè ou ak revni an atant.',
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => launchUrl(
                Uri.parse('https://granboulva.com/creator-agreement'),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text(
                'Li Akò Konplè →',
                style: TextStyle(
                  color: AppColors.purpleLight,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.purpleLight,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _checked = !_checked),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _checked,
                      onChanged: (v) => setState(() => _checked = v ?? false),
                      activeColor: AppColors.purpleLight,
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'M li epi m aksepte Akò Kreyatè Gran Boulva a.\nI have read and accept the Creator Agreement.',
                      style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: (_checked && !_submitting) ? _confirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _checked ? AppColors.purpleLight : Colors.grey.shade800,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Konfime',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ],
    );
  }
}

class _TermPoint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TermPoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.purpleLight),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ─── Shared card wrapper ────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0e0f1e),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1e2040)),
      ),
      child: child,
    );
  }
}
