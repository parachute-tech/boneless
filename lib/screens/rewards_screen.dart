import 'dart:convert';

import 'package:bonless61/core/config/app_config.dart';
import 'package:bonless61/core/theme/app_colors.dart';
import 'package:bonless61/wigets/widgetexport.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  int selectedTab = 0;
  late Future<LoyaltySummary> _loyaltySummaryFuture;

  @override
  void initState() {
    super.initState();
    _loyaltySummaryFuture = LoyaltyApi.fetchSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const TopBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                const SizedBox(height: 0),
                FutureBuilder<LoyaltySummary>(
                  future: _loyaltySummaryFuture,
                  builder: (context, snapshot) {
                    final summary = snapshot.data;
                    final isLoading = snapshot.connectionState == ConnectionState.waiting;
                    final hasError = snapshot.hasError || !snapshot.hasData;

                    return RewardsBalanceHeader(
                      points: isLoading || hasError
                          ? '--'
                          : summary!.totalPoints.toString(),
                      label: hasError ? 'COULD NOT LOAD POINTS' : 'CURRENT BALANCE',
                      onRetry: hasError
                          ? () {
                              setState(() {
                                _loyaltySummaryFuture = LoyaltyApi.fetchSummary();
                              });
                            }
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 0),
                FutureBuilder<LoyaltySummary>(
                  future: _loyaltySummaryFuture,
                  builder: (context, snapshot) {
                    final summary = snapshot.data;
                    final isLoading = snapshot.connectionState == ConnectionState.waiting;
                    final hasError = snapshot.hasError || !snapshot.hasData;

                    if (isLoading) {
                      return const RewardsProgressText(
                        pointsText: 'Loading',
                        targetText: 'your next tier',
                      );
                    }

                    if (hasError) {
                      return const RewardsProgressText(
                        pointsText: '--',
                        targetText: 'your rewards',
                      );
                    }

                    return RewardsProgressText(
                      pointsText: '${summary!.pointsRemaining ?? 0} pts',
                      targetText: summary.nextTierName == null
                          ? 'Max Tier!'
                          : '${summary.nextTierName} Tier!',
                    );
                  },
                ),
                const SizedBox(height: 28),
                FutureBuilder<LoyaltySummary>(
                  future: _loyaltySummaryFuture,
                  builder: (context, snapshot) {
                    final summary = snapshot.data;
                    return TierProgressCard(
                      currentTierName: summary?.currentTierName ?? 'LOADING',
                      nextTierName: summary?.nextTierName,
                      pointsRemaining: summary?.pointsRemaining,
                      progress: summary?.progress ?? 0,
                    );
                  },
                ),
                const SizedBox(height: 20),
                RewardsToggleBar(
                  selectedIndex: selectedTab,
                  onChanged: (index) {
                    setState(() {
                      selectedTab = index;
                    });
                  },
                ),
                const SizedBox(height: 20),
                selectedTab == 0
                    ? const _RedeemContent()
                    : const _HowToEarnContent(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardsFramePainter extends CustomPainter {
  final Color color;

  _RewardsFramePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.52, size.height * 0.06)
      ..lineTo(size.width * 0.90, size.height * 0.40)
      ..lineTo(size.width * 0.52, size.height * 0.88)
      ..lineTo(size.width * 0.10, size.height * 0.42);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class TierProgressCard extends StatelessWidget {
  final String currentTierName;
  final String? nextTierName;
  final int? pointsRemaining;
  final double progress;

  const TierProgressCard({
    super.key,
    required this.currentTierName,
    required this.nextTierName,
    required this.pointsRemaining,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final nextTierLabel = nextTierName == null
        ? 'TOP TIER'
        : '${pointsRemaining ?? 0} PTS TO ${nextTierName!.toUpperCase()}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${currentTierName.toUpperCase()} TIER',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            nextTierLabel,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 36,
                    backgroundColor: Colors.black,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryRed,
                    ),
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
class RewardsBalanceHeader extends StatelessWidget {
  final String points;
  final String label;
  final VoidCallback? onRetry;

  const RewardsBalanceHeader({
    super.key,
    required this.points,
    required this.label,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, -22),
            child: Container(
              width: 390,
              height: 390,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryRed.withOpacity(0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -18),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 2,
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -18),
            child: Container(
              width: 255,
              height: 255,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryRed.withOpacity(0.16),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _RewardsFramePainter(AppColors.primaryRed),
            ),
          ),
          Positioned(
            top: 130,
            child: GestureDetector(
              onTap: onRetry,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      letterSpacing: 3.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    points,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 86,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'POINTS',
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RewardsProgressText extends StatelessWidget {
  final String pointsText;
  final String targetText;

  const RewardsProgressText({
    super.key,
    required this.pointsText,
    required this.targetText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
          children: [
            const TextSpan(text: "You're "),
            TextSpan(
              text: pointsText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(text: ' away from '),
            TextSpan(
              text: targetText,
              style: const TextStyle(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RewardsToggleBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const RewardsToggleBar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: selectedIndex == 0
                      ? const Color(0xFF2A2A2A)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  'REDEEM',
                  style: TextStyle(
                    color: selectedIndex == 0
                        ? AppColors.primaryRed
                        : Colors.white38,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: selectedIndex == 1
                      ? const Color(0xFF2A2A2A)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  'HOW TO EARN',
                  style: TextStyle(
                    color: selectedIndex == 1
                        ? AppColors.primaryRed
                        : Colors.white38,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RedeemContent extends StatelessWidget {
  const _RedeemContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'AVAILABLE REWARDS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'VIEW ALL',
              style: TextStyle(
                color: AppColors.primaryRed,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const RewardItemCard(
          image: 'assets/deal.png',
          title: 'LOADED FRIES',
          subtitle: 'French fries - cheddar cheese -\nchips - boneless sauce.',
          points: '10 PTS',
        ),
        const SizedBox(height: 14),
        const RewardItemCard(
          image: 'assets/deal.png',
          title: 'CLASSIC SLIDER',
          subtitle: 'Angus beef with aged cheddar.',
          points: '15 PTS',
        ),
      ],
    );
  }
}

class RewardItemCard extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final String points;

  const RewardItemCard({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.asset(
                image,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    points,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 46,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0),
                        Colors.black.withOpacity(0.55),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'CLAIM',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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

class _HowToEarnContent extends StatelessWidget {
  const _HowToEarnContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              color: AppColors.primaryRed,
            ),
            const SizedBox(width: 10),
            const Text(
              'HOW TO EARN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const EarnItemCard(
          icon: Icons.restaurant,
          title: 'ORDER ANY MEAL',
          subtitle:
              'Earn 1 point for every 500 SYP spent in-store or online.',
        ),
        const SizedBox(height: 12),

        const EarnItemCard(
          icon: Icons.phone_iphone,
          title: 'APP-ONLY OFFERS',
          subtitle:
              'Check your inbox for 2x points days and hidden deals.',
        ),
        const SizedBox(height: 12),

        const EarnItemCard(
          icon: Icons.trending_up,
          title: 'HIGHER TIERS',
          subtitle:
              'Unlock point multipliers by reaching Silver and Gold.',
        ),
      ],
    );
  }
}

class EarnItemCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EarnItemCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
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
class LoyaltySummary {
  final int totalPoints;
  final String currentTierName;
  final String? nextTierName;
  final int? nextTierMinPoints;
  final int? pointsRemaining;

  const LoyaltySummary({
    required this.totalPoints,
    required this.currentTierName,
    required this.nextTierName,
    required this.nextTierMinPoints,
    required this.pointsRemaining,
  });

  double get progress {
    if (nextTierMinPoints == null || nextTierMinPoints == 0) {
      return 1;
    }

    return totalPoints / nextTierMinPoints!;
  }

  factory LoyaltySummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final currentTier = data['current_tier'] as Map<String, dynamic>?;
    final nextTier = data['next_tier'] as Map<String, dynamic>?;

    return LoyaltySummary(
      totalPoints: data['total_points'] as int? ?? 0,
      currentTierName: currentTier?['name'] as String? ?? 'N/A',
      nextTierName: nextTier?['name'] as String?,
      nextTierMinPoints: nextTier?['min_points'] as int?,
      pointsRemaining: nextTier?['points_remaining'] as int?,
    );
  }
}

class LoyaltyApi {
  static Future<LoyaltySummary> fetchSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Missing auth token');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/loyalty/summary'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load loyalty summary: ${response.statusCode}');
    }

    return LoyaltySummary.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}