// lib/viewmodels/review_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/review_model.dart';

class ReviewViewModel with ChangeNotifier {
  final List<Review> _reviews = [];

  List<Review> get bestReviews => _reviews;
  List<Review> get todayReviews => _reviews;

  void addReview({
    required String recipeName,
    required String title,
    required String content,
    String? imageUrl,
  }) {
    final newReview = Review(
      recipeName: recipeName,
      title: title,
      content: content,
      imageUrl: imageUrl,
    );
    _reviews.insert(0, newReview);
    notifyListeners();
  }

  // [솔루션] 조회수 증가 함수
  void incrementView(Review review) {
    review.views++;
    notifyListeners();
  }

  // [솔루션] 좋아요 토글 함수
  void toggleLike(Review review) {
    review.isLiked = !review.isLiked;
    if (review.isLiked) {
      review.likes++;
    } else {
      review.likes--;
    }
    notifyListeners();
  }
}


