import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_colors.dart';
import '../../widgets/common/app_back_button.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _loading = true;
  bool _newMatchups = true;
  bool _votes = true;
  bool _replies = true;
  bool _follows = true;
  bool _weeklyDigest = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _newMatchups = prefs.getBool('notif_new_matchups') ?? true;
      _votes = prefs.getBool('notif_votes') ?? true;
      _replies = prefs.getBool('notif_replies') ?? true;
      _follows = prefs.getBool('notif_follows') ?? true;
      _weeklyDigest = prefs.getBool('notif_weekly_digest') ?? false;
      _loading = false;
    });
  }

  Future<void> _toggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        surfaceTintColor: Colors.transparent,
        leading: AppBackButton(
          onTap: () => Navigator.of(context).pop(),
        ),
        title: const Text('Notifikasyon',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins')),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionLabel('Aktivite'),
                const SizedBox(height: 12),
                _buildGroup([
                  _NotifTile(
                    icon: '⚡',
                    title: 'Nouvo matchups',
                    subtitle: 'Resevwa notifikasyon pou nouvo matchups',
                    value: _newMatchups,
                    onChanged: (v) {
                      setState(() => _newMatchups = v);
                      _toggle('notif_new_matchups', v);
                    },
                    showDivider: true,
                  ),
                  _NotifTile(
                    icon: '🗳️',
                    title: 'Vòt ak agimantasyon',
                    subtitle: 'Lè yon moun vote oswa agimante',
                    value: _votes,
                    onChanged: (v) {
                      setState(() => _votes = v);
                      _toggle('notif_votes', v);
                    },
                    showDivider: true,
                  ),
                  _NotifTile(
                    icon: '💬',
                    title: 'Repons',
                    subtitle: 'Lè yon moun reponn agimantasyon ou',
                    value: _replies,
                    onChanged: (v) {
                      setState(() => _replies = v);
                      _toggle('notif_replies', v);
                    },
                    showDivider: false,
                  ),
                ]),
                const SizedBox(height: 20),
                _sectionLabel('Sosyal'),
                const SizedBox(height: 12),
                _buildGroup([
                  _NotifTile(
                    icon: '👥',
                    title: 'Nouvo abònen',
                    subtitle: 'Lè yon moun swiv ou',
                    value: _follows,
                    onChanged: (v) {
                      setState(() => _follows = v);
                      _toggle('notif_follows', v);
                    },
                    showDivider: false,
                  ),
                ]),
                const SizedBox(height: 20),
                _sectionLabel('Rezime'),
                const SizedBox(height: 12),
                _buildGroup([
                  _NotifTile(
                    icon: '📊',
                    title: 'Rezime chak semenn',
                    subtitle: 'Resevwa yon rezime aktivite ou chak semenn',
                    value: _weeklyDigest,
                    onChanged: (v) {
                      setState(() => _weeklyDigest = v);
                      _toggle('notif_weekly_digest', v);
                    },
                    showDivider: false,
                  ),
                ]),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.purpleDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.purpleLight, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chanjman yo sove otomatikman.',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontFamily: 'Poppins'),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            fontFamily: 'Poppins'),
      );

  Widget _buildGroup(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children),
      );
}

class _NotifTile extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _NotifTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins')),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontFamily: 'Poppins')),
            ]),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.purple,
          ),
        ]),
      ),
      if (showDivider)
        const Divider(
            height: 1, color: AppColors.borderDim, indent: 16, endIndent: 16),
    ]);
  }
}
