// MediaFeedScreen — scrollable feed of all voice/video arguments across matchups.
// Accessible from the Kominotè section of the menu.
// Route: /media-feed

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/app_colors.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/common/verification_badge.dart';
import '../../widgets/media_player_widget.dart';

class MediaFeedScreen extends StatefulWidget {
  const MediaFeedScreen({super.key});

  @override
  State<MediaFeedScreen> createState() => _MediaFeedScreenState();
}

class _MediaFeedScreenState extends State<MediaFeedScreen> {
  final _service = ArgumentService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.getMediaFeed();
    if (mounted) {
      setState(() {
        _items = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        elevation: 0,
        leading: AppBackButton(onTap: () => context.pop()),
        title: const Row(
          children: [
            Text('🎤', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'Vwa & Videyo',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : _items.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppColors.purple,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _MediaArgumentCard(item: _items[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎙️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'Poko gen agiman vwa oswa videyo',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vote sou yon matchup epi anregistre premye agiman an!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Individual card ────────────────────────────────────────────────────────────

class _MediaArgumentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _MediaArgumentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final user = item['user'] as Map<String, dynamic>?;
    final matchup = item['matchup'] as Map<String, dynamic>?;
    final username = user?['username'] as String? ?? 'Itilizatè';
    final avatarUrl = user?['avatar_url'] as String?;
    final gender = user?['gender'] as String?;
    final verificationType = user?['verification_type'] as String?;
    final verificationStatus = user?['verification_status'] as String?;
    final verificationBadgeStyle = user?['verification_badge_style'] as String?;
    final matchupTitle = (matchup?['title_ht'] as String?)?.isNotEmpty == true
        ? matchup!['title_ht'] as String
        : matchup?['title_en'] as String? ?? '';
    final matchupId = matchup?['id'] as String?;
    final body = item['body'] as String? ?? '';
    final mediaUrl = item['media_url'] as String;
    final mediaType = item['media_type'] as String;
    final mediaDuration = item['media_duration'] as int?;
    final createdAt = item['created_at'] != null
        ? DateTime.tryParse(item['created_at'] as String)
        : null;
    final likeCount = item['like_count'] as int? ?? 0;
    final replyCount = item['reply_count'] as int? ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: avatar + username + time ───────────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/user/$username'),
                  child: UserAvatar(
                    radius: 18,
                    avatarUrl: avatarUrl,
                    gender: gender,
                    backgroundColor: AppColors.purpleDim,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.push('/user/$username'),
                            child: Text(
                              '@$username',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          if (verificationStatus == 'approved') ...[
                            const SizedBox(width: 4),
                            VerificationBadge(
                              type: verificationType,
                              status: verificationStatus,
                              badgeStyle: verificationBadgeStyle,
                              size: 12,
                            ),
                          ],
                        ],
                      ),
                      if (createdAt != null)
                        Text(
                          timeago.format(createdAt, locale: 'en_short'),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontFamily: 'Poppins',
                          ),
                        ),
                    ],
                  ),
                ),
                // media type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.purpleDim,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    mediaType == 'video' ? '🎬 Videyo' : '🎤 Vwa',
                    style: const TextStyle(
                      color: AppColors.purple,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),

            // ── Matchup context ────────────────────────────────────────────
            if (matchupTitle.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: matchupId != null
                    ? () => context.push('/matchup/$matchupId')
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bg1,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded,
                          color: AppColors.purple, size: 13),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          matchupTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMuted, size: 14),
                    ],
                  ),
                ),
              ),
            ],

            // ── Text body (optional, hidden if just a space) ───────────────
            if (body.trim().isNotEmpty && body.trim() != ' ') ...[
              const SizedBox(height: 10),
              Text(
                body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  height: 1.4,
                ),
              ),
            ],

            // ── Media player ───────────────────────────────────────────────
            const SizedBox(height: 10),
            MediaPlayerWidget(
              url: mediaUrl,
              type: mediaType,
              duration: mediaDuration,
            ),

            // ── Footer: likes + replies ────────────────────────────────────
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.thumb_up_outlined,
                    color: AppColors.textMuted, size: 14),
                const SizedBox(width: 4),
                Text('$likeCount',
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontFamily: 'Poppins')),
                const SizedBox(width: 14),
                const Icon(Icons.chat_bubble_outline_rounded,
                    color: AppColors.textMuted, size: 14),
                const SizedBox(width: 4),
                Text('$replyCount',
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontFamily: 'Poppins')),
                const Spacer(),
                GestureDetector(
                  onTap: matchupId != null
                      ? () => context.push('/matchup/$matchupId')
                      : null,
                  child: const Text(
                    'Wè matchup →',
                    style: TextStyle(
                      color: AppColors.purple,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
