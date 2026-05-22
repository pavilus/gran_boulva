import 'package:flutter/foundation.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_sound_service.dart';
import 'badge_unlock_events.dart';
import '../models/models.dart';

final supabase = Supabase.instance.client;

class AuthService {
  Future<AuthResponse> signIn(String email, String password) =>
      supabase.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp(String email, String password) =>
      supabase.auth.signUp(email: email, password: password);

  Future<void> signOut() => supabase.auth.signOut();

  Future<void> resetPassword(String email) =>
      supabase.auth.resetPasswordForEmail(email);

  User? get currentUser => supabase.auth.currentUser;
  Session? get currentSession => supabase.auth.currentSession;
}

class UserService {
  Future<UserModel?> getProfile() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return null;
    final data = await supabase
        .from('users')
        .select()
        .eq('auth_user_id', uid)
        .maybeSingle();
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  Future<UserModel?> getProfileById(String userId) async {
    final data =
        await supabase.from('users').select().eq('id', userId).single();
    return UserModel.fromJson(data);
  }

  Future<UserModel?> getProfileByUsername(String username) async {
    final data = await supabase
        .from('users')
        .select()
        .ilike('username', username)
        .maybeSingle();
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  Future<void> createProfile({
    required String authUserId,
    required String fullName,
    required String username,
    required String email,
    String? referralCode,
    String? gender,
    DateTime? dateOfBirth,
    String? country,
    String? phoneNumber,
    String language = 'ht',
  }) async {
    final myCode = username.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '') +
        DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    await supabase.from('users').insert({
      'auth_user_id': authUserId,
      'full_name': fullName,
      'username': username,
      'email': email,
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'country': country,
      'phone_number': phoneNumber,
      'language': language,
      'referral_code': myCode,
      'referred_by_code': referralCode,
    });
  }

  Future<bool> isUsernameAvailable(String username) async {
    final result = await supabase
        .rpc('is_username_available', params: {'p_username': username});
    return result == true;
  }

  Future<void> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? location,
    String? gender,
    DateTime? dateOfBirth,
    String? country,
    String? phoneNumber,
  }) async {
    final user = await getProfile();
    if (user == null) return;
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (username != null) updates['username'] = username;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (location != null) updates['location'] = location;
    if (gender != null) updates['gender'] = gender;
    if (dateOfBirth != null) {
      updates['date_of_birth'] = dateOfBirth.toIso8601String().split('T').first;
    }
    if (country != null) updates['country'] = country;
    if (phoneNumber != null) updates['phone_number'] = phoneNumber;
    if (updates.isEmpty) return;
    await supabase.from('users').update(updates).eq('id', user.id);
  }

  Future<String?> uploadAvatar(List<int> bytes, String userId) async {
    final path = '$userId/avatar.jpg';
    await supabase.storage.from('avatars').uploadBinary(
          path,
          bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
          fileOptions:
              const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    return supabase.storage.from('avatars').getPublicUrl(path);
  }

  Future<List<TopVoiceModel>> getTopVoices({int limit = 8}) async {
    final data =
        await supabase.rpc('get_top_voices', params: {'p_limit': limit});
    return (data as List).map((j) => TopVoiceModel.fromJson(j)).toList();
  }

  Future<void> follow(String targetUserId) async {
    await supabase.rpc('follow_user', params: {
      'p_following_id': targetUserId,
    });
    await RecommendationService().recordEvent(
      eventType: 'follow',
      targetType: 'user',
      targetId: targetUserId,
    );
  }

  Future<void> unfollow(String targetUserId) async {
    await supabase.rpc('unfollow_user', params: {
      'p_following_id': targetUserId,
    });
  }

  Future<bool> isFollowing(String targetUserId) async {
    final user = await getProfile();
    if (user == null) return false;
    final result = await supabase
        .from('follows')
        .select('id')
        .eq('follower_id', user.id)
        .eq('following_id', targetUserId)
        .maybeSingle();
    return result != null;
  }
}

class MatchupService {
  Future<List<CategoryModel>> getCategories() async {
    final data = await supabase
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return (data as List).map((j) => CategoryModel.fromJson(j)).toList();
  }

  Future<List<MatchupModel>> getHomeFeed({String? categoryId}) async {
    try {
      final data = await supabase.rpc('get_recommended_home_feed', params: {
        'p_category_id': categoryId,
        'p_limit': 30,
      });
      return (data as List? ?? [])
          .map((j) => MatchupModel.fromJson(j))
          .toList();
    } catch (e) {
      debugPrint('recommended feed fallback: $e');
      try {
        final res = await supabase.functions.invoke('get-home-feed',
            queryParameters:
                categoryId != null ? {'category_id': categoryId} : null);
        final data = res.data as Map<String, dynamic>;
        final matchups = (data['matchups'] as List? ?? [])
            .map((j) => MatchupModel.fromJson(j))
            .toList();
        return matchups;
      } catch (_) {
        return _fetchMatchupsFallback(categoryId: categoryId);
      }
    }
  }

  Future<void> recordMatchupView(String matchupId) {
    return RecommendationService().recordEvent(
      eventType: 'matchup_view',
      targetType: 'matchup',
      targetId: matchupId,
    );
  }

  Future<void> recordNotificationClick({
    required String targetType,
    required String targetId,
  }) {
    return RecommendationService().recordEvent(
      eventType: 'notification_click',
      targetType: targetType,
      targetId: targetId,
    );
  }

