// All Gran Boulva data models

class UserModel {
  final String id;
  final String authUserId;
  final String fullName;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? country;
  final String? phoneNumber;
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
  final String? verificationType;
  final String? verificationBadgeStyle;
  final String verificationStatus;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.authUserId,
    required this.fullName,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.gender,
    this.dateOfBirth,
    this.country,
    this.phoneNumber,
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
    this.verificationType,
    this.verificationBadgeStyle,
    this.verificationStatus = 'none',
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
        gender: j['gender'],
        dateOfBirth: j['date_of_birth'] == null
            ? null
            : DateTime.tryParse(j['date_of_birth']),
        country: j['country'],
        phoneNumber: j['phone_number'],
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
        verificationType: j['verification_type'],
        verificationBadgeStyle: j['verification_badge_style'],
        verificationStatus: j['verification_status'] ?? 'none',
        createdAt: DateTime.parse(j['created_at']),
      );

  bool get isAdmin => role == 'admin' || role == 'moderator';
  bool get isVerified =>
      verificationStatus == 'approved' && verificationType != null;

  UserModel copyWith({
    String? id,
    String? authUserId,
    String? fullName,
    String? username,
    String? email,
    String? avatarUrl,
    String? bio,
    String? gender,
    DateTime? dateOfBirth,
    String? country,
    String? phoneNumber,
    String? language,
    String? referralCode,
    int? influenceScore,
    int? participationCount,
    int? victoryCount,
    int? followersCount,
    int? followingCount,
    int? freeBoostCredits,
    int? coinBalance,
    int? totalSupportGiven,
    int? totalSupportReceived,
    int? totalCoinsSpent,
    int? totalCoinsTransferred,
    int? totalBoostsUsed,
    String? role,
    String? verificationType,
    String? verificationBadgeStyle,
    String? verificationStatus,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      authUserId: authUserId ?? this.authUserId,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      country: country ?? this.country,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      language: language ?? this.language,
      referralCode: referralCode ?? this.referralCode,
      influenceScore: influenceScore ?? this.influenceScore,
      participationCount: participationCount ?? this.participationCount,
      victoryCount: victoryCount ?? this.victoryCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      freeBoostCredits: freeBoostCredits ?? this.freeBoostCredits,
      coinBalance: coinBalance ?? this.coinBalance,
      totalSupportGiven: totalSupportGiven ?? this.totalSupportGiven,
      totalSupportReceived: totalSupportReceived ?? this.totalSupportReceived,
      totalCoinsSpent: totalCoinsSpent ?? this.totalCoinsSpent,
      totalCoinsTransferred:
          totalCoinsTransferred ?? this.totalCoinsTransferred,
      totalBoostsUsed: totalBoostsUsed ?? this.totalBoostsUsed,
      role: role ?? this.role,
      verificationType: verificationType ?? this.verificationType,
      verificationBadgeStyle:
          verificationBadgeStyle ?? this.verificationBadgeStyle,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class VerificationRequestModel {
  final String id;
  final String userId;
  final String verificationType;
  final String status;
  final String? displayName;
  final String? legalName;
  final String? organizationName;
  final String? website;
  final String? organizationEmail;
  final String? socialLinks;
  final String? proofNotes;
  final String? adminNotes;
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final UserModel? user;
  final List<VerificationDocumentModel> documents;

  const VerificationRequestModel({
    required this.id,
    required this.userId,
    required this.verificationType,
    required this.status,
    this.displayName,
    this.legalName,
    this.organizationName,
    this.website,
    this.organizationEmail,
    this.socialLinks,
    this.proofNotes,
    this.adminNotes,
    this.rejectionReason,
    required this.submittedAt,
    this.reviewedAt,
    this.user,
    this.documents = const [],
  });

  factory VerificationRequestModel.fromJson(Map<String, dynamic> j) {
    final userJson = j['user'];
    final documentJson = j['documents'] ?? j['verification_documents'];
    return VerificationRequestModel(
      id: j['id'],
      userId: j['user_id'],
      verificationType: j['verification_type'],
      status: j['status'] ?? 'pending',
      displayName: j['display_name'],
      legalName: j['legal_name'],
      organizationName: j['organization_name'],
      website: j['website'],
      organizationEmail: j['organization_email'],
      socialLinks: j['social_links'],
      proofNotes: j['proof_notes'],
      adminNotes: j['admin_notes'],
      rejectionReason: j['rejection_reason'],
      submittedAt: DateTime.parse(j['submitted_at'] ?? j['created_at']),
      reviewedAt:
          j['reviewed_at'] == null ? null : DateTime.tryParse(j['reviewed_at']),
      user: userJson is Map<String, dynamic>
          ? UserModel.fromJson(userJson)
          : userJson is Map
              ? UserModel.fromJson(Map<String, dynamic>.from(userJson))
              : null,
      documents: documentJson is List
          ? documentJson
              .map((doc) => VerificationDocumentModel.fromJson(
                  Map<String, dynamic>.from(doc)))
              .toList()
          : const [],
    );
  }

  String get typeLabel {
    switch (verificationType) {
      case 'public_figure':
        return 'Pèsonalite piblik';
      case 'organization':
        return 'Òganizasyon';
      case 'trusted_creator':
        return 'Kreyatè serye';
      case 'admin':
        return 'Ekip Gran Boulva';
      default:
        return 'Verifye';
    }
  }
}

class VerificationDocumentModel {
  final String id;
  final String requestId;
  final String userId;
  final String documentType;
  final String documentUrl;
  final DateTime createdAt;

  const VerificationDocumentModel({
    required this.id,
    required this.requestId,
    required this.userId,
    required this.documentType,
    required this.documentUrl,
    required this.createdAt,
  });

  factory VerificationDocumentModel.fromJson(Map<String, dynamic> j) =>
      VerificationDocumentModel(
        id: j['id'],
        requestId: j['verification_request_id'],
        userId: j['user_id'],
        documentType: j['document_type'] ?? 'proof',
        documentUrl: j['document_url'],
        createdAt: DateTime.parse(j['created_at'] ?? j['uploaded_at']),
      );
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
  final int shareCount;
  final int saveCount;
  final int viewCount;
  final double finalScore;

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
    this.shareCount = 0,
    this.saveCount = 0,
    this.viewCount = 0,
    this.finalScore = 0,
  });

  factory ArgumentModel.fromJson(Map<String, dynamic> j) {
    final boostExpiresAt = j['boost_expires_at'] != null
        ? DateTime.tryParse(j['boost_expires_at'].toString())
        : null;
    final activeBoost =
        boostExpiresAt != null && boostExpiresAt.isAfter(DateTime.now());

    return ArgumentModel(
      id: j['id'],
      userId: j['user_id'],
      matchupId: j['matchup_id'],
      optionId: j['option_id'],
      body: j['body'],
      likeCount: j['like_count'] ?? 0,
      dislikeCount: j['dislike_count'] ?? 0,
      replyCount: j['reply_count'] ?? 0,
      boostExpiresAt: boostExpiresAt,
      visibilityScore: j['visibility_score'] ?? 0,
      status: j['status'] ?? 'active',
      createdAt: DateTime.parse(j['created_at']),
      user: j['user'],
      option: j['option'],
      myReaction: j['my_reaction'],
      isBoosted: (j['is_boosted'] ?? false) == true || activeBoost,
      supportCount: j['support_count'] ?? j['supporter_count'] ?? 0,
      supportCoins: j['support_coins'] ?? j['total_support_coins'] ?? 0,
      shareCount: j['share_count'] ?? 0,
      saveCount: j['save_count'] ?? 0,
      viewCount: j['view_count'] ?? 0,
      finalScore: double.tryParse(j['final_score']?.toString() ?? '0') ?? 0,
    );
  }

  String get username => user?['username'] ?? 'Itilizatè';
  String? get userAvatar => user?['avatar_url'];
  String? get userGender => user?['gender'];
  String? get userVerificationType => user?['verification_type'];
  String? get userVerificationBadgeStyle => user?['verification_badge_style'];
  String get userVerificationStatus => user?['verification_status'] ?? 'none';
  String get optionLabel => option?['option_label'] ?? '';
  String get optionName => option?['option_name'] ?? '';

  double get finalRankingScore {
    if (finalScore > 0) return finalScore;

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
    final engagementRateScore = viewCount > 0
        ? (((likeCount + replyCount + shareCount + saveCount) / viewCount) *
                100)
            .clamp(0, 100)
        : 0;
    return visibilityScore +
        boostScore +
        (likeCount * 2) +
        (replyCount * 5) +
        (shareCount * 8) +
        (saveCount * 6) +
        supportScore +
        engagementRateScore +
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

class BadgeEventResult {
  final String badgeKey;
  final String badgeName;
  final int xp;
  final int oldLevel;
  final int level;
  final bool leveledUp;
  final bool insertedEvent;

  const BadgeEventResult({
    required this.badgeKey,
    required this.badgeName,
    required this.xp,
    required this.oldLevel,
    required this.level,
    required this.leveledUp,
    required this.insertedEvent,
  });

  factory BadgeEventResult.fromJson(Map<String, dynamic> j) => BadgeEventResult(
        badgeKey: j['badge_key'] ?? '',
        badgeName: j['badge_name'] ?? '',
        xp: j['xp'] ?? 0,
        oldLevel: j['old_level'] ?? 0,
        level: j['level'] ?? 0,
        leveledUp: j['leveled_up'] ?? false,
        insertedEvent: j['inserted_event'] ?? false,
      );
}

class PredictionModel {
  final String id;
  final String categoryId;
  final String titleHt;
  final String? titleEn;
  final String? descriptionHt;
  final String optionA;
  final String optionB;
  final DateTime? deadlineAt;
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
    this.deadlineAt,
    required this.status,
    this.winningOption,
    required this.totalVotes,
    this.category,
    this.mySelectedOption,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> j) => PredictionModel(
        id: j['id'],
        categoryId: j['category_id'] ?? '',
        titleHt: j['title_ht'] ?? '',
        titleEn: j['title_en'],
        descriptionHt: j['description_ht'],
        optionA: j['option_a'] ?? '',
        optionB: j['option_b'] ?? '',
        deadlineAt: j['deadline_at'] != null
            ? DateTime.tryParse(j['deadline_at'])
            : null,
        status: j['status'] ?? 'active',
        winningOption: j['winning_option'],
        totalVotes: j['total_votes'] ?? 0,
        category: j['category'] != null
            ? CategoryModel.fromJson(j['category'])
            : null,
        mySelectedOption: j['my_selected_option'],
      );

  bool get isActive => status == 'active';
  bool get isClosed => status == 'closed' || status == 'resolved';
  bool get hasParticipated => mySelectedOption != null;

  Duration get timeLeft => deadlineAt?.difference(DateTime.now()) ?? Duration.zero;
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

// ─── Coin Economy v2 ───────────────────────────────────────

class SupportLevelModel {
  final String id;
  final int coins;
  final String labelHt;
  final String labelEn;
  final String emoji;
  final String colorHex;
  final int animationIntensity; // 1–5
  final String feedMessageHt;

  const SupportLevelModel({
    required this.id,
    required this.coins,
    required this.labelHt,
    required this.labelEn,
    required this.emoji,
    required this.colorHex,
    required this.animationIntensity,
    required this.feedMessageHt,
  });

  factory SupportLevelModel.fromJson(Map<String, dynamic> j) =>
      SupportLevelModel(
        id: j['id'] ?? '',
        coins: j['coins'] ?? 0,
        labelHt: j['label_ht'] ?? '',
        labelEn: j['label_en'] ?? '',
        emoji: j['emoji'] ?? '💙',
        colorHex: j['color_hex'] ?? '#3B82F6',
        animationIntensity: j['animation_intensity'] ?? 1,
        feedMessageHt: j['feed_message_ht'] ?? '',
      );

  /// Fallback levels used while loading from DB
  static const List<SupportLevelModel> defaults = [
    SupportLevelModel(
        id: '',
        coins: 50,
        labelHt: 'Sipò Rapid',
        labelEn: 'Quick Support',
        emoji: '💙',
        colorHex: '#3B82F6',
        animationIntensity: 1,
        feedMessageHt: 'voye yon sipò rapid'),
    SupportLevelModel(
        id: '',
        coins: 250,
        labelHt: 'Sipò Solid',
        labelEn: 'Strong Support',
        emoji: '💜',
        colorHex: '#A855F7',
        animationIntensity: 2,
        feedMessageHt: 'voye yon sipò solid'),
    SupportLevelModel(
        id: '',
        coins: 1000,
        labelHt: 'Gran Sipò',
        labelEn: 'Major Support',
        emoji: '💛',
        colorHex: '#EAB308',
        animationIntensity: 3,
        feedMessageHt: 'voye yon gran sipò'),
    SupportLevelModel(
        id: '',
        coins: 5000,
        labelHt: 'Sipòtè Elit',
        labelEn: 'Elite Supporter',
        emoji: '🧡',
        colorHex: '#F97316',
        animationIntensity: 4,
        feedMessageHt: 'voye yon sipò elit'),
    SupportLevelModel(
        id: '',
        coins: 10000,
        labelHt: 'Soutyen Legendè',
        labelEn: 'Legendary Support',
        emoji: '❤️',
        colorHex: '#EF4444',
        animationIntensity: 5,
        feedMessageHt: 'voye yon soutyen legendè'),
  ];
}

class GiftingEventModel {
  final String id;
  final String giverUsername;
  final String? giverAvatar;
  final String receiverUsername;
  final int coinsAmount;
  final String? feedMessage;
  final String emoji;
  final String colorHex;
  final DateTime createdAt;

  const GiftingEventModel({
    required this.id,
    required this.giverUsername,
    this.giverAvatar,
    required this.receiverUsername,
    required this.coinsAmount,
    this.feedMessage,
    required this.emoji,
    required this.colorHex,
    required this.createdAt,
  });

  factory GiftingEventModel.fromJson(Map<String, dynamic> j) =>
      GiftingEventModel(
        id: j['id'] ?? '',
        giverUsername: j['giver_username'] ?? '',
        giverAvatar: j['giver_avatar'],
        receiverUsername: j['receiver_username'] ?? '',
        coinsAmount: j['coins_amount'] ?? 0,
        feedMessage: j['feed_message'],
        emoji: j['emoji'] ?? '💙',
        colorHex: j['color_hex'] ?? '#3B82F6',
        createdAt: DateTime.parse(j['created_at']),
      );
}

class TopSupporterModel {
  final String giverUserId;
  final String username;
  final String? avatarUrl;
  final int totalCoins;
  final int giftCount;

  const TopSupporterModel({
    required this.giverUserId,
    required this.username,
    this.avatarUrl,
    required this.totalCoins,
    required this.giftCount,
  });

  factory TopSupporterModel.fromJson(Map<String, dynamic> j) =>
      TopSupporterModel(
        giverUserId: j['giver_user_id'] ?? '',
        username: j['username'] ?? '',
        avatarUrl: j['avatar_url'],
        totalCoins: j['total_coins'] ?? 0,
        giftCount: j['gift_count'] ?? 0,
      );
}

// ─── Creator Revenue System ────────────────────────────────

class CreatorProfileModel {
  final String userId;
  final int creatorTier; // 0=User, 1=Rising, 2=Verified, 3=Elite, 4=Icon
  final int creatorScore; // 0-100
  final int trustScore; // 0-100
  final bool isMonetizationEnabled;
  final bool monetizationSuspended;
  final double revenueShareRate; // e.g. 0.70
  final int totalEarnedCoins;
  final int pendingPayoutCoins;
  final int totalPaidOutCoins;
  final DateTime? scoreUpdatedAt;
  final DateTime? tierUpdatedAt;

  const CreatorProfileModel({
    required this.userId,
    required this.creatorTier,
    required this.creatorScore,
    required this.trustScore,
    required this.isMonetizationEnabled,
    required this.monetizationSuspended,
    required this.revenueShareRate,
    required this.totalEarnedCoins,
    required this.pendingPayoutCoins,
    required this.totalPaidOutCoins,
    this.scoreUpdatedAt,
    this.tierUpdatedAt,
  });

  factory CreatorProfileModel.fromJson(Map<String, dynamic> j) =>
      CreatorProfileModel(
        userId: j['user_id'],
        creatorTier: j['creator_tier'] ?? 0,
        creatorScore: j['creator_score'] ?? 0,
        trustScore: j['trust_score'] ?? 0,
        isMonetizationEnabled: j['is_monetization_enabled'] ?? false,
        monetizationSuspended: j['monetization_suspended'] ?? false,
        revenueShareRate:
            double.tryParse(j['revenue_share_rate']?.toString() ?? '0') ?? 0.0,
        totalEarnedCoins: j['total_earned_coins'] ?? 0,
        pendingPayoutCoins: j['pending_payout_coins'] ?? 0,
        totalPaidOutCoins: j['total_paid_out_coins'] ?? 0,
        scoreUpdatedAt: j['score_updated_at'] == null
            ? null
            : DateTime.tryParse(j['score_updated_at']),
        tierUpdatedAt: j['tier_updated_at'] == null
            ? null
            : DateTime.tryParse(j['tier_updated_at']),
      );

  String get tierLabel {
    switch (creatorTier) {
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

  String get tierLabelEn {
    switch (creatorTier) {
      case 1:
        return 'Rising Creator';
      case 2:
        return 'Verified Creator';
      case 3:
        return 'Elite Creator';
      case 4:
        return 'Cultural Icon';
      default:
        return 'User';
    }
  }

  int get revenueSharePercent => (revenueShareRate * 100).round();
}

class CreatorDashboardModel {
  final int creatorTier;
  final int creatorScore;
  final int trustScore;
  final bool isMonetizationEnabled;
  final double revenueShareRate;
  final int totalEarnedCoins;
  final int pendingPayoutCoins;
  final int totalPaidOutCoins;
  final int revenueLast7d;
  final int revenueLast30d;
  final double usdLast7d;
  final double usdLast30d;
  final double walletUsdBalance;
  final double coinToUsdRate;
  final int uniqueSupporters30d;
  final int followersCount;
  final int participationCount;
  final int victoryCount;
  final int totalSupportReceived;
  final int influenceScore;

  const CreatorDashboardModel({
    required this.creatorTier,
    required this.creatorScore,
    required this.trustScore,
    required this.isMonetizationEnabled,
    required this.revenueShareRate,
    required this.totalEarnedCoins,
    required this.pendingPayoutCoins,
    required this.totalPaidOutCoins,
    required this.revenueLast7d,
    required this.revenueLast30d,
    this.usdLast7d = 0.0,
    this.usdLast30d = 0.0,
    this.walletUsdBalance = 0.0,
    this.coinToUsdRate = 0.006,
    required this.uniqueSupporters30d,
    required this.followersCount,
    required this.participationCount,
    required this.victoryCount,
    required this.totalSupportReceived,
    required this.influenceScore,
  });

  factory CreatorDashboardModel.fromJson(Map<String, dynamic> j) =>
      CreatorDashboardModel(
        creatorTier: j['creator_tier'] ?? 0,
        creatorScore: j['creator_score'] ?? 0,
        trustScore: j['trust_score'] ?? 0,
        isMonetizationEnabled: j['is_monetization_enabled'] ?? false,
        revenueShareRate:
            double.tryParse(j['revenue_share_rate']?.toString() ?? '0') ?? 0.0,
        totalEarnedCoins: j['total_earned_coins'] ?? 0,
        pendingPayoutCoins: j['pending_payout_coins'] ?? 0,
        totalPaidOutCoins: j['total_paid_out_coins'] ?? 0,
        revenueLast7d: j['revenue_last_7d'] ?? 0,
        revenueLast30d: j['revenue_last_30d'] ?? 0,
        usdLast7d: double.tryParse(j['usd_last_7d']?.toString() ?? '0') ?? 0.0,
        usdLast30d:
            double.tryParse(j['usd_last_30d']?.toString() ?? '0') ?? 0.0,
        walletUsdBalance:
            double.tryParse(j['wallet_usd_balance']?.toString() ?? '0') ?? 0.0,
        coinToUsdRate:
            double.tryParse(j['coin_to_usd_rate']?.toString() ?? '0.006') ??
                0.006,
        uniqueSupporters30d: j['unique_supporters_30d'] ?? 0,
        followersCount: j['followers_count'] ?? 0,
        participationCount: j['participation_count'] ?? 0,
        victoryCount: j['victory_count'] ?? 0,
        totalSupportReceived: j['total_support_received'] ?? 0,
        influenceScore: j['influence_score'] ?? 0,
      );

  int get revenueSharePercent => (revenueShareRate * 100).round();

  /// USD value of pending payout coins at current rate
  double get pendingPayoutUsd => pendingPayoutCoins * coinToUsdRate;

  /// USD value of total earned coins
  double get totalEarnedUsd => totalEarnedCoins * coinToUsdRate;
}

class CreatorRevenueEventModel {
  final String id;
  final String creatorUserId;
  final String? sourceUserId;
  final String eventType;
  final int grossCoins;
  final double creatorShareRate;
  final int creatorCoins;
  final int platformCoins;
  final DateTime createdAt;

  const CreatorRevenueEventModel({
    required this.id,
    required this.creatorUserId,
    this.sourceUserId,
    required this.eventType,
    required this.grossCoins,
    required this.creatorShareRate,
    required this.creatorCoins,
    required this.platformCoins,
    required this.createdAt,
  });

  factory CreatorRevenueEventModel.fromJson(Map<String, dynamic> j) =>
      CreatorRevenueEventModel(
        id: j['id'],
        creatorUserId: j['creator_user_id'],
        sourceUserId: j['source_user_id'],
        eventType: j['event_type'] ?? '',
        grossCoins: j['gross_coins'] ?? 0,
        creatorShareRate:
            double.tryParse(j['creator_share_rate']?.toString() ?? '0') ?? 0.0,
        creatorCoins: j['creator_coins'] ?? 0,
        platformCoins: j['platform_coins'] ?? 0,
        createdAt: DateTime.parse(j['created_at']),
      );
}

// ─── End Creator Revenue System ────────────────────────────

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
