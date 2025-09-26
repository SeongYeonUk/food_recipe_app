// lib/screens/community_screen.dart

import 'package:flutter/material.dart';
import 'community/community_data.dart'; // [솔루션] 공유 데이터 파일 임포트

class CommunityDetailScreen extends StatelessWidget {
  final String title;
  const CommunityDetailScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title 화면', style: const TextStyle(fontSize: 24))),
    );
  }
}

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    // [솔루션] 공유 데이터를 사용하므로, categories 리스트를 여기서 삭제합니다.

    return Scaffold(
      appBar: AppBar(title: const Text('커뮤니티')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.8,
                ),
                itemCount: communityCategories.length, // [솔루션] 공유 데이터 사용
                itemBuilder: (context, index) {
                  final category = communityCategories[index]; // [솔루션] 공유 데이터 사용
                  return _buildCategoryItem(
                    context,
                    label: category['label'],
                    color: category['color'],
                    onTap: () => _navigateToScreen(context, category['screen']),
                  );
                },
              ),
              const SizedBox(height: 24),
              // ... (이하 광고 배너, 검색창 코드는 기존과 100% 동일)
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCategoryItem(BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
