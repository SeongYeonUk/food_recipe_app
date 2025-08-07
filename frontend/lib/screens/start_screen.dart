import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_recipe_app/common/component/custom_button.dart';
import 'package:food_recipe_app/common/const/colors.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  int currentPage = 0;
  Timer? timer;
  final PageController _pageController = PageController();
  final List<Map<String, dynamic>> pageList = [
    {
      'image': 'asset/img/page1.jpg',
      'color': const Color(0xFFFFF8E1),
    },
    {
      'image': 'asset/img/page2.jpg',
      'color': const Color(0xFFFFF8E1),
    },
    {
      'image': 'asset/img/page3.jpg',
      'color': Colors.white,
    },
    {
      'image': 'asset/img/page4.jpg',
      'color': Colors.white,
    },
  ];

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      int nextPage = (currentPage + 1) % pageList.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  color: pageList[currentPage]['color'],
                ),
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      currentPage = page;
                    });
                  },
                  itemCount: pageList.length,
                  itemBuilder: (context, index) {
                    return Center(
                      child: Image.asset(
                        pageList[index]['image'],
                        width: MediaQuery.of(context).size.width * 0.7,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const Text(
                          '나만의 냉장고 도서관',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '간편하게 식재료를 관리하고\n레시피를 추천 받으세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            pageList.length,
                                (index) => buildPageIndicator(index == currentPage),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => showBottomSheet(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: PRIMARY_COLOR,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Get started',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      width: isActive ? 16 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isActive ? PRIMARY_COLOR : Colors.grey[300],
      ),
    );
  }

  void showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext innerContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Login or sign up',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('간편하게 회원가입 혹은 로그인 하세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 32),
              CustomAuthButton(
                text: '간편하게 회원가입 하기',
                route: '/signup',
                buttonType: ButtonType.elevated,
                backgroundColor: PRIMARY_COLOR,
                textColor: Colors.white,
              ),
              const SizedBox(height: 12),
              CustomAuthButton(
                text: '로그인하기',
                route: '/login',
                buttonType: ButtonType.outlined,
                textColor: Colors.black87,
                borderColor: Colors.grey[300]!,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('또는', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Image.asset(
                        'asset/img/google_logo.png',
                        height: 24.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Image.asset(
                        'asset/img/apple_logo.png',
                        height: 24.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'If you are creating a new account, Terms & Conditions and Privacy Policy will apply.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              )
            ],
          ),
        );
      },
    );
  }
}
