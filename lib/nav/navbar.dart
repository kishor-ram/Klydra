import 'package:flutter/material.dart';
import 'package:klydra/nav/home.dart';
import 'package:klydra/nav/aiassistant.dart';
import 'package:klydra/nav/analytics.dart';
import 'package:klydra/nav/profilepage.dart';
import 'package:water_drop_nav_bar/water_drop_nav_bar.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int selectedIndex = 0;
  final PageController pageController = PageController();

  final List<Widget> pages = [
    const HomePage(),
    const AnalyticsPage(),
    const AIAssistantPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        children: pages,
      ),
      bottomNavigationBar: WaterDropNavBar(
        bottomPadding: 25,
        backgroundColor: Colors.white,
        waterDropColor: const Color.fromARGB(255, 94, 102, 193),
        inactiveIconColor: const Color(0xFF9E9E9E),
        barItems: [
          BarItem(
            filledIcon: Icons.home,
            outlinedIcon: Icons.home_outlined,
          ),
          BarItem(
            filledIcon: Icons.analytics,
            outlinedIcon: Icons.analytics_outlined,
          ),
          BarItem(
            filledIcon: Icons.smart_toy,
            outlinedIcon: Icons.smart_toy_outlined,
          ),
          BarItem(
            filledIcon: Icons.person,
            outlinedIcon: Icons.person_outlined,
          ),
        ],
        selectedIndex: selectedIndex,
        onItemSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
          pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }
}
