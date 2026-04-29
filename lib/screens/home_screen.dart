import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bonless61/core/config/app_config.dart';
import 'package:bonless61/core/theme/app_colors.dart';
import 'package:bonless61/screens/cart_screen.dart';
import 'package:bonless61/widgets/widgetexport.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Homescreen extends StatelessWidget {
  const Homescreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const TopBar(),
      floatingActionButton: GestureDetector(
        onTap: () => Get.to(() => const CartScreen()),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primaryRed,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryRed.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.shopping_basket_outlined,
            color: Colors.white,
            size: 34,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Background image
                        Positioned.fill(
                          child: Image.asset(
                            'assets/deal.png', // make sure this exists
                            fit: BoxFit.cover,
                          ),
                        ),

                        // Dark overlay for readability
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.black.withOpacity(0.2),
                                ],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                          ),
                        ),

                        // Content
                        Positioned(
                          left: 16,
                          bottom: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'BOGO BONELESS\nBUCKET',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              buildButton(
                                text: 'CLAIM DEAL →',
                                height: 48,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const LoyaltyCard(),
                const SizedBox(height: 24),

                // Current Offers Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CURRENT OFFERS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'VIEW ALL',
                      style: TextStyle(
                        color: AppColors.primaryRed,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Offers List
                const OffersList(), //there is an error her
                const SizedBox(height: 28),

                Row(
                  children: const [
                    Text(
                      'FAVORITES',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const FavoriteItemCard(
                  image: 'assets/deal.png',
                  title: 'CLASSIC BONELESS',
                  subtitle: '12PC · GARLIC PARM',
                  price: '900 SYP',
                ),
                const SizedBox(height: 14),
                const FavoriteItemCard(
                  image: 'assets/deal.png',
                  title: 'CRISPY WINGS',
                  subtitle: '8PC · BUFFALO HOT',
                  price: '400 SYP',
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      )
    );
  }
}

class OfferCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String description;
  final String badgeText;

  const OfferCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              if (imageUrl != null && imageUrl!.isNotEmpty)
                Image.network(
                  imageUrl!,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/deal.png',
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    );
                  },
                )
              else
                Image.asset(
                  'assets/deal.png',
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              if (badgeText.isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OffersList extends StatefulWidget {
  const OffersList({super.key});

  @override
  State<OffersList> createState() => _OffersListState();
}

class _OffersListState extends State<OffersList> {
  late Future<List<Offer>> _offersFuture;

  @override
  void initState() {
    super.initState();
    _offersFuture = OffersApi.fetchOffers();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: FutureBuilder<List<Offer>>(
        future: _offersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryRed,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _offersFuture = OffersApi.fetchOffers();
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Could not load offers. Tap to retry.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            );
          }

          final offers = snapshot.data ?? [];

          if (offers.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'No offers available right now.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            );
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: offers.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final offer = offers[index];

              return OfferCard(
                imageUrl: offer.imageUrl,
                title: offer.title,
                description: offer.description,
                badgeText: offer.badgeText,
              );
            },
          );
        },
      ),
    );
  }
}

class Offer {
  final String title;
  final String description;
  final String type;
  final int discountValue;
  final String? imageUrl;

  const Offer({
    required this.title,
    required this.description,
    required this.type,
    required this.discountValue,
    required this.imageUrl,
  });

  String get badgeText {
    if (type == 'PERCENTAGE') {
      return '$discountValue% OFF';
    }

    if (type == 'FIXED') {
      return '$discountValue SYP OFF';
    }

    if (type == 'BOGO') {
      return 'BOGO';
    }

    return type;
  }

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      title: json['title'] as String? ?? 'Offer',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? '',
      discountValue: json['discount_value'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class OffersApi {
  static Future<List<Offer>> fetchOffers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Missing auth token');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/offers'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load offers: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final offers = decoded['data'] as List<dynamic>? ?? [];

    return offers
        .map((offer) => Offer.fromJson(offer as Map<String, dynamic>))
        .toList();
  }
}

class LoyaltyCard extends StatefulWidget {
  const LoyaltyCard({super.key});

  @override
  State<LoyaltyCard> createState() => _LoyaltyCardState();
}

class _LoyaltyCardState extends State<LoyaltyCard> {
  late Future<LoyaltySummary> _loyaltySummaryFuture;

  @override
  void initState() {
    super.initState();
    _loyaltySummaryFuture = LoyaltyApi.fetchSummary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LoyaltySummary>(
      future: _loyaltySummaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoyaltyCardView(
            points: '--',
            tierName: 'LOADING',
            nextReward: 'LOADING REWARD',
            progress: 0,
            pointsLeftText: '',
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return LoyaltyCardView(
            points: '--',
            tierName: 'ERROR',
            nextReward: 'COULD NOT LOAD POINTS',
            progress: 0,
            pointsLeftText: 'Tap refresh later',
            onRetry: () {
              setState(() {
                _loyaltySummaryFuture = LoyaltyApi.fetchSummary();
              });
            },
          );
        }

        final summary = snapshot.data!;

        return LoyaltyCardView(
          points: summary.totalPoints.toString(),
          tierName: summary.currentTierName,
          nextReward: summary.nextTierName == null
              ? 'MAX TIER REACHED'
              : 'NEXT TIER: ${summary.nextTierName}',
          progress: summary.progress,
          pointsLeftText: summary.pointsRemaining == null
              ? 'Top tier'
              : '${summary.pointsRemaining} pts left',
        );
      },
    );
  }
}

class LoyaltyCardView extends StatelessWidget {
  final String points;
  final String tierName;
  final String nextReward;
  final double progress;
  final String pointsLeftText;
  final VoidCallback? onRetry;

  const LoyaltyCardView({
    super.key,
    required this.points,
    required this.tierName,
    required this.nextReward,
    required this.progress,
    required this.pointsLeftText,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LOYALTY ACCOUNT',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        color: AppColors.primaryRed,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'TIER $tierName',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          PointsDisplay(points: points),

          const SizedBox(height: 12),

          Text(
            nextReward,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0, 1),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              pointsLeftText,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
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

class PointsDisplay extends StatelessWidget {
  final String points;

  const PointsDisplay({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          points,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            'PTS',
            style: TextStyle(
              color: AppColors.primaryRed,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class FavoriteItemCard extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final String price;

  const FavoriteItemCard({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 118,
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      image,
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          price,
                          style: const TextStyle(
                            color: AppColors.primaryRed,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart_outlined,
                      color: Colors.white70,
                      size: 32,
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
