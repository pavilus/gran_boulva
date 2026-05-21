import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../models/models.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? gender;
  final double radius;
  final Color backgroundColor;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.gender,
    this.radius = 20,
    this.backgroundColor = AppColors.bg1,
  });

  factory UserAvatar.fromUser(
    UserModel? user, {
    Key? key,
    double radius = 20,
    Color backgroundColor = AppColors.bg1,
  }) {
    return UserAvatar(
      key: key,
      avatarUrl: user?.avatarUrl,
      gender: user?.gender,
      radius: radius,
      backgroundColor: backgroundColor,
    );
  }

  static ImageProvider defaultImageProvider(String? gender) {
    final normalized = gender?.toLowerCase().trim();
    if (normalized == 'female' || normalized == 'fi') {
      return const AssetImage('assets/images/default_female.png');
    }
    return const AssetImage('assets/images/default_male.png');
  }

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: url != null && url.isNotEmpty
          ? CachedNetworkImageProvider(url)
          : defaultImageProvider(gender),
    );
  }
}
