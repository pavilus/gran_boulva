// All Gran Boulva data models

class UserModel {
  final String id;
  final String authUserId;
  final String fullName;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final String language;
  final String referralCode;
  final int influenceScore;
  final int participationCount;
  final int victoryCount;
  final int followersCount;
  final int followingCount;
  final int freeBoostCredits;
  final int coinBalance;
  final int totalSupportGiven;
  final int totalSupportReceived;
  final int totalCoinsSpent;
  final int totalCoinsTransferred;
  final int totalBoostsUsed;
  final String role;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.authUserId,
    required this.fullName,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.bio,
    required this.language,
    required this.referralCode,
    required this.influenceScore,
    required this.participationCount,
    required this.victoryCount,
    required this.followersCount,
    required this.followingCount,
    required this.freeBoostCredits,
    this.coinBalance = 0,
    this.totalSupportGiven = 0,
    this.totalSupportReceived = 0,
    this.totalCoinsSpent = 0,
    this.totalCoinsTransferred = 0,
    this.totalBoostsUsed = 0,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'],
        authUserId: j['auth_user_id'],
        fullName: j['full_name'],
        username: j['username'],
        email: j['email'],
        avatarUrl: j['avatar_url'],
        bio: j['bio'],
        language: j['language'] ?? 'ht',
        referralCode: j['referral_code'] ?? '',
        influenceScore: j['influence_score'] ?? 0,
        participationCount: j['participation_count'] ?? 0,
        victoryCount: j['victory_count'] ?? 0,
        followersCount: j['followers_count'] ?? 0,
        followingCount: j['following_count'] ?? 0,
        freeBoostCredits: j['free_boost_credits'] ?? 0,
        coinBalance: j['coin_balance'] ?? 0,
        totalSupportGiven: j['total_support_given'] ?? 0,
        totalSupportReceived: j['total_support_received'] ?? 0,
        totalCoinsSpent: j['total_coins_spent'] ?? 0,
        totalCoinsTransferred: j['total_coins_transferred'] ?? 0,
        totalBoostsUsed: j['total_boosts_used'] ?? 0,
        role: j['role'] ?? 'user',
        createdAt: DateTime.parse(j['created_at']),
      );

  bool get isAdmin => role == 'admin' || role == 'moderator';
}

class CategoryModel {
  final String id;
  final String nameHt;
  final String nameEn;
  final String? icon;

  const CategoryModel(
      {required this.id,
      required this.nameHt,
      required this.nameEn,
      this.icon});

  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
        id: j['id'],
        nameHt: j['name_ht'],
        nameEn: j['name_en'],
        icon: j['icon'],
      );
}

class MatchupOptionModel {
  final String id;
  final String matchupId;
  final String optionLabel;
  final String optionName;
  final String? imageUrl;
  final int voteCount;

  const MatchupOptionModel({
    required this.id,
    required this.matchupId,
    required this.optionLabel,
    required this.optionName,
    this.imageUrl,
    required this.voteCount,
  });

  factory MatchupOptionModel.fromJson(Map<String, dynamic> j) =>
      MatchupOptionModel(
        id: j['id'],
        matchupId: j['matchup_id'],
        optionLabel: j['option_label'],
        optionName: j['option_name'],
        imageUrl: j['image_url'],
        voteCount: j['vote_count'] ?? 0,
      );
}

class MatchupModel {
  final String id;
  final String categoryId;
  final String titleHt;
  final String? titleEn;
  final String? descriptionHt;
  final String status;
  final int totalVotes;
  final int engagementScore;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final CategoryModel? category;
  final List<MatchupOptionModel> options;
  final int argumentCount;
  final String? myVoteOptionId;
  final bool isSaved;

  const MatchupModel({
    required this.id,
    required this.categoryId,
    required this.titleHt,
    this.titleEn,
    this.descriptionHt,
    required this.status,
    required this.totalVotes,
    required this.engagementScore,
    this.publishedAt,
    this.expiresAt,
    this.category,
    required this.options,
    this.argumentCount = 0,
    this.myVoteOptionId,
    this.isSaved = false,
  });

