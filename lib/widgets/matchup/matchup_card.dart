import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../common/app_interactions.dart';

class MatchupCard extends StatelessWidget {
  final MatchupModel matchup;
  final VoidCallback onTap;
  final ValueChanged<bool>? onSave;

  const MatchupCard(
      {super.key, required this.matchup, required this.onTap, this.onSave});

  @override
  Widget build(BuildContext context) {
    final optA = matchup.optionA;
    final optB = matchup.optionB;
    final pctA = matchup.optionAPercent;
    final pctB = matchup.optionBPercent;
    final imageA = _imageForOption(optA);
    final imageB = _imageForOption(optB);
    final hasImage = imageA != null || imageB != null;

    return AppPressable(
      onTap: onTap,
      pressedScale: 0.985,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/Cardback.png',
                  fit: BoxFit.cover,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: category + time
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    child: Row(
                      children: [
                        _CategoryChip(name: matchup.category?.nameHt ?? ''),
                        const SizedBox(width: 8),
                        const _PopularBadge(),
                        const Spacer(),
                        Text(
                          matchup.publishedAt != null
                              ? timeago.format(matchup.publishedAt!,
                                  locale: 'en_short')
                              : '',
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontFamily: 'Poppins'),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.more_horiz,
                            color: AppColors.textMuted, size: 18),
                      ],
                    ),
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Text(
                      matchup.titleHt,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // VS bar
                  if (optA != null && optB != null) ...[
                    _VsBar(
                      pctA: pctA,
                      pctB: pctB,
                      labelA: optA.optionName,
                      labelB: optB.optionName,
                      votesA: optA.voteCount,
                      votesB: optB.voteCount,
                      imageA: imageA,
                      imageB: imageB,
                      hasImage: hasImage,
                    ),
                    // Percentage split bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: pctA.round().clamp(1, 99),
                              child: Container(
                                height: 4,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF1E0A6B),
                                      Color(0xFF4C1D95)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: pctB.round().clamp(1, 99),
                              child: Container(
                                height: 4,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF7C1050),
                                      Color(0xFFBE185D)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Footer
                  _CardFooter(matchup: matchup, onSave: onSave),
                  const SizedBox(height: 6),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _imageForOption(MatchupOptionModel? option) {
    if (option == null) return null;
    if (option.imageUrl != null && option.imageUrl!.isNotEmpty) {
      return option.imageUrl;
    }

    final normalized = option.optionName.toLowerCase();
    if (normalized.contains('t-vice') || normalized.contains('tvice')) {
      return 'assets/images/tvice.png';
    }
    if (normalized.contains('rutshelle')) {
      return 'assets/images/rutshelle.png';
    }
    return null;
  }
}

class _CategoryChip extends StatelessWidget {
  final String name;
  const _CategoryChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(name,
          style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins')),
    );
  }
}

class _PopularBadge extends StatelessWidget {
  const _PopularBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1440),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4A1A7A), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Image.asset('assets/images/fire.png',
            width: 13, height: 13, fit: BoxFit.contain),
        const SizedBox(width: 3),
        const Text('Popilè',
            style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins')),
      ]),
    );
  }
}

class _VsBar extends StatelessWidget {
  final double pctA;
  final double pctB;
  final String labelA;
  final String labelB;
  final int votesA;
  final int votesB;
  final String? imageA;
  final String? imageB;
  final bool hasImage;

  const _VsBar({
    required this.pctA,
    required this.pctB,
    required this.labelA,
    required this.labelB,
    required this.votesA,
    required this.votesB,
    this.imageA,
    this.imageB,
    required this.hasImage,
  });

