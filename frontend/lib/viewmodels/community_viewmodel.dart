// lib/viewmodels/community_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/community_post_model.dart';

class CommunityViewModel with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<CommunityPost> _mostViewedPosts = [];
  List<CommunityPost> _todayShowcasePosts = [];
  List<CommunityPost> get mostViewedPosts => _mostViewedPosts;
  List<CommunityPost> get todayShowcasePosts => _todayShowcasePosts;

  List<CommunityPost> _bestReviewPosts = [];
  List<CommunityPost> _todayReviewPosts = [];
  List<CommunityPost> get bestReviewPosts => _bestReviewPosts;
  List<CommunityPost> get todayReviewPosts => _todayReviewPosts;

  CommunityViewModel() {
    fetchShowcaseData();
    fetchReviewData();
  }

  Future<void> fetchShowcaseData() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    _mostViewedPosts = List.generate(6, (i) => CommunityPost(id: i, type: PostType.showcase, title: '계란 후라이 응용법 ${i+1}', imageUrl: '', views: 156 - i*10, likes: 27, comments: 113));
    _todayShowcasePosts = List.generate(6, (i) => CommunityPost(id: 10+i, type: PostType.showcase, title: '술안주 부추전 만들기 ${i+1}', imageUrl: '', views: 83, likes: 19, comments: 37));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchReviewData() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    _bestReviewPosts = List.generate(6, (i) => CommunityPost(id: 20+i, type: PostType.review, title: '내가 직접 만든 인생 라볶이 후기!!', recipeName: '행복한 라볶이', imageUrl: ''));
    _todayReviewPosts = List.generate(6, (i) => CommunityPost(id: 30+i, type: PostType.review, title: '오늘은 이거다! 부추전 후기 공유', recipeName: '술안주 부추전', imageUrl: ''));

    _isLoading = false;
    notifyListeners();
  }
}