  factory MatchupModel.fromJson(Map<String, dynamic> j) {
    List<MatchupOptionModel> opts = [];
    if (j['options'] != null) {
      opts = (j['options'] as List)
          .map((o) => MatchupOptionModel.fromJson(o))
          .toList();
    }
    if (j['matchup_options'] != null) {
      opts = (j['matchup_options'] as List)
          .map((o) => MatchupOptionModel.fromJson(o))
          .toList();
    }

    CategoryModel? cat;
    if (j['category'] != null) cat = CategoryModel.fromJson(j['category']);

    return MatchupModel(
      id: j['id'],
      categoryId: j['category_id'],
      titleHt: j['title_ht'],
      titleEn: j['title_en'],
      descriptionHt: j['description_ht'],
      status: j['status'] ?? 'published',
      totalVotes: j['total_votes'] ?? 0,
      engagementScore: j['engagement_score'] ?? 0,
      publishedAt:
          j['published_at'] != null ? DateTime.parse(j['published_at']) : null,
      expiresAt:
          j['expires_at'] != null ? DateTime.parse(j['expires_at']) : null,
      category: cat,
      options: opts,
      argumentCount: j['argument_count'] ?? 0,
      myVoteOptionId: j['my_vote_option_id'],
      isSaved: j['is_saved'] ?? false,
    );
  }

  double get optionAPercent {
    if (totalVotes == 0 || options.isEmpty) return 50;
    final a = options.firstWhere((o) => o.optionLabel == 'A',
        orElse: () => options.first);
    return (a.voteCount / totalVotes) * 100;
  }

  double get optionBPercent => 100 - optionAPercent;

  MatchupOptionModel? get optionA {
    if (options.isEmpty) return null;
    try {
      return options.firstWhere((o) => o.optionLabel == 'A');
    } catch (_) {
      return options.first;
    }
  }

  MatchupOptionModel? get optionB {
    if (options.length < 2) return null;
    try {
      return options.firstWhere((o) => o.optionLabel == 'B');
    } catch (_) {
      return options.last;
    }
  }

  bool get hasVoted => myVoteOptionId != null;
}

class ArgumentModel {
  final String id;
  final String userId;
  final String matchupId;
  final String optionId;
  final String body;
  final int likeCount;
  final int dislikeCount;
  final int replyCount;
  final DateTime? boostExpiresAt;
  final int visibilityScore;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? option;
  final String? myReaction;
  final bool isBoosted;
  final int supportCount;
  final int supportCoins;

  const ArgumentModel({
    required this.id,
    required this.userId,
    required this.matchupId,
    required this.optionId,
    required this.body,
    required this.likeCount,
    required this.dislikeCount,
    required this.replyCount,
    this.boostExpiresAt,
    required this.visibilityScore,
    required this.status,
    required this.createdAt,
    this.user,
    this.option,
    this.myReaction,
    this.isBoosted = false,
    this.supportCount = 0,
    this.supportCoins = 0,
  });

  factory ArgumentModel.fromJson(Map<String, dynamic> j) => ArgumentModel(
        id: j['id'],
        userId: j['user_id'],
        matchupId: j['matchup_id'],
        optionId: j['option_id'],
        body: j['body'],
        likeCount: j['like_count'] ?? 0,
        dislikeCount: j['dislike_count'] ?? 0,
        replyCount: j['reply_count'] ?? 0,
        boostExpiresAt: j['boost_expires_at'] != null
            ? DateTime.parse(j['boost_expires_at'])
            : null,
        visibilityScore: j['visibility_score'] ?? 0,
        status: j['status'] ?? 'active',
        createdAt: DateTime.parse(j['created_at']),
        user: j['user'],
        option: j['option'],
        myReaction: j['my_reaction'],
        isBoosted: j['is_boosted'] ?? false,
        supportCount: j['support_count'] ?? j['supporter_count'] ?? 0,
        supportCoins: j['support_coins'] ?? j['total_support_coins'] ?? 0,
      );

  String get username => user?['username'] ?? 'Itilizatè';
  String? get userAvatar => user?['avatar_url'];
  String get optionLabel => option?['option_label'] ?? '';
  String get optionName => option?['option_name'] ?? '';

  double get finalRankingScore {
    final age = DateTime.now().difference(createdAt);
    final recencyScore = age.inHours < 2
        ? 15
        : age.inHours < 12
            ? 10
            : age.inHours < 24
                ? 5
                : 0;
    final boostScore = isBoosted ? 60 : 0;
    final supportScore = supportCoins * 0.3;
    return visibilityScore +
        boostScore +
        (likeCount * 2) +
        (replyCount * 5) +
        supportScore +
        recencyScore;
  }
}

