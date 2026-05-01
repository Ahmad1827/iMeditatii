import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppColors {
  static const Color bg = Color(0xFFF9F7F1);
  static const Color ink = Color(0xFF2C363F);
  static const Color sunset = Color(0xFFE75A41);
  static const Color forest = Color(0xFF3C7A61);
  static const Color mustard = Color(0xFFEAB334);
  static const Color cloud = Color(0xFFE2DFD2);
  static const Color sky = Color(0xFF5BA8B5);
}

class RetroBlock extends StatelessWidget {
  final Widget child;
  final Color bgColor;
  final double padding;
  final double shadowOffset;
  final Color borderColor;

  const RetroBlock({
    super.key,
    required this.child,
    this.bgColor = Colors.white,
    this.padding = 24.0,
    this.shadowOffset = 6.0,
    this.borderColor = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink,
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          'ALL REVIEWS',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        backgroundColor: AppColors.bg,
        iconTheme: const IconThemeData(color: AppColors.ink),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: AppColors.ink, height: 3),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: StreamBuilder<QuerySnapshot>(
            stream: reviewsRef.snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.sunset),
                );
              }

              final docs = snap.data!.docs;

              if (docs.isEmpty) {
                return Center(
                  child: RetroBlock(
                    bgColor: AppColors.cloud,
                    child: const Text(
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
                  final author = data['authorName'] ?? 'ANONYMOUS PLAYER';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: RetroBlock(
                      bgColor: Colors.white,
                      padding: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            color: AppColors.cloud,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppColors.ink, width: 3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  author.toUpperCase(),
                                  style: const TextStyle(
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
                              comment.isEmpty ? 'NO COMMENT PROVIDED.' : '"$comment"',
                              style: TextStyle(
                                fontSize: 22,
                                color: comment.isEmpty ? Colors.black38 : AppColors.ink,
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
  }
}