  String _fmt(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : '$v';

  Widget _image(String source, Alignment alignment) {
    if (source.startsWith('assets/')) {
      return Image.asset(source, fit: BoxFit.cover, alignment: alignment);
    }
    return CachedNetworkImage(
      imageUrl: source,
      fit: BoxFit.cover,
      alignment: alignment,
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Expanded(
                  flex: pctA.round().clamp(10, 90),
                  child: _VsSide(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E0A6B), Color(0xFF4C1D95)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    image: imageA,
                    imageBuilder: _image,
                    imageAlignment: Alignment.topLeft,
                    scrimBegin: Alignment.centerLeft,
                    scrimEnd: Alignment.centerRight,
                    percent: pctA,
                    label: labelA,
                    votes: votesA,
                    alignEnd: false,
                    hasImage: hasImage,
                    formatVotes: _fmt,
                  ),
                ),
                Expanded(
                  flex: pctB.round().clamp(10, 90),
                  child: _VsSide(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C1050), Color(0xFFBE185D)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    image: imageB,
                    imageBuilder: _image,
                    imageAlignment: Alignment.topRight,
                    scrimBegin: Alignment.centerRight,
                    scrimEnd: Alignment.centerLeft,
                    percent: pctB,
                    label: labelB,
                    votes: votesB,
                    alignEnd: true,
                    hasImage: hasImage,
                    formatVotes: _fmt,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VsSide extends StatelessWidget {
  final LinearGradient gradient;
  final String? image;
  final Widget Function(String source, Alignment alignment) imageBuilder;
  final Alignment imageAlignment;
  final Alignment scrimBegin;
  final Alignment scrimEnd;
  final double percent;
  final String label;
  final int votes;
  final bool alignEnd;
  final bool hasImage;
  final String Function(int value) formatVotes;

  const _VsSide({
    required this.gradient,
    required this.image,
    required this.imageBuilder,
    required this.imageAlignment,
    required this.scrimBegin,
    required this.scrimEnd,
    required this.percent,
    required this.label,
    required this.votes,
    required this.alignEnd,
    required this.hasImage,
    required this.formatVotes,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisAlignment =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return SizedBox(
      height: 88,
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 72;
        final micro = constraints.maxWidth < 46;
        return Stack(fit: StackFit.expand, children: [
          DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
          if (image != null) imageBuilder(image!, imageAlignment),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: hasImage ? 0.68 : 0),
                  Colors.black.withValues(alpha: hasImage ? 0.18 : 0),
                ],
                begin: scrimBegin,
                end: scrimEnd,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 6 : 10, vertical: compact ? 6 : 8),
            child: Column(
              crossAxisAlignment: crossAxisAlignment,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${percent.toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 9 : 10,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins')),
                if (!micro) ...[
                  Text(label,
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: compact ? 9 : 11,
                          fontFamily: 'Poppins'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Align(
                    alignment:
                        alignEnd ? Alignment.centerRight : Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!alignEnd) ...[
                            const Icon(Icons.people_outline,
                                color: Colors.white54, size: 12),
                            const SizedBox(width: 3),
                          ],
                          Text('${formatVotes(votes)} vwa',
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontFamily: 'Poppins')),
                          if (alignEnd) ...[
                            const SizedBox(width: 3),
                            const Icon(Icons.people_outline,
                                color: Colors.white54, size: 12),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ]);
      }),
    );
  }
}

class _CardFooter extends StatefulWidget {
  final MatchupModel matchup;
  final ValueChanged<bool>? onSave;
  const _CardFooter({required this.matchup, this.onSave});

  @override
  State<_CardFooter> createState() => _CardFooterState();
}

class _CardFooterState extends State<_CardFooter> {
  late bool _saved;
  @override
  void initState() {
    super.initState();
    _saved = widget.matchup.isSaved;
  }

  String _fmt(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : '$v';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(
        children: [
          _FooterStat(
              icon: Icons.chat_bubble_outline_rounded,
              value: _fmt(widget.matchup.argumentCount)),
          const SizedBox(width: 16),
          _FooterStat(
              icon: Icons.group_outlined,
              value: _fmt(widget.matchup.totalVotes)),
          const Spacer(),
          AppPressable(
            onTap: () {
              setState(() => _saved = !_saved);
              widget.onSave?.call(_saved);
            },
            haptic: AppHaptic.selection,
            pressedScale: 0.86,
            child: Icon(
              _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _saved ? AppColors.purple : AppColors.textMuted,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterStat extends StatelessWidget {
  final IconData icon;
  final String value;
  const _FooterStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppColors.textMuted, size: 16),
      const SizedBox(width: 4),
      Text(value,
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 12, fontFamily: 'Poppins')),
    ]);
  }
}
