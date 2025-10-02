import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/review_viewmodel.dart';
import 'community_widgets.dart';

class RecipeReviewScreen extends StatelessWidget {
  const RecipeReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('레시피 후기')),
      body: Consumer<ReviewViewModel>(
        builder: (context, viewModel, child) {
          // ViewModel에 로딩 상태가 없으므로, 목록이 비어있는지만 확인합니다.
          if (viewModel.bestReviews.isEmpty && viewModel.todayReviews.isEmpty) {
            return const Center(child: Text('아직 등록된 후기가 없습니다.'));
          }

          // ViewModel에 새로고침 기능이 없으므로, RefreshIndicator를 제거합니다.
          return SingleChildScrollView(
            child: Column(
              children: [
                // TopMenuBar는 현재 사용되지 않는 것으로 가정하고 주석 처리합니다.
                // TopMenuBar(currentIndex: 5),
                const SizedBox(height: 16),

                // '베스트 레시피 후기' 목록이 있을 때만 섹션을 표시합니다.
                if (viewModel.bestReviews.isNotEmpty) ...[
                  ReviewPostSection(
                    title: '베스트 레시피 후기',
                    titleColor: Colors.orange,
                    posts: viewModel.bestReviews,
                  ),
                  const SizedBox(height: 24),
                ],

                // '오늘 올라온 레시피 후기' 목록이 있을 때만 섹션을 표시합니다.
                if (viewModel.todayReviews.isNotEmpty) ...[
                  ReviewPostSection(
                    title: '오늘 올라온 레시피 후기',
                    titleColor: Colors.orange,
                    posts: viewModel.todayReviews,
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

