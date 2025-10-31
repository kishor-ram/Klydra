import 'package:flutter/material.dart';
import 'package:klydra/features/reprts.dart';
import 'package:klydra/features/trendingissues.dart';
import 'package:klydra/nav/aiassistant.dart';
import 'package:klydra/nav/analytics.dart';
import 'package:klydra/widgets/opionchart.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabAnimation;

  bool _showAIChat = false;
  PageController _trendingController = PageController();
  int _currentTrendingIndex = 0;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      _fabController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _fabController.dispose();
    _trendingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset(
            'Assets/images/boy.png',
            fit: BoxFit.contain,
            width: 36,
            height: 36,
          ),
        ),

        centerTitle: false,
        backgroundColor: Colors.white,
        title: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: const Text(
            'Welcome, DMMK',
            style: TextStyle(
    
              color: Color.fromARGB(255, 0, 58, 145),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications,
              color: Color.fromARGB(255, 49, 83, 231),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),

      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        EnhancedOpinionChart(),
                        const SizedBox(height: 24),
                        _buildTrendingIssues(),
                        const SizedBox(height: 24),
                        _buildRecommendations(),
                        const SizedBox(height: 24),
                        _buildFeatureGrid(),
                        const SizedBox(height: 100), 
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildAnimatedFAB(),
        ],
      ),
    );
  }

  Widget _buildTrendingIssues() {
    final trendingIssues = [
      {'title': 'Healthcare Reform', 'sentiment': 78, 'trend': 'up'},
      {'title': 'Education Policy', 'sentiment': 65, 'trend': 'up'},
      {'title': 'Infrastructure Development', 'sentiment': 82, 'trend': 'up'},
      {'title': 'Economic Growth', 'sentiment': 71, 'trend': 'down'},
      {'title': 'Environmental Protection', 'sentiment': 69, 'trend': 'up'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Trending Issues',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TrendingIssuesPage()),
                );
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _trendingController,
            onPageChanged: (index) {
              setState(() {
                _currentTrendingIndex = index;
              });
            },
            itemCount: trendingIssues.length,
            itemBuilder: (context, index) {
              final issue = trendingIssues[index];
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3B82F6).withOpacity(0.1),
                      const Color(0xFF8B5CF6).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            issue['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Icon(
                          issue['trend'] == 'up'
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: issue['trend'] == 'up'
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: (issue['sentiment'] as int) / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        issue['sentiment'] as int > 70
                            ? const Color(0xFF10B981)
                            : issue['sentiment'] as int > 50
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${issue['sentiment']}% Positive Sentiment',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: Lottie.network(
                        'https://lottie.host/embed/4d0b85c4-2f9d-4b76-8b5a-d5c8e7f9a2b1/xyz123abc.json',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.bar_chart,
                            color: const Color(0xFF3B82F6),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(trendingIssues.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentTrendingIndex == index ? 20 : 6,
              decoration: BoxDecoration(
                color: _currentTrendingIndex == index
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRecommendations() {
    final recommendations = [
      {
        'title': 'Focus on Youth Engagement',
        'description':
            'Increase social media presence targeting 18-25 age group',
        'priority': 'High',
        'icon': Icons.people,
      },
      {
        'title': 'Address Healthcare Concerns',
        'description':
            'Public healthcare initiatives showing positive response',
        'priority': 'Medium',
        'icon': Icons.local_hospital,
      },
      {
        'title': 'Infrastructure Messaging',
        'description': 'Highlight recent infrastructure developments',
        'priority': 'High',
        'icon': Icons.construction,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'AI Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AnalyticsPage()),
                );
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...recommendations.map(
          (rec) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    rec['icon'] as IconData,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec['description'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: rec['priority'] == 'High'
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    rec['priority'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      {
        'title': 'Analytics',
        'subtitle': 'Deep Insights',
        'icon': Icons.analytics,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Reports',
        'subtitle': 'Generate Reports',
        'icon': Icons.assessment,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Trending',
        'subtitle': 'Live Trends',
        'icon': Icons.trending_up,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'AI Insights',
        'subtitle': 'Smart Analysis',
        'icon': Icons.psychology,
        'color': const Color(0xFFE11D48),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Smart Features',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 19,
            childAspectRatio: 1.2,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return GestureDetector(
              onTap: () {
                switch (feature['title']) {
                  case 'Analytics':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AnalyticsPage()),
                    );
                    break;
                  case 'Reports':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsPage()),
                    );
                    break;
                  case 'Trending':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TrendingIssuesPage()),
                    );
                    break;
                  case 'AI Insights':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AIAssistantPage()),
                    );
                    break;
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: (feature['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: feature['color'] as Color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      feature['subtitle'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnimatedFAB() {
    return Positioned(
      left: 250,
      bottom: -10,
      child: ScaleTransition(
        scale: _fabAnimation,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showAIChat = true;
              Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AIAssistantPage()),
                    );
            });
          },
          child: Lottie.asset(
            'Assets/animations/chatbot.json',
            width: 170,
            height: 170,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.smart_toy, color: Colors.blue, size: 36);
            },
          ),
        ),
      ),
    );
  }
}