  Future<List<TopVoiceModel>> getTopVoices() async {
    try {
      final res = await supabase.functions.invoke('get-home-feed');
      final data = res.data as Map<String, dynamic>;
      return (data['top_voices'] as List? ?? [])
          .map((j) => TopVoiceModel.fromJson(j))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MatchupModel>> _fetchMatchupsFallback(
      {String? categoryId, String sort = 'popular'}) async {
    var q = supabase
        .from('matchups')
        .select('*, category:categories(*), options:matchup_options(*)')
        .eq('status', 'published');

    if (categoryId != null) q = q.eq('category_id', categoryId);

    final orderCol = sort == 'popular' ? 'engagement_score' : 'published_at';
    final data = await q.order(orderCol, ascending: false).limit(30);
    return (data as List).map((j) => MatchupModel.fromJson(j)).toList();
  }

  Future<List<MatchupModel>> getMatchupsFeed(
      {String sort = 'popular', String? categoryId}) async {
    return _fetchMatchupsFallback(sort: sort, categoryId: categoryId);
  }

  Future<List<MatchupModel>> getSavedMatchups() async {
    final user = await UserService().getProfile();
    if (user == null) return [];

    final savedRows = await supabase
        .from('saved_items')
        .select('item_id, created_at')
        .eq('user_id', user.id)
        .eq('item_type', 'matchup')
        .order('created_at', ascending: false);
    final savedIds = (savedRows as List)
        .map((row) => row['item_id'])
        .whereType<String>()
        .toList();
    if (savedIds.isEmpty) return [];

    final matchups = await supabase
        .from('matchups')
        .select('*, category:categories(*), options:matchup_options(*)')
        .inFilter('id', savedIds);
    final byId = {
      for (final row in matchups as List)
        row['id'] as String: MatchupModel.fromJson({
          ...Map<String, dynamic>.from(row as Map),
          'is_saved': true,
        })
    };

    return [
      for (final id in savedIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  Future<MatchupModel?> getMatchupDetail(String matchupId) async {
    final data = await supabase
        .from('matchups')
        .select('*, category:categories(*), options:matchup_options(*)')
        .eq('id', matchupId)
        .single();
    return MatchupModel.fromJson(data);
  }

  Future<Map<String, dynamic>> submitVoteAndArgument({
    required String matchupId,
    required String optionId,
    required String argumentBody,
  }) async {
    final data =
        await supabase.rpc('submit_vote_and_argument_with_coins', params: {
      'p_matchup_id': matchupId,
      'p_option_id': optionId,
      'p_argument_body': argumentBody,
    });
    await BadgeService().recordEvent(
      badgeKey: 'top_voter',
      eventType: 'vote',
      xpGained: 1,
      referenceId: matchupId,
    );
    await BadgeService().recordEvent(
      badgeKey: 'debater',
      eventType: 'argument_posted',
      xpGained: 3,
      referenceId: matchupId,
    );
    await RecommendationService().recordEvent(
      eventType: 'vote',
      targetType: 'matchup',
      targetId: matchupId,
    );
    await RecommendationService().recordEvent(
      eventType: 'argument_post',
      targetType: 'matchup',
      targetId: matchupId,
    );
    AppSoundService.play(AppSound.vote);

    return data is Map ? Map<String, dynamic>.from(data) : {'success': true};
  }

  Future<void> changeVote({
    required String matchupId,
    required String newOptionId,
  }) async {
    await supabase.rpc('change_vote_with_coins', params: {
      'p_matchup_id': matchupId,
      'p_option_id': newOptionId,
    });
    await BadgeService().recordEvent(
      badgeKey: 'top_voter',
      eventType: 'vote_changed',
      xpGained: 0,
      referenceId: matchupId,
    );
    await RecommendationService().recordEvent(
      eventType: 'vote',
      targetType: 'matchup',
      targetId: matchupId,
    );
    AppSoundService.play(AppSound.vote);
  }

  Future<Map<String, dynamic>?> getUserVote(String matchupId) async {
    final user = await UserService().getProfile();
    if (user == null) return null;
    final result = await supabase
        .from('votes')
        .select()
        .eq('user_id', user.id)
        .eq('matchup_id', matchupId)
        .maybeSingle();
    return result;
  }

  Future<bool> hasUserArgued(String matchupId) async {
    final user = await UserService().getProfile();
    if (user == null) return false;
    final result = await supabase
        .from('arguments')
        .select('id')
        .eq('user_id', user.id)
        .eq('matchup_id', matchupId)
        .maybeSingle();
    return result != null;
  }

  Future<void> toggleSave(String matchupId, bool save) async {
    final user = await UserService().getProfile();
    if (user == null) return;
    if (save) {
      await supabase.from('saved_items').upsert({
        'user_id': user.id,
        'item_type': 'matchup',
        'item_id': matchupId,
      }, onConflict: 'user_id,item_type,item_id');
      await RecommendationService().recordEvent(
        eventType: 'save',
        targetType: 'matchup',
        targetId: matchupId,
      );
    } else {
      await supabase
          .from('saved_items')
          .delete()
          .eq('user_id', user.id)
          .eq('item_type', 'matchup')
          .eq('item_id', matchupId);
    }
  }
}

class RecommendationService {
  Future<void> recordEvent({
    required String eventType,
    required String targetType,
    required String targetId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await supabase.rpc('record_behavior_event', params: {
        'p_event_type': eventType,
        'p_target_type': targetType,
        'p_target_id': targetId,
        'p_metadata': metadata ?? {},
      });
    } catch (_) {
      // Recommendation signals must not block core product actions.
    }
  }
}

class ArgumentService {
  static const _argumentSelectWithRelations =
      '*, user:users!arguments_user_id_fkey(username, avatar_url, gender, verification_type, verification_badge_style, verification_status), option:matchup_options!arguments_option_id_fkey(option_label, option_name)';

  Future<Map<String, dynamic>> getArguments(String matchupId,
      {String sort = 'popular', int page = 0, bool fetchAll = false}) async {
    try {
      final arguments = await _fetchVoterVisibleArguments(
        matchupId,
        sort: sort,
        page: page,
        fetchAll: fetchAll,
      ).catchError((e) {
        debugPrint('getArguments rpc fallback: $e');
        return _fetchArguments(
          matchupId,
          sort: sort,
          page: page,
          fetchAll: fetchAll,
        );
      });
      await _mergeCurrentUserArgument(arguments, matchupId);
      return {'arguments': arguments, 'locked': false};
    } catch (e) {
      debugPrint('getArguments error: $e');
      return {'locked': false, 'arguments': [], 'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> _fetchVoterVisibleArguments(
    String matchupId, {
    required String sort,
    required int page,
    required bool fetchAll,
  }) async {
    final data = await supabase.rpc('get_matchup_arguments_for_voter', params: {
      'p_matchup_id': matchupId,
      'p_sort': sort,
      'p_limit': 20,
      'p_offset': page * 20,
      'p_fetch_all': fetchAll,
    });
    return (data as List? ?? [])
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchArguments(
    String matchupId, {
    required String sort,
    required int page,
    required bool fetchAll,
  }) async {
    final orderCol = sort == 'recent' ? 'created_at' : 'final_score';
    try {
      final query = supabase
          .from('arguments')
          .select(_argumentSelectWithRelations)
          .eq('matchup_id', matchupId)
          .eq('status', 'active')
          .order(orderCol, ascending: false);
      final data = fetchAll
          ? await query
          : await query.range(page * 20, (page + 1) * 20 - 1);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('getArguments joined query fallback: $e');
      final query = supabase
          .from('arguments')
          .select()
          .eq('matchup_id', matchupId)
          .eq('status', 'active')
          .order(orderCol, ascending: false);
      final data = fetchAll
          ? await query
          : await query.range(page * 20, (page + 1) * 20 - 1);
      final arguments = List<Map<String, dynamic>>.from(data as List);
      await _hydrateArgumentRelations(arguments);
      return arguments;
    }
  }

  Future<void> _mergeCurrentUserArgument(
    List<Map<String, dynamic>> arguments,
    String matchupId,
  ) async {
    try {
      final user = await UserService().getProfile();
      if (user == null || arguments.any((a) => a['user_id'] == user.id)) return;

      final mine = await supabase
          .from('arguments')
          .select(_argumentSelectWithRelations)
          .eq('matchup_id', matchupId)
          .eq('user_id', user.id)
          .eq('status', 'active')
          .order('created_at', ascending: false);
      if (mine.isNotEmpty) {
        arguments.insertAll(
          0,
          mine.map((a) => Map<String, dynamic>.from(a as Map)),
        );
      }
    } catch (e) {
      debugPrint('getArguments current user merge error: $e');
    }
  }

  Future<void> _hydrateArgumentRelations(
      List<Map<String, dynamic>> arguments) async {
    if (arguments.isEmpty) return;

    await Future.wait([
      _hydrateArgumentUsers(arguments),
      _hydrateArgumentOptions(arguments),
    ]);
  }

  Future<void> _hydrateArgumentUsers(
      List<Map<String, dynamic>> arguments) async {
    try {
      final userIds = arguments
          .map((a) => a['user_id'])
          .whereType<String>()
          .toSet()
          .toList();
      if (userIds.isEmpty) return;
      final rows = await supabase
          .from('users')
          .select('id, username, avatar_url, gender')
          .inFilter('id', userIds);
      final usersById = {
        for (final row in rows as List)
          row['id'] as String: Map<String, dynamic>.from(row as Map)
      };
      for (final argument in arguments) {
        argument['user'] = usersById[argument['user_id']];
      }
    } catch (e) {
      debugPrint('getArguments user hydration error: $e');
    }
  }

  Future<void> _hydrateArgumentOptions(
      List<Map<String, dynamic>> arguments) async {
    try {
      final optionIds = arguments
          .map((a) => a['option_id'])
          .whereType<String>()
          .toSet()
          .toList();
      if (optionIds.isEmpty) return;
      final rows = await supabase
          .from('matchup_options')
          .select('id, option_label, option_name')
          .inFilter('id', optionIds);
      final optionsById = {
        for (final row in rows as List)
          row['id'] as String: Map<String, dynamic>.from(row as Map)
      };
      for (final argument in arguments) {
        argument['option'] = optionsById[argument['option_id']];
      }
    } catch (e) {
      debugPrint('getArguments option hydration error: $e');
    }
  }

  Future<void> likeArgument(String argumentId, {String? ownerUserId}) async {
    final user = await UserService().getProfile();
    if (user == null) return;
    await supabase.from('argument_reactions').upsert({
      'argument_id': argumentId,
      'user_id': user.id,
      'reaction_type': 'like',
    }, onConflict: 'argument_id,user_id');
    await RecommendationService().recordEvent(
      eventType: 'like',
      targetType: 'argument',
      targetId: argumentId,
    );
    if (ownerUserId != null && ownerUserId != user.id) {
      NotificationService().send(
        toUserId: ownerUserId,
        type: 'argument_like',
        title: '@${user.username} renmen agiman ou',
        relatedTable: 'arguments',
        relatedId: argumentId,
      );
    }
  }

  Future<void> dislikeArgument(String argumentId) async {
    final user = await UserService().getProfile();
    if (user == null) return;
    await supabase.from('argument_reactions').upsert({
      'argument_id': argumentId,
      'user_id': user.id,
      'reaction_type': 'dislike',
    }, onConflict: 'argument_id,user_id');
  }

  Future<void> removeReaction(String argumentId) async {
    final user = await UserService().getProfile();
    if (user == null) return;
    await supabase
        .from('argument_reactions')
        .delete()
        .eq('argument_id', argumentId)
        .eq('user_id', user.id);
  }

  Future<void> replyToArgument(String argumentId, String body,
      {String? ownerUserId}) async {
    final user = await UserService().getProfile();
    if (user == null) return;
    await supabase.from('argument_replies').insert({
      'argument_id': argumentId,
      'user_id': user.id,
      'body': body,
    });
    await BadgeService().recordEvent(
      badgeKey: 'community',
      eventType: 'helpful_reply',
      xpGained: 2,
      referenceId: argumentId,
    );
    await RecommendationService().recordEvent(
      eventType: 'reply',
      targetType: 'argument',
      targetId: argumentId,
    );
    if (ownerUserId != null && ownerUserId != user.id) {
      NotificationService().send(
        toUserId: ownerUserId,
        type: 'argument_reply',
        title: '@${user.username} reponn agiman ou',
        body: body.length > 80 ? '${body.substring(0, 80)}…' : body,
        relatedTable: 'arguments',
        relatedId: argumentId,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getReplies(String argumentId) async {
    final data = await supabase
        .from('argument_replies')
        .select(
            '*, user:users!argument_replies_user_id_fkey(username, avatar_url, gender, verification_type, verification_badge_style, verification_status)')
        .eq('argument_id', argumentId)
        .eq('status', 'active')
        .order('created_at');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<String?> getArgumentMatchupId(String argumentId) async {
    final data = await supabase
        .from('arguments')
        .select('matchup_id')
        .eq('id', argumentId)
        .maybeSingle();
    return data?['matchup_id'] as String?;
  }

  Future<void> report(
      {required String type,
      required String id,
      required String reason}) async {
    final user = await UserService().getProfile();
    if (user == null) return;
    await supabase.from('reports').insert({
      'reporter_user_id': user.id,
      'reported_type': type,
      'reported_id': id,
      'reason': reason,
    });
  }
}

class CoinPackConfig {
  final int coins;
  final int price;
  final String label;
  final String savings;
  final bool popular;

  const CoinPackConfig({
    required this.coins,
    required this.price,
    required this.label,
    required this.savings,
    required this.popular,
  });

  factory CoinPackConfig.fromJson(Map<String, dynamic> json) {
    return CoinPackConfig(
      coins: _intFromJson(json['coins']),
      price: _intFromJson(json['price']),
      label: (json['label'] ?? '').toString(),
      savings: (json['savings'] ?? '').toString(),
      popular: json['popular'] == true,
    );
  }
}

class BoostTierConfig {
  final String label;
  final String tier;
  final int coins;
  final String desc;

  const BoostTierConfig({
    required this.label,
    required this.tier,
    required this.coins,
    required this.desc,
  });

  String get price => '$coins Coins';

  factory BoostTierConfig.fromJson(Map<String, dynamic> json) {
    return BoostTierConfig(
      label: (json['label'] ?? '').toString(),
      tier: (json['tier'] ?? '').toString(),
      coins: _intFromJson(json['coins']),
      desc: (json['desc'] ?? '').toString(),
    );
  }
}

class CoinEconomyConfig {
  final int coinsPerVote;
  final int coinsPerArgument;
  final int transferFee;
  final int signupBonus;
  final int dailyClaimBase;
  final int dailyStreakBonus;
  final int dailyClaimMax;
  final List<int> supportAmounts;
  final List<CoinPackConfig> coinPacks;
  final List<BoostTierConfig> boostTiers;

  const CoinEconomyConfig({
    required this.coinsPerVote,
    required this.coinsPerArgument,
    required this.transferFee,
    required this.signupBonus,
    required this.dailyClaimBase,
    required this.dailyStreakBonus,
    required this.dailyClaimMax,
    required this.supportAmounts,
    required this.coinPacks,
    required this.boostTiers,
  });

  static const fallback = CoinEconomyConfig(
    coinsPerVote: 0,
    coinsPerArgument: 0,
    transferFee: 10,
    signupBonus: 5,
    dailyClaimBase: 2,
    dailyStreakBonus: 1,
    dailyClaimMax: 10,
    supportAmounts: [10, 25, 50, 100],
    coinPacks: [
      CoinPackConfig(
        coins: 100,
        price: 99,
        label: '\$0.99',
        savings: '',
        popular: false,
      ),
      CoinPackConfig(
        coins: 550,
        price: 499,
        label: '\$4.99',
        savings: '9% ekonomi',
        popular: false,
      ),
      CoinPackConfig(
        coins: 1200,
        price: 999,
        label: '\$9.99',
        savings: '16% ekonomi',
        popular: true,
      ),
      CoinPackConfig(
        coins: 2500,
        price: 1999,
        label: '\$19.99',
        savings: '19% ekonomi',
        popular: false,
      ),
      CoinPackConfig(
        coins: 7000,
        price: 4999,
        label: '\$49.99',
        savings: '29% ekonomi',
        popular: false,
      ),
    ],
    boostTiers: [
      BoostTierConfig(
        label: '24 Èdtan',
        tier: '24h',
        coins: 150,
        desc: 'Vizibilite × 2 pandan 24 èdtan',
      ),
      BoostTierConfig(
        label: '4 Jou',
        tier: '4d',
        coins: 350,
        desc: 'Vizibilite × 5 pandan 4 jou',
      ),
      BoostTierConfig(
        label: '1 Semèn',
        tier: '1w',
        coins: 550,
        desc: 'Vizibilite × 10 pandan 1 semèn',
      ),
    ],
  );

  factory CoinEconomyConfig.fromJson(Map<String, dynamic> json) {
    final supportAmounts = (json['supportAmounts'] as List? ?? [])
        .map(_intFromJson)
        .where((value) => value > 0)
        .toList();
    final coinPacks = (json['coinPacks'] as List? ?? [])
        .whereType<Map>()
        .map((item) => CoinPackConfig.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((pack) => pack.coins > 0 && pack.price > 0)
        .toList();
    final boostTiers = (json['boostTiers'] as List? ?? [])
        .whereType<Map>()
        .map((item) => BoostTierConfig.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((tier) => tier.tier.isNotEmpty && tier.coins > 0)
        .toList();

    return CoinEconomyConfig(
      coinsPerVote: _intFromJson(json['coinsPerVote']),
      coinsPerArgument: _intFromJson(json['coinsPerArgument']),
      transferFee:
          _intFromJson(json['transferFee'], fallback: fallback.transferFee),
      signupBonus:
          _intFromJson(json['signupBonus'], fallback: fallback.signupBonus),
      dailyClaimBase: _intFromJson(json['dailyClaimBase'],
          fallback: fallback.dailyClaimBase),
      dailyStreakBonus: _intFromJson(json['dailyStreakBonus'],
          fallback: fallback.dailyStreakBonus),
      dailyClaimMax:
          _intFromJson(json['dailyClaimMax'], fallback: fallback.dailyClaimMax),
      supportAmounts:
          supportAmounts.isNotEmpty ? supportAmounts : fallback.supportAmounts,
      coinPacks: coinPacks.isNotEmpty ? coinPacks : fallback.coinPacks,
      boostTiers: boostTiers.isNotEmpty ? boostTiers : fallback.boostTiers,
    );
  }
}

int _intFromJson(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

class DailyCoinClaimStatus {
  final bool canClaim;
  final int todayAmount;
  final int streakCount;
  final int nextStreakCount;
  final int amount;
  final bool claimed;

  const DailyCoinClaimStatus({
    required this.canClaim,
    required this.todayAmount,
    required this.streakCount,
    required this.nextStreakCount,
    this.amount = 0,
    this.claimed = false,
  });

  factory DailyCoinClaimStatus.fromJson(Map<String, dynamic> json) {
    return DailyCoinClaimStatus(
      canClaim: json['can_claim'] == true,
      todayAmount: _intFromJson(json['today_amount']),
      streakCount: _intFromJson(json['streak_count']),
      nextStreakCount: _intFromJson(json['next_streak_count']),
      amount: _intFromJson(json['amount']),
      claimed: json['claimed'] == true,
    );
  }
}

class CoinService {
  Future<CoinEconomyConfig> getEconomyConfig() async {
    try {
      final data = await supabase
          .from('app_settings')
          .select('value')
          .eq('key', 'coin_economy')
          .maybeSingle();
      final value = data?['value'];
      if (value is Map) {
        return CoinEconomyConfig.fromJson(Map<String, dynamic>.from(value));
      }
    } catch (e) {
      debugPrint('getEconomyConfig fallback: $e');
    }
    return CoinEconomyConfig.fallback;
  }

  Future<DailyCoinClaimStatus> getDailyClaimStatus() async {
    final data = await supabase.rpc('get_daily_coin_claim_status');
    return DailyCoinClaimStatus.fromJson(
        Map<String, dynamic>.from(data as Map));
  }

  Future<DailyCoinClaimStatus> claimDailyReward() async {
    final data = await supabase.rpc('claim_daily_coin_reward');
    final result =
        DailyCoinClaimStatus.fromJson(Map<String, dynamic>.from(data as Map));
    final now = DateTime.now();
    final dailyKey =
        'daily:${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await BadgeService().recordEvent(
      badgeKey: 'hot_streak',
      eventType: 'daily_claim',
      xpGained: 1,
      referenceKey: dailyKey,
    );
    if (now.weekday == DateTime.monday || result.streakCount % 7 == 0) {
      await BadgeService().recordEvent(
        badgeKey: 'consistent',
        eventType: 'weekly_participation',
        xpGained: 1,
        referenceKey: _weekReferenceKey(now),
      );
    }
    AppSoundService.play(AppSound.coin);
    return result;
  }

  String _weekReferenceKey(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDay).inDays + 1;
    final week = ((dayOfYear + firstDay.weekday - 2) / 7).floor() + 1;
    return 'week:${date.year}-W${week.toString().padLeft(2, '0')}';
  }

  Future<int> getBalance() async {
    final user = await UserService().getProfile();
    if (user == null) return 0;
    if (user.coinBalance > 0) return user.coinBalance;

    final transactions = await getTransactions(limit: 200);
    return balanceFromTransactions(transactions);
  }

  int balanceFromTransactions(List<CoinTransactionModel> transactions) {
    var balance = 0;
    for (final transaction in transactions) {
      final status = transaction.status.toLowerCase();
      if (status != 'completed' && status != 'succeeded' && status != 'paid') {
        continue;
      }

      switch (transaction.transactionType) {
        case 'purchase':
        case 'referral_reward':
        case 'admin_reward':
        case 'refund':
        case 'signup_bonus':
        case 'daily_claim':
          balance += transaction.amount;
          break;
        case 'boost_spend':
        case 'argument_support':
        case 'vote_spend':
        case 'vote_change_spend':
        case 'argument_post_spend':
          balance -= transaction.amount + transaction.fee;
          break;
        case 'transfer':
          balance -= transaction.fee;
          break;
      }
    }
    return balance < 0 ? 0 : balance;
  }

  Future<List<CoinTransactionModel>> getTransactions({int limit = 20}) async {
    final user = await UserService().getProfile();
    if (user == null) return [];
    final data = await supabase
        .from('coin_transactions')
        .select()
        .or('from_user_id.eq.${user.id},to_user_id.eq.${user.id}')
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((j) => CoinTransactionModel.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> createPurchase({
    required int coinAmount,
    required int usdCents,
  }) async {
    try {
      final res =
          await supabase.functions.invoke('create-coin-purchase', body: {
        'coin_amount': coinAmount,
        'usd_amount': usdCents / 100,
        'usd_cents': usdCents,
      });
      final data = _mapFromResponse(res.data);
      final error = data['error'] ?? data['message'];
      if (error != null && data['client_secret'] == null) {
        throw Exception(error);
      }
      if (_clientSecretFrom(data) == null) {
        throw Exception('Missing Stripe client secret');
      }
      return data;
    } catch (e) {
      debugPrint('createPurchase edge function error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> confirmCoinPurchase({
    required String clientSecret,
  }) async {
    final res = await supabase.functions.invoke('confirm-coin-purchase', body: {
      'client_secret': clientSecret,
    });
    final data = _mapFromResponse(res.data);
    final error = data['error'] ?? data['message'];
    if (error != null) throw Exception(error);
    return data;
  }

  Map<String, dynamic> _mapFromResponse(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    return {'data': data};
  }

  String? _clientSecretFrom(Map<String, dynamic> data) {
    final direct = data['client_secret'] ?? data['clientSecret'];
    if (direct != null && direct.toString().isNotEmpty) {
      return direct.toString();
    }

    final paymentIntent = data['payment_intent'] ?? data['paymentIntent'];
    if (paymentIntent is Map) {
      final nested =
          paymentIntent['client_secret'] ?? paymentIntent['clientSecret'];
      if (nested != null && nested.toString().isNotEmpty) {
        return nested.toString();
      }
    }

    final nestedData = data['data'];
    if (nestedData is Map) {
      final nested = nestedData['client_secret'] ?? nestedData['clientSecret'];
      if (nested != null && nested.toString().isNotEmpty) {
        return nested.toString();
      }
    }

    return null;
  }

  Future<void> supportArgument({
    required String argumentId,
    required int amount,
    String? ownerUserId,
  }) async {
    try {
      await supabase.rpc('support_argument_checked', params: {
        'p_argument_id': argumentId,
        'p_amount': amount,
      });
      await RecommendationService().recordEvent(
        eventType: 'support',
        targetType: 'argument',
        targetId: argumentId,
        metadata: {'amount': amount},
      );
    } catch (e) {
      if (e.toString().contains('pwòp agiman')) rethrow;
      try {
        final res = await supabase.functions.invoke('support-argument', body: {
          'argument_id': argumentId,
          'amount': amount,
          'transaction_type': 'argument_support',
        });
        final data = res.data;
        if (data is Map && data['error'] != null) {
          throw Exception(data['error']);
        }
      } catch (_) {
        await supabase.rpc('support_argument', params: {
          'p_argument_id': argumentId,
          'p_amount': amount,
        });
        await RecommendationService().recordEvent(
          eventType: 'support',
          targetType: 'argument',
          targetId: argumentId,
          metadata: {'amount': amount},
        );
      }
    }
    await BadgeService().recordEvent(
      badgeKey: 'community',
      eventType: 'argument_support',
      xpGained: 2,
      referenceKey:
          'support:$argumentId:$amount:${DateTime.now().millisecondsSinceEpoch}',
    );
    if (ownerUserId != null) {
      final user = await UserService().getProfile();
      if (user != null && ownerUserId != user.id) {
        NotificationService().send(
          toUserId: ownerUserId,
          type: 'argument_support',
          title: '@${user.username} sipòte agiman ou ak $amount coins',
          relatedTable: 'arguments',
          relatedId: argumentId,
        );
      }
    }
  }

  /// Gifts coins to any user (creator, argument author, etc.).
  /// Returns the gifting result including animation intensity.
  Future<Map<String, dynamic>> giftCoins({
    required String receiverUserId,
    required int coins,
    String contextType = 'creator',
    String? contextId,
    bool isPublic = true,
  }) async {
    final result = await supabase.rpc('gift_coins', params: {
      'p_receiver_id': receiverUserId,
      'p_coins': coins,
      'p_context_type': contextType,
      'p_context_id': contextId,
      'p_is_public': isPublic,
    });
    await RecommendationService().recordEvent(
      eventType: 'support',
      targetType: contextType,
      targetId: contextId ?? receiverUserId,
      metadata: {'coins': coins},
    );
    await BadgeService().recordEvent(
      badgeKey: 'community',
      eventType: 'coin_gift',
      xpGained: 2,
      referenceKey:
          'gift:$receiverUserId:${contextId ?? receiverUserId}:$coins:${DateTime.now().millisecondsSinceEpoch}',
    );
    return Map<String, dynamic>.from(result as Map);
  }

  /// Loads support level tiers from DB (falls back to defaults).
  Future<List<SupportLevelModel>> getSupportLevels() async {
    try {
      final data = await supabase
          .from('coin_support_levels')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      return (data as List).map((j) => SupportLevelModel.fromJson(j)).toList();
    } catch (_) {
      return SupportLevelModel.defaults;
    }
  }

  /// Top supporters for a creator (last 30 days).
  Future<List<TopSupporterModel>> getTopSupporters(String creatorUserId) async {
    try {
      final data = await supabase.rpc('get_top_supporters', params: {
        'p_creator_id': creatorUserId,
        'p_limit': 5,
      });
      return (data as List).map((j) => TopSupporterModel.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Public gifting feed (last N events across the platform).
  Future<List<GiftingEventModel>> getPublicGiftingFeed({int limit = 20}) async {
    try {
      final data = await supabase.rpc('get_public_gifting_feed', params: {
        'p_limit': limit,
      });
      return (data as List).map((j) => GiftingEventModel.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> transferCoins({
    required String receiverUserId,
    required int amount,
  }) async {
    final economy = await getEconomyConfig();
    try {
      final res = await supabase.functions.invoke('transfer-coins', body: {
        'receiver_user_id': receiverUserId,
        'amount': amount,
        'fee': economy.transferFee,
        'transaction_type': 'transfer',
      });
      final data = res.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error']);
      }
    } catch (_) {
      await supabase.rpc('transfer_coins', params: {
        'p_receiver_user_id': receiverUserId,
        'p_amount': amount,
      });
    }
  }
}

class BadgeService {
  static const List<Map<String, dynamic>> _fallbackBadges = [
    {
      'id': 'top_voter',
      'key': 'top_voter',
      'name_ht': 'Top Votè',
      'name_en': 'Top Voter',
      'description_ht': 'Vote sou matchups pou monte nivo ou.',
      'description_en': 'Vote on matchups to level up.',
      'icon_asset': 'assets/images/topvote.png',
      'color_hex': '#A855F7',
      'sort_order': 1,
    },
    {
      'id': 'hot_streak',
      'key': 'hot_streak',
      'name_ht': 'San Kanpe',
      'name_en': 'Hot Streak',
      'description_ht': 'Kenbe aktivite ou vivan chak jou.',
      'description_en': 'Keep your participation streak alive.',
      'icon_asset': 'assets/images/sankanpe.png',
      'color_hex': '#F97316',
      'sort_order': 2,
    },
    {
      'id': 'debater',
      'key': 'debater',
      'name_ht': 'Gran Debatè',
      'name_en': 'Debater',
      'description_ht': 'Ekri agiman ki fè diskisyon an pi rich.',
      'description_en': 'Post arguments that strengthen the debate.',
      'icon_asset': 'assets/images/grandebate.png',
      'color_hex': '#3B82F6',
      'sort_order': 3,
    },
    {
      'id': 'consistent',
      'key': 'consistent',
      'name_ht': 'Konsistan',
      'name_en': 'Consistent',
      'description_ht': 'Patisipe regilyèman semèn apre semèn.',
      'description_en': 'Participate reliably week after week.',
      'icon_asset': 'assets/images/konsistan.png',
      'color_hex': '#22C55E',
      'sort_order': 4,
    },
    {
      'id': 'community',
      'key': 'community',
      'name_ht': 'Gran Sipòtè',
      'name_en': 'Great Supporter',
      'description_ht': 'Sipòte lòt moun epi fè kominote a grandi.',
      'description_en': 'Support others and help the community grow.',
      'icon_asset': 'assets/images/sipote.png',
      'color_hex': '#D90C82',
      'sort_order': 5,
    },
  ];

  static const Map<String, List<int>> _levelThresholds = {
    'top_voter': [10, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 25000],
    'hot_streak': [3, 7, 14, 21, 30, 45, 60, 90, 180, 365],
    'debater': [5, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000],
    'consistent': [1, 2, 4, 8, 12, 24, 36, 52, 104, 156],
    'community': [10, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 25000],
  };

  List<BadgeProgressModel> fallbackProgress() {
    final badges = _fallbackBadges.map(BadgeModel.fromJson).toList();
    return badges.map((badge) {
      final levels = _fallbackLevels(badge.id);
      return BadgeProgressModel(
        badge: badge,
        nextLevel: levels.first,
      );
    }).toList();
  }

  Future<List<BadgeProgressModel>> getUserBadges({String? userId}) async {
    try {
      final currentUser =
          userId == null ? await UserService().getProfile() : null;
      final targetUserId = userId ?? currentUser?.id;
      final badgeRows = await supabase
          .from('badges')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      final badges = (badgeRows as List)
          .map((j) => BadgeModel.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
      if (badges.isEmpty) return fallbackProgress();

      final levelRows = await supabase
          .from('badge_levels')
          .select()
          .order('level', ascending: true);
      final levels = (levelRows as List)
          .map((j) =>
              BadgeLevelModel.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();

      List<UserBadgeModel> userBadges = [];
      if (targetUserId != null) {
        final progressRows = await supabase
            .from('user_badges')
            .select()
            .eq('user_id', targetUserId);
        userBadges = (progressRows as List)
            .map((j) =>
                UserBadgeModel.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList();
      }

      return badges.map((badge) {
        final badgeLevels =
            levels.where((level) => level.badgeId == badge.id).toList();
        final progress = userBadges
            .where((userBadge) => userBadge.badgeId == badge.id)
            .firstOrNull;
        final currentLevel = badgeLevels
            .where((level) => level.level == (progress?.currentLevel ?? 0))
            .firstOrNull;
        final nextLevel = badgeLevels
            .where((level) => level.level > (progress?.currentLevel ?? 0))
            .firstOrNull;
        return BadgeProgressModel(
          badge: badge,
          progress: progress,
          currentLevel: currentLevel,
          nextLevel: nextLevel,
        );
      }).toList();
    } catch (_) {
      return fallbackProgress();
    }
  }

  Future<BadgeEventResult?> recordEvent({
    required String badgeKey,
    required String eventType,
    required int xpGained,
    String? referenceId,
    String? referenceKey,
  }) async {
    try {
      final data = await supabase.rpc(
        referenceKey == null ? 'record_badge_event' : 'record_badge_event_v2',
        params: {
          'p_badge_key': badgeKey,
          'p_event_type': eventType,
          'p_xp_gained': xpGained,
          'p_reference_id': referenceId,
          if (referenceKey != null) 'p_reference_key': referenceKey,
        },
      );
      if (data is Map) {
        final result =
            BadgeEventResult.fromJson(Map<String, dynamic>.from(data));
        if (result.leveledUp) {
          AppSoundService.play(AppSound.badgeUnlock);
          BadgeUnlockEvents.show(result);
        }
        return result;
      }
    } catch (_) {
      // Badge progress is nice-to-have and should not block core actions.
    }
    return null;
  }

  List<BadgeLevelModel> _fallbackLevels(String badgeId) {
    final thresholds =
        _levelThresholds[badgeId] ?? _levelThresholds['top_voter']!;
    return thresholds.indexed.map((entry) {
      final level = entry.$1 + 1;
      final requiredXp = entry.$2;
      return BadgeLevelModel(
        id: '$badgeId-$level',
        badgeId: badgeId,
        level: level,
        requiredXp: requiredXp,
        titleHt: 'Nivo $level',
        titleEn: 'Level $level',
        influenceReward: level * 5,
      );
    }).toList();
  }
}

class PredictionService {
  Future<List<PredictionModel>> getPredictions() async {
    final data = await supabase
        .from('predictions')
        .select('*, category:categories(*)')
        .inFilter('status', ['active', 'closed', 'resolved']).order(
            'deadline_at');
    return (data as List).map((j) => PredictionModel.fromJson(j)).toList();
  }

  Future<PredictionModel?> getPredictionDetail(String id) async {
    final data = await supabase
        .from('predictions')
        .select('*, category:categories(*)')
        .eq('id', id)
        .single();
    return PredictionModel.fromJson(data);
  }

  Future<void> submitPrediction({
    required String predictionId,
    required String selectedOption,
    String? argumentBody,
  }) async {
    final user = await UserService().getProfile();
    if (user == null) return;
    await supabase.from('prediction_votes').insert({
      'prediction_id': predictionId,
      'user_id': user.id,
      'selected_option': selectedOption,
      'argument_body': argumentBody,
    });
    await RecommendationService().recordEvent(
      eventType: 'prediction_vote',
      targetType: 'prediction',
      targetId: predictionId,
    );
  }

  Future<Map<String, dynamic>?> getUserPredictionVote(
      String predictionId) async {
    final user = await UserService().getProfile();
    if (user == null) return null;
    return supabase
        .from('prediction_votes')
        .select()
        .eq('prediction_id', predictionId)
        .eq('user_id', user.id)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> getPredictionVotes(
      String predictionId) async {
    final data = await supabase
        .from('prediction_votes')
        .select('selected_option')
        .eq('prediction_id', predictionId);
    return List<Map<String, dynamic>>.from(data);
  }
}

class NotificationService {
  Future<List<NotificationModel>> getNotifications(
      {bool unreadOnly = false}) async {
    final user = await UserService().getProfile();
    if (user == null) return [];
    var q = supabase.from('notifications').select().eq('user_id', user.id);
    if (unreadOnly) q = q.eq('is_read', false);
    final data = await q.order('created_at', ascending: false).limit(50);
    return (data as List).map((j) => NotificationModel.fromJson(j)).toList();
  }

  Future<int> getUnreadCount() async {
    final user = await UserService().getProfile();
    if (user == null) return 0;
    final data = await supabase
        .from('notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_read', false);
    return (data as List).length;
  }

  Future<void> markAllRead() async {
    final user = await UserService().getProfile();
    if (user == null) return;
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_read', false);
  }

  Future<void> markRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> send({
    required String toUserId,
    required String type,
    required String title,
    String? body,
    String? relatedTable,
    String? relatedId,
  }) async {
    try {
      await supabase.from('notifications').insert({
        'user_id': toUserId,
        'type': type,
        'title': title,
        if (body != null) 'body': body,
        if (relatedTable != null) 'related_table': relatedTable,
        if (relatedId != null) 'related_id': relatedId,
        'is_read': false,
      });
    } catch (e) {
      debugPrint('sendNotification error: $e');
    }
  }
}

class BoostService {
  Future<Map<String, dynamic>> createBoost({
    required String argumentId,
    required String tier,
    bool useFreCredit = false,
    bool useCoins = false,
    int? coinCost,
  }) async {
    try {
      final res = await supabase.functions.invoke('boost-argument', body: {
        'argument_id': argumentId,
        'tier': tier,
        'use_free_credit': useFreCredit,
        'use_coins': useCoins,
        if (coinCost != null) 'coin_cost': coinCost,
        'transaction_type': useCoins ? 'boost_spend' : 'boost',
      });
      await RecommendationService().recordEvent(
        eventType: 'boost',
        targetType: 'argument',
        targetId: argumentId,
      );
      AppSoundService.play(AppSound.boost);
      return Map<String, dynamic>.from(res.data as Map);
    } catch (_) {
      final data = await supabase.rpc('boost_argument', params: {
        'p_argument_id': argumentId,
        'p_tier': tier,
        'p_use_free_credit': useFreCredit,
        'p_use_coins': useCoins,
        'p_coin_cost': coinCost,
      });
      await RecommendationService().recordEvent(
        eventType: 'boost',
        targetType: 'argument',
        targetId: argumentId,
      );
      AppSoundService.play(AppSound.boost);
      return Map<String, dynamic>.from(data as Map);
    }
  }
}

class AdminService {
  Future<List<AiDraftModel>> getPendingDrafts() async {
    final data = await supabase
        .from('ai_generated_drafts')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (data as List).map((j) => AiDraftModel.fromJson(j)).toList();
  }

  Future<void> approveDraft(String draftId,
      {Map<String, dynamic>? edits, String? scheduleAt}) async {
    await supabase.functions.invoke('approve-ai-draft', body: {
      'draft_id': draftId,
      'action': 'approve',
      if (edits != null) 'edits': edits,
      if (scheduleAt != null) 'schedule_at': scheduleAt,
    });
  }

  Future<void> rejectDraft(String draftId, {String? notes}) async {
    await supabase.functions.invoke('approve-ai-draft', body: {
      'draft_id': draftId,
      'action': 'reject',
      if (notes != null) 'notes': notes,
    });
  }

  Future<List<MatchupModel>> getAllMatchups() async {
    final data = await supabase
        .from('matchups')
        .select('*, category:categories(*), options:matchup_options(*)')
        .order('created_at', ascending: false);
    return (data as List).map((j) => MatchupModel.fromJson(j)).toList();
  }

  Future<void> createMatchup({
    required String categoryId,
    required String titleHt,
    required String optionA,
    required String optionB,
    String? titleEn,
    String? descriptionHt,
    bool publish = false,
  }) async {
    final user = await UserService().getProfile();
    final matchup = await supabase
        .from('matchups')
        .insert({
          'category_id': categoryId,
          'title_ht': titleHt,
          'title_en': titleEn,
          'description_ht': descriptionHt,
          'status': publish ? 'published' : 'draft',
          'source_type': 'admin',
          'created_by_admin': user?.id,
          if (publish) 'published_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    await supabase.from('matchup_options').insert([
      {
        'matchup_id': matchup['id'],
        'option_label': 'A',
        'option_name': optionA
      },
      {
        'matchup_id': matchup['id'],
        'option_label': 'B',
        'option_name': optionB
      },
    ]);
  }

  Future<void> publishMatchup(String matchupId) async {
    await supabase.from('matchups').update({
      'status': 'published',
      'published_at': DateTime.now().toIso8601String(),
    }).eq('id', matchupId);
  }

  Future<void> unpublishMatchup(String matchupId) async {
    await supabase
        .from('matchups')
        .update({'status': 'draft'}).eq('id', matchupId);
  }

  Future<List<Map<String, dynamic>>> getPendingReports() async {
    final data = await supabase
        .from('reports')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<UserModel>> getUsers({int limit = 50}) async {
    final data = await supabase
        .from('users')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((j) => UserModel.fromJson(j)).toList();
  }

  Future<List<VerificationRequestModel>> getVerificationRequests() async {
    final data = await supabase
        .from('verification_requests')
        .select(
            '*, user:users!verification_requests_user_id_fkey(*), documents:verification_documents!verification_documents_verification_request_id_fkey(*)')
        .order('submitted_at', ascending: false);
    return (data as List)
        .map((j) => VerificationRequestModel.fromJson(j))
        .toList();
  }

  Future<void> approveVerificationRequest(VerificationRequestModel request,
      {String? adminNotes}) async {
    final admin = await UserService().getProfile();
    final badgeStyle = _badgeStyleForType(request.verificationType);
    final now = DateTime.now().toIso8601String();

    await supabase.from('user_verifications').upsert({
      'user_id': request.userId,
      'verification_type': request.verificationType,
      'badge_style': badgeStyle,
      'status': 'approved',
      'granted_by': admin?.id,
      'granted_at': now,
      'updated_at': now,
    }, onConflict: 'user_id,verification_type');

    await supabase.from('users').update({
      'verification_type': request.verificationType,
      'verification_badge_style': badgeStyle,
      'verification_status': 'approved',
    }).eq('id', request.userId);

    await supabase.from('verification_requests').update({
      'status': 'approved',
      'admin_notes': adminNotes,
      'reviewed_by': admin?.id,
      'reviewed_at': now,
      'updated_at': now,
    }).eq('id', request.id);

    await _notifyVerificationResult(
      request.userId,
      title: 'Kont ou verifye',
      body: 'Demann verifikasyon ou a apwouve.',
    );
  }

  Future<void> rejectVerificationRequest(VerificationRequestModel request,
      {String? reason}) async {
    final admin = await UserService().getProfile();
    final now = DateTime.now().toIso8601String();
    await supabase.from('verification_requests').update({
      'status': 'rejected',
      'rejection_reason': reason,
      'reviewed_by': admin?.id,
      'reviewed_at': now,
      'updated_at': now,
    }).eq('id', request.id);

    await supabase
        .from('users')
        .update({
          'verification_status': 'rejected',
        })
        .eq('id', request.userId)
        .neq('verification_status', 'approved');

    await _notifyVerificationResult(
      request.userId,
      title: 'Verifikasyon pa apwouve',
      body: reason?.isNotEmpty == true
          ? reason!
          : 'Demann verifikasyon ou a pa apwouve pou kounye a.',
    );
  }

  Future<void> revokeVerification(UserModel user, {String? reason}) async {
    final admin = await UserService().getProfile();
    final now = DateTime.now().toIso8601String();

    await supabase
        .from('user_verifications')
        .update({
          'status': 'revoked',
          'revoked_at': now,
          'revoked_by': admin?.id,
          'revocation_reason': reason,
          'updated_at': now,
        })
        .eq('user_id', user.id)
        .eq('status', 'approved');

    await supabase.from('users').update({
      'verification_type': null,
      'verification_badge_style': null,
      'verification_status': 'revoked',
    }).eq('id', user.id);

    await _notifyVerificationResult(
      user.id,
      title: 'Verifikasyon retire',
      body: reason?.isNotEmpty == true
          ? reason!
          : 'Badj verifikasyon ou a retire.',
    );
  }

  Future<String> createVerificationDocumentUrl(String documentPath) async {
    return supabase.storage
        .from('verification-documents')
        .createSignedUrl(documentPath, 60 * 10);
  }

  String _badgeStyleForType(String type) {
    switch (type) {
      case 'organization':
        return 'business';
      case 'public_figure':
        return 'gold';
      case 'trusted_creator':
        return 'silver';
      case 'admin':
        return 'verified';
      default:
        return 'standard';
    }
  }

  Future<void> _notifyVerificationResult(
    String userId, {
    required String title,
    required String body,
  }) async {
    try {
      await NotificationService().send(
        toUserId: userId,
        type: 'system',
        title: title,
        body: body,
        relatedTable: 'verification_requests',
      );
    } catch (_) {
      // Notifications should not block moderation actions.
    }
  }

  Future<void> runTrendScan() async {
    await supabase.functions.invoke('run-trend-scan');
  }

  Future<void> createPrediction({
    required String categoryId,
    required String titleHt,
    required String optionA,
    required String optionB,
    required DateTime deadline,
    String? descriptionHt,
  }) async {
    final user = await UserService().getProfile();
    await supabase.from('predictions').insert({
      'category_id': categoryId,
      'title_ht': titleHt,
      'option_a': optionA,
      'option_b': optionB,
      'description_ht': descriptionHt,
      'deadline_at': deadline.toIso8601String(),
      'status': 'active',
      'source_type': 'admin',
      'created_by_admin': user?.id,
    });
  }

  Future<List<PredictionModel>> getAllPredictions() async {
    final data = await supabase
        .from('predictions')
        .select('*, category:categories(*)')
        .order('created_at', ascending: false);
    return (data as List).map((j) => PredictionModel.fromJson(j)).toList();
  }

  Future<List<CategoryModel>> getCategories() async {
    final data = await supabase.from('categories').select().order('sort_order');
    return (data as List).map((j) => CategoryModel.fromJson(j)).toList();
  }

  Future<void> addCategory(String nameHt, String nameEn, String icon) async {
    await supabase
        .from('categories')
        .insert({'name_ht': nameHt, 'name_en': nameEn, 'icon': icon});
  }
}

// ─────────────────────────────────────────────────────────
// CreatorService
// ─────────────────────────────────────────────────────────
class CreatorService {
  /// Returns the signed-in user's creator profile row.
  Future<CreatorProfileModel?> getMyProfile() async {
    final user = await UserService().getProfile();
    if (user == null) return null;

    final data = await supabase
        .from('creator_profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return CreatorProfileModel.fromJson(data);
  }

  /// Returns the full creator dashboard stats via RPC.
  Future<CreatorDashboardModel?> getDashboard() async {
    final user = await UserService().getProfile();
    if (user == null) return null;

    final result = await supabase.rpc(
      'get_creator_dashboard',
      params: {'p_user_id': user.id},
    );
    if (result == null) return null;
    return CreatorDashboardModel.fromJson(Map<String, dynamic>.from(result));
  }

  /// Recalculates the score and auto-upgrades tier if eligible.
  /// Safe to call after any significant user action.
  Future<int?> refreshTier() async {
    final user = await UserService().getProfile();
    if (user == null) return null;

    final result = await supabase.rpc(
      'refresh_creator_tier',
      params: {'p_user_id': user.id},
    );
    return result as int?;
  }

  /// Returns a public creator profile for any user by their users.id.
  Future<CreatorProfileModel?> getProfileForUser(String userId) async {
    final data = await supabase
        .from('creator_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;
    return CreatorProfileModel.fromJson(data);
  }

  /// Returns recent revenue events for the signed-in creator.
  Future<List<CreatorRevenueEventModel>> getRevenueEvents(
      {int limit = 30}) async {
    final user = await UserService().getProfile();
    if (user == null) return [];

    final data = await supabase
        .from('creator_revenue_events')
        .select()
        .eq('creator_user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((j) => CreatorRevenueEventModel.fromJson(j))
        .toList();
  }

  /// Requests a payout of pending coins. Admin processes it manually or via MonCash.
  Future<void> requestPayout({
    required int coinsAmount,
    required String payoutMethod,
    String? payoutPhone,
    double? estimatedUsd,
  }) async {
    final user = await UserService().getProfile();
    if (user == null) throw Exception('Not signed in');

    await supabase.from('creator_payouts').insert({
      'creator_user_id': user.id,
      'coins_amount': coinsAmount,
      'payout_method': payoutMethod,
      'payout_phone': payoutPhone,
      'estimated_usd': estimatedUsd,
      'status': 'pending',
    });
  }
}

class VerificationService {
  Future<List<VerificationRequestModel>> getMyRequests() async {
    final user = await UserService().getProfile();
    if (user == null) return [];

    final data = await supabase
        .from('verification_requests')
        .select(
            '*, documents:verification_documents!verification_documents_verification_request_id_fkey(*)')
        .eq('user_id', user.id)
        .order('submitted_at', ascending: false);
    return (data as List)
        .map((j) => VerificationRequestModel.fromJson(j))
        .toList();
  }

  Future<VerificationRequestModel> submitRequest({
    required String verificationType,
    String? displayName,
    String? legalName,
    String? organizationName,
    String? website,
    String? organizationEmail,
    String? socialLinks,
    String? proofNotes,
  }) async {
    final user = await UserService().getProfile();
    if (user == null) throw Exception('User profile not found');

    final row = await supabase
        .from('verification_requests')
        .insert({
          'user_id': user.id,
          'verification_type': verificationType,
          'status': 'pending',
          'display_name': displayName,
          'legal_name': legalName,
          'organization_name': organizationName,
          'website': website,
          'organization_email': organizationEmail,
          'social_links': socialLinks,
          'proof_notes': proofNotes,
        })
        .select()
        .single();

    await supabase
        .from('users')
        .update({'verification_status': 'pending'})
        .eq('id', user.id)
        .neq('verification_status', 'approved');

    return VerificationRequestModel.fromJson(row);
  }

  Future<void> uploadDocument({
    required String requestId,
    required Uint8List bytes,
    required String fileName,
    String documentType = 'proof',
  }) async {
    final authUser = supabase.auth.currentUser;
    final user = await UserService().getProfile();
    if (authUser == null || user == null) {
      throw Exception('User profile not found');
    }

    final extension = fileName.split('.').last.toLowerCase();
    final safeExtension =
        ['jpg', 'jpeg', 'png', 'webp'].contains(extension) ? extension : 'jpg';
    final path =
        '${authUser.id}/$requestId/${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
    final contentType = switch (safeExtension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    await supabase.storage.from('verification-documents').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );

    await supabase.from('verification_documents').insert({
      'verification_request_id': requestId,
      'user_id': user.id,
      'document_type': documentType,
      'document_url': path,
    });
  }
}