class CoinTransactionModel {
  final String id;
  final int amount;
  final int fee;
  final String transactionType;
  final String status;
  final DateTime createdAt;

  const CoinTransactionModel({
    required this.id,
    required this.amount,
    required this.fee,
    required this.transactionType,
    required this.status,
    required this.createdAt,
  });

  factory CoinTransactionModel.fromJson(Map<String, dynamic> j) =>
      CoinTransactionModel(
        id: j['id'],
        amount: j['amount'] ?? 0,
        fee: j['fee'] ?? 0,
        transactionType: j['transaction_type'] ?? j['type'] ?? 'unknown',
        status: j['status'] ?? 'completed',
        createdAt: DateTime.parse(j['created_at']),
      );
}

class BadgeModel {
  final String id;
  final String key;
  final String nameHt;
  final String nameEn;
  final String descriptionHt;
  final String descriptionEn;
  final String iconAsset;
  final String colorHex;
  final int sortOrder;

  const BadgeModel({
    required this.id,
    required this.key,
    required this.nameHt,
    required this.nameEn,
    required this.descriptionHt,
    required this.descriptionEn,
    required this.iconAsset,
    required this.colorHex,
    required this.sortOrder,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> j) => BadgeModel(
        id: j['id'] ?? j['key'] ?? '',
        key: j['key'] ?? j['badge_key'] ?? '',
        nameHt: j['name_ht'] ?? j['name'] ?? '',
        nameEn: j['name_en'] ?? j['name'] ?? '',
        descriptionHt: j['description_ht'] ?? j['description'] ?? '',
        descriptionEn: j['description_en'] ?? j['description'] ?? '',
        iconAsset: j['icon_asset'] ?? j['image_asset'] ?? '',
        colorHex: j['color_hex'] ?? '#A855F7',
        sortOrder: j['sort_order'] ?? 0,
      );
}

class BadgeLevelModel {
  final String id;
  final String badgeId;
  final int level;
  final int requiredXp;
  final String titleHt;
  final String titleEn;
  final int influenceReward;

  const BadgeLevelModel({
    required this.id,
    required this.badgeId,
    required this.level,
    required this.requiredXp,
    required this.titleHt,
    required this.titleEn,
    required this.influenceReward,
  });

  factory BadgeLevelModel.fromJson(Map<String, dynamic> j) => BadgeLevelModel(
        id: j['id'] ?? '',
        badgeId: j['badge_id'] ?? '',
        level: j['level'] ?? 0,
        requiredXp: j['required_xp'] ?? 0,
        titleHt: j['title_ht'] ?? '',
        titleEn: j['title_en'] ?? '',
        influenceReward: j['influence_reward'] ?? 0,
      );
}

class UserBadgeModel {
  final String id;
  final String userId;
  final String badgeId;
  final int currentXp;
  final int currentLevel;
  final bool isFeatured;
  final DateTime? earnedAt;

  const UserBadgeModel({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.currentXp,
    required this.currentLevel,
    required this.isFeatured,
    this.earnedAt,
  });

  factory UserBadgeModel.fromJson(Map<String, dynamic> j) => UserBadgeModel(
        id: j['id'] ?? '',
        userId: j['user_id'] ?? '',
        badgeId: j['badge_id'] ?? '',
        currentXp: j['current_xp'] ?? 0,
        currentLevel: j['current_level'] ?? 0,
        isFeatured: j['is_featured'] ?? false,
        earnedAt:
            j['earned_at'] != null ? DateTime.tryParse(j['earned_at']) : null,
      );
}

class BadgeProgressModel {
  final BadgeModel badge;
  final UserBadgeModel? progress;
  final BadgeLevelModel? currentLevel;
  final BadgeLevelModel? nextLevel;

  const BadgeProgressModel({
    required this.badge,
    this.progress,
    this.currentLevel,
    this.nextLevel,
  });

  int get currentXp => progress?.currentXp ?? 0;
  int get level => progress?.currentLevel ?? 0;
  int get nextRequiredXp => nextLevel?.requiredXp ?? currentXp;
  bool get isMaxed => level >= 10 || nextLevel == null;

