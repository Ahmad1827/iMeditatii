import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'theme_manager.dart';
import 'app_colors.dart';

class RetroBlock extends StatelessWidget {
  final Widget child;
  final Color? bgColor;
  final double padding;
  final double shadowOffset;
  final Color? borderColor;

  const RetroBlock({
    super.key,
    required this.child,
    this.bgColor,
    this.padding = 24.0,
    this.shadowOffset = 6.0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = bgColor ?? AppColors.cardBg;
    final effectiveBorder = borderColor ?? AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: effectiveBg,
        border: Border.all(color: effectiveBorder, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}

class AllReviewsScreen extends StatelessWidget {
  final String teacherId;

  const AllReviewsScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context) {
    final reviewsRef = FirebaseFirestore.instance
        .collection('teachers')
        .doc(teacherId)
        .collection('reviews')
        .orderBy('createdAt', descending: true);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: Text(
              'ALL REVIEWS',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            backgroundColor: AppColors.bg,
            iconTheme: IconThemeData(color: AppColors.ink),
            elevation: 0,
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: Container(color: AppColors.border, height: 3),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: StreamBuilder<QuerySnapshot>(
                stream: reviewsRef.snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return Center(
                      child: CircularProgressIndicator(color: AppColors.sunset),
                    );
                  }

                  final docs = snap.data!.docs;

                  if (docs.isEmpty) {
                    return Center(
                      child: RetroBlock(
                        bgColor: AppColors.cloud,
                        child: Text(
                          'NO REVIEWS FOUND.',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final rating = data['rating'] ?? 0;
                      final comment = data['comment'] ?? '';
                      final author = data['authorName'] ?? data['userName'] ?? 'ANONYMOUS PLAYER';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 32.0),
                        child: RetroBlock(
                          bgColor: AppColors.cardBg,
                          padding: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                color: AppColors.cloud,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: AppColors.border, width: 3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      author.toString().toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.ink,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(5, (starIndex) {
                                        return Icon(
                                          starIndex < rating ? Icons.star : Icons.star_border,
                                          color: AppColors.sunset,
                                          size: 28,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(
                                  comment.toString().isEmpty ? 'NO COMMENT PROVIDED.' : '"$comment"',
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: comment.toString().isEmpty ? AppColors.textMuted : AppColors.ink,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}