import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/common/user_avatar.dart';

class TopVoicesScreen extends StatefulWidget {
  const TopVoicesScreen({super.key});

  @override
  State<TopVoicesScreen> createState() => _TopVoicesScreenState();
}

class _TopVoicesScreenState extends State<TopVoicesScreen> {
  final _userService = UserService();
  List<TopVoiceModel> _voices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _userService.getTopVoices(limit: 50);
      if (mounted) {
        setState(() {
          _voices = data;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('top voices error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        surfaceTintColor: Colors.transparent,
        leading: AppBackButton(onTap: () => Navigator.of(context).pop()),
        title: const Text(
          'Tòp Vwa',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.purple,
        backgroundColor: AppColors.card,
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.purple),
              )
            : _voices.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
                    children: const [
                      Icon(Icons.emoji_events_outlined,
                          color: AppColors.textMuted, size: 54),
                      SizedBox(height: 14),
                      Text(
                        'Pa gen tòp vwa ankò',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Lè itilizatè yo bati enfliyans, klasman yo ap parèt isit la.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _voices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final voice = _voices[i];
                      return _TopVoiceTile(
                        voice: voice,
                        rank: i + 1,
                        onTap: () => context.push('/user/${voice.username}'),
                      );
                    },
                  ),
      ),
    );
  }
}

class _TopVoiceTile extends StatelessWidget {
  final TopVoiceModel voice;
  final int rank;
  final VoidCallback onTap;

  const _TopVoiceTile({
    required this.voice,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = voice.avatarUrl;
    final medalColor = switch (rank) {
      1 => AppColors.warning,
      2 => const Color(0xFFC4B5FD),
      3 => const Color(0xFFF59E0B),
      _ => AppColors.purpleLight,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: medalColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: UserAvatar(
                  avatarUrl: avatar,
                  radius: 24,
                  backgroundColor: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${voice.username}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Vwa kominote a',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.purpleLight.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/fire.png', width: 14, height: 14, fit: BoxFit.contain),
                  const SizedBox(width: 4),
                  Text(
                    voice.formattedScore,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
