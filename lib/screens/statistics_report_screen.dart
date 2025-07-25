import 'package:flutter/material.dart';

class StatisticsReportScreen extends StatelessWidget {
  const StatisticsReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 샘플 데이터
    final List<String> _favoriteIngredients = [
      '계란', '양파', '대파', '우유', '닭가슴살'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('통계 및 리포트'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '자주 사용하는 식재료',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: _favoriteIngredients.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(_favoriteIngredients[index]),
                  );
                },
              ),
            ),
            // TODO: 향후 그래프 등 시각화 자료 추가
          ],
        ),
      ),
    );
  }
}