  double get progressRatio {
    if (isMaxed) return 1;
    final currentRequired = currentLevel?.requiredXp ?? 0;
    final nextRequired = nextLevel?.requiredXp ?? 1;
    final span = nextRequired - currentRequired;
    if (span <= 0) return 0;
    return ((currentXp - currentRequired) / span).clamp(0, 1).toDouble();
  }
}

class PredictionModel {
  final String id;
  final String categoryId;
  final String titleHt;
  final String? titleEn;
  final String? descriptionHt;
  final String optionA;
  final String optionB;
  final DateTime deadlineAt;
  final String status;
  final String? winningOption;
  final int totalVotes;
  final CategoryModel? category;
  final String? mySelectedOption;

  const PredictionModel({
    required this.id,
    required this.categoryId,
    required this.titleHt,
    this.titleEn,
    this.descriptionHt,
    required this.optionA,
    required this.optionB,
    required this.deadlineAt,
    required this.status,
    this.winningOption,
    required this.totalVotes,
    this.category,
    this.mySelectedOption,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> j) => PredictionModel(
        id: j['id'],
        categoryId: j['category_id'],
        titleHt: j['title_ht'],
        titleEn: j['title_en'],
        descriptionHt: j['description_ht'],
        optionA: j['option_a'],
        optionB: j['option_b'],
        deadlineAt: DateTime.parse(j['deadline_at']),
        status: j['status'] ?? 'active',
        winningOption: j['winning_option'],
        totalVotes: j['total_votes'] ?? 0,
        category: j['category'] != null
            ? CategoryModel.fromJson(j['category'])
            : null,
        mySelectedOption: j['my_selected_option'],
      );

  bool get isActive => status == 'active' || status == 'open';
  bool get isClosed => status == 'closed' || status == 'resolved';
  bool get hasParticipated => mySelectedOption != null;

  Duration get timeLeft => deadlineAt.difference(DateTime.now());
}

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String? body;
  final String? relatedTable;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.relatedTable,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
      NotificationModel(
        id: j['id'],
        userId: j['user_id'],
        type: j['type'],
        title: j['title'],
        body: j['body'],
        relatedTable: j['related_table'],
        relatedId: j['related_id'],
        isRead: j['is_read'] ?? false,
        createdAt: DateTime.parse(j['created_at']),
      );

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    String? relatedTable,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      relatedTable: relatedTable ?? this.relatedTable,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AiDraftModel {
  final String id;
  final String type;
  final String? categoryId;
  final String titleHt;
  final String? titleEn;
  final String optionA;
  final String optionB;
  final String? descriptionHt;
  final List<String> sourceLinks;
  final double? trendScore;
  final double? debateScore;
  final double? safetyScore;
  final String? riskLevel;
  final String status;
  final DateTime createdAt;

  const AiDraftModel({
    required this.id,
    required this.type,
    this.categoryId,
    required this.titleHt,
    this.titleEn,
    required this.optionA,
    required this.optionB,
    this.descriptionHt,
    required this.sourceLinks,
    this.trendScore,
    this.debateScore,
    this.safetyScore,
    this.riskLevel,
    required this.status,
    required this.createdAt,
  });

  factory AiDraftModel.fromJson(Map<String, dynamic> j) => AiDraftModel(
        id: j['id'],
        type: j['type'],
        categoryId: j['category_id'],
        titleHt: j['title_ht'],
        titleEn: j['title_en'],
        optionA: j['option_a'],
        optionB: j['option_b'],
        descriptionHt: j['description_ht'],
        sourceLinks: j['source_links'] != null
            ? List<String>.from(j['source_links'])
            : [],
        trendScore: (j['trend_score'] as num?)?.toDouble(),
        debateScore: (j['debate_score'] as num?)?.toDouble(),
        safetyScore: (j['safety_score'] as num?)?.toDouble(),
        riskLevel: j['risk_level'],
        status: j['status'] ?? 'pending',
        createdAt: DateTime.parse(j['created_at']),
      );
}

class TopVoiceModel {
  final String id;
  final String username;
  final String? avatarUrl;
  final int influenceScore;

  const TopVoiceModel(
      {required this.id,
      required this.username,
      this.avatarUrl,
      required this.influenceScore});

  factory TopVoiceModel.fromJson(Map<String, dynamic> j) => TopVoiceModel(
        id: j['id'],
        username: j['username'],
        avatarUrl: j['avatar_url'],
        influenceScore: j['influence_score'] ?? 0,
      );

  String get formattedScore {
    if (influenceScore >= 1000) {
      return '${(influenceScore / 1000).toStringAsFixed(1)}K';
    }
    return '$influenceScore';
  }
}
