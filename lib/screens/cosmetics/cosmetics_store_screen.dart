import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';

class CosmeticsStoreScreen extends StatefulWidget {
  const CosmeticsStoreScreen({super.key});

  @override
  State<CosmeticsStoreScreen> createState() => _CosmeticsStoreScreenState();
}

class _CosmeticsStoreScreenState extends State<CosmeticsStoreScreen> {
  final _cosmeticsService = CosmeticsService();
  final _userService = UserService();

  List<CosmeticItem> _items = [];
  int _coinBalance = 0;
  bool _loading = true;
  String _selectedCategory = 'all';

  static const _categoryTabs = [
    ('all', 'Tout'),
    ('profile_frame', 'Kadè Pwofil'),
    ('username_effect', 'Efè Non'),
    ('profile_theme', 'Tèm Pwofil'),
    ('cosmetic_badge', 'Badj Kosmetik'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _cosmeticsService.getStore(),
        _userService.getProfile(),
      ]);
      if (!mounted) return;
      setState(() {
        _items = results[0] as List<CosmeticItem>;
        final user = results[1] as UserModel?;
        _coinBalance = user?.coinBalance ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CosmeticItem> get _filteredItems {
    if (_selectedCategory == 'all') return _items;
    return _items.where((i) => i.categoryKey == _selectedCategory).toList();
  }

  void _openItemSheet(CosmeticItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemBottomSheet(
        item: item,
        coinBalance: _coinBalance,
        onPurchase: () => _purchase(item),
        onEquip: () => _equip(item),
      ),
    );
  }

  Future<void> _purchase(CosmeticItem item) async {
    // confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          item.nameHt,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        content: Text(
          'Achte pou ${item.priceCoins} monè?',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anile',
                style:
                    TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Achte',
                style: TextStyle(
                    color: AppColors.purple,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    Navigator.pop(context); // close bottom sheet
    final result = await _cosmeticsService.purchaseCosmetic(item.id);
    if (!mounted) return;

    if (result['ok'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✨ ${item.nameHt} achte!',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['error'] as String? ?? 'Erè',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _equip(CosmeticItem item) async {
    Navigator.pop(context); // close bottom sheet
    final result =
        await _cosmeticsService.equipCosmetic(item.categoryKey, item.id);
    if (!mounted) return;

    if (result['ok'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${item.nameHt} ekipe!',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['error'] as String? ?? 'Erè',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Boutik Kosmetik',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$_coinBalance',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : Column(
              children: [
                _buildCategoryTabs(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.purple,
                    backgroundColor: AppColors.card,
                    child: _filteredItems.isEmpty
                        ? const Center(
                            child: Text(
                              'Pa gen item nan kategori sa a.',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontFamily: 'Poppins'),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.82,
                            ),
                            itemCount: _filteredItems.length,
                            itemBuilder: (_, i) =>
                                _ItemCard(item: _filteredItems[i], onTap: _openItemSheet),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _categoryTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (key, label) = _categoryTabs[i];
          final isSelected = _selectedCategory == key;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.purple
                    : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.purple
                      : AppColors.border,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Item Card ─────────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final CosmeticItem item;
  final ValueChanged<CosmeticItem> onTap;

  const _ItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rarityColor = item.rarityColor;

    return GestureDetector(
      onTap: () => onTap(item),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0e0f1e),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: rarityColor.withValues(alpha: 0.55), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: rarityColor.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rarity badge top-right
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: rarityColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _rarityLabel(item.rarity),
                    style: TextStyle(
                      color: rarityColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              // Preview / icon placeholder
              Expanded(
                child: Center(
                  child: item.assetUrl != null
                      ? Image.network(item.assetUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              _cosmeticIcon(item.categoryKey, rarityColor))
                      : _cosmeticIcon(item.categoryKey, rarityColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.nameHt,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (item.isEquipped)
                _statusChip('Ekipe', AppColors.success)
              else if (item.isOwned)
                _statusChip('Ou Posede', AppColors.purple)
              else if (item.priceCoins == 0)
                _statusChip('Gradye', AppColors.pink)
              else
                Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 3),
                    Text(
                      '${item.priceCoins}',
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cosmeticIcon(String categoryKey, Color color) {
    final icon = switch (categoryKey) {
      'profile_frame' => Icons.crop_free_rounded,
      'username_effect' => Icons.auto_awesome_rounded,
      'profile_theme' => Icons.palette_outlined,
      'cosmetic_badge' => Icons.workspace_premium_rounded,
      _ => Icons.star_rounded,
    };
    return Icon(icon, color: color, size: 48);
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  String _rarityLabel(String rarity) {
    return switch (rarity) {
      'common' => 'KOURAN',
      'rare' => 'RARE',
      'epic' => 'EPIK',
      'legendary' => 'LEJANDÈ',
      'founder' => 'FONDATE',
      _ => rarity.toUpperCase(),
    };
  }
}

// ── Item Bottom Sheet ─────────────────────────────────────────────────────────
class _ItemBottomSheet extends StatelessWidget {
  final CosmeticItem item;
  final int coinBalance;
  final VoidCallback onPurchase;
  final VoidCallback onEquip;

  const _ItemBottomSheet({
    required this.item,
    required this.coinBalance,
    required this.onPurchase,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    final rarityColor = item.rarityColor;
    final canAfford = coinBalance >= item.priceCoins;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0e0f1e),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rarityColor.withValues(alpha: 0.5)),
            ),
            child: item.assetUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(item.assetUrl!, fit: BoxFit.contain))
                : Icon(_categoryIcon(item.categoryKey), color: rarityColor, size: 40),
          ),
          const SizedBox(height: 14),

          // rarity chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rarityColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              _rarityLabel(item.rarity),
              style: TextStyle(
                  color: rarityColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins'),
            ),
          ),
          const SizedBox(height: 10),

          // name
          Text(
            item.nameHt,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),

          // description
          if (item.descriptionHt != null && item.descriptionHt!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.descriptionHt!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 24),

          // action button
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(context, canAfford),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool canAfford) {
    if (item.isEquipped) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text(
          '✅ Ekipe',
          style: TextStyle(
              color: AppColors.success,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700),
        ),
      );
    }

    if (item.isOwned) {
      return ElevatedButton(
        onPressed: onEquip,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text(
          'Ekipe',
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 15),
        ),
      );
    }

    if (item.rarity == 'founder' || item.priceCoins == 0) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text(
          'Gradye sèlman',
          style: TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins'),
        ),
      );
    }

    return ElevatedButton(
      onPressed: canAfford ? onPurchase : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            canAfford ? AppColors.purple : AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            canAfford
                ? 'Achte  •  ${item.priceCoins} monè'
                : 'Pa ase monè  (${item.priceCoins} bezwen)',
            style: TextStyle(
              color: canAfford ? Colors.white : AppColors.textMuted,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String key) {
    return switch (key) {
      'profile_frame' => Icons.crop_free_rounded,
      'username_effect' => Icons.auto_awesome_rounded,
      'profile_theme' => Icons.palette_outlined,
      'cosmetic_badge' => Icons.workspace_premium_rounded,
      _ => Icons.star_rounded,
    };
  }

  String _rarityLabel(String rarity) {
    return switch (rarity) {
      'common' => 'KOURAN',
      'rare' => 'RARE',
      'epic' => 'EPIK',
      'legendary' => 'LEJANDÈ',
      'founder' => 'FONDATE',
      _ => rarity.toUpperCase(),
    };
  }
}
