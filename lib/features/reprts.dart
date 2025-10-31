import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _chartController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _chartAnimation;

  String selectedPeriod = 'Last 7 Days';
  String selectedCategory = 'Overall Performance';
  bool isGeneratingReport = false;

  final List<String> timePeriods = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'Last 6 Months',
    'Last Year',
    'Custom Range'
  ];

  final List<String> reportCategories = [
    'Overall Performance',
    'Policy Decisions',
    'Public Sentiment',
    'Media Coverage',
    'Social Media Impact'
  ];

  // Sample data based on selected period
  Map<String, dynamic> get currentReportData {
    switch (selectedPeriod) {
      case 'Last 7 Days':
        return {
          'positive': 68,
          'negative': 22,
          'neutral': 10,
          'totalMentions': 24580,
          'improvement': '+5.2%',
          'isImproved': true,
          'keyMetrics': [
            {'title': 'Sentiment Score', 'value': '68%', 'change': '+3.2%', 'isPositive': true},
            {'title': 'Public Trust', 'value': '72%', 'change': '+1.8%', 'isPositive': true},
            {'title': 'Media Coverage', 'value': '85%', 'change': '-2.1%', 'isPositive': false},
            {'title': 'Social Engagement', 'value': '91%', 'change': '+7.5%', 'isPositive': true},
          ],
          'chartData': [
            {'day': 'Mon', 'positive': 65, 'negative': 25, 'neutral': 10},
            {'day': 'Tue', 'positive': 70, 'negative': 20, 'neutral': 10},
            {'day': 'Wed', 'positive': 68, 'negative': 22, 'neutral': 10},
            {'day': 'Thu', 'positive': 72, 'negative': 18, 'neutral': 10},
            {'day': 'Fri', 'positive': 69, 'negative': 21, 'neutral': 10},
            {'day': 'Sat', 'positive': 67, 'negative': 23, 'neutral': 10},
            {'day': 'Sun', 'positive': 68, 'negative': 22, 'neutral': 10},
          ],
          'topIssues': [
            {'title': 'Healthcare Initiatives', 'sentiment': 'positive', 'mentions': 8420},
            {'title': 'Infrastructure Development', 'sentiment': 'positive', 'mentions': 6890},
            {'title': 'Education Policy', 'sentiment': 'neutral', 'mentions': 5670},
            {'title': 'Environmental Concerns', 'sentiment': 'negative', 'mentions': 3600},
          ]
        };
      case 'Last 30 Days':
        return {
          'positive': 65,
          'negative': 25,
          'neutral': 10,
          'totalMentions': 156420,
          'improvement': '+2.8%',
          'isImproved': true,
          'keyMetrics': [
            {'title': 'Sentiment Score', 'value': '65%', 'change': '+2.8%', 'isPositive': true},
            {'title': 'Public Trust', 'value': '69%', 'change': '+0.5%', 'isPositive': true},
            {'title': 'Media Coverage', 'value': '78%', 'change': '+4.2%', 'isPositive': true},
            {'title': 'Social Engagement', 'value': '88%', 'change': '+12.3%', 'isPositive': true},
          ],
          'chartData': List.generate(30, (index) => {
            'day': 'Day ${index + 1}',
            'positive': 60 + math.Random().nextInt(15),
            'negative': 20 + math.Random().nextInt(10),
            'neutral': 8 + math.Random().nextInt(5),
          }),
          'topIssues': [
            {'title': 'Economic Policies', 'sentiment': 'positive', 'mentions': 45200},
            {'title': 'Social Welfare', 'sentiment': 'positive', 'mentions': 38900},
            {'title': 'Transportation', 'sentiment': 'neutral', 'mentions': 28700},
            {'title': 'Law & Order', 'sentiment': 'negative', 'mentions': 18600},
          ]
        };
      default:
        return {
          'positive': 62,
          'negative': 28,
          'neutral': 10,
          'totalMentions': 89340,
          'improvement': '-1.5%',
          'isImproved': false,
          'keyMetrics': [
            {'title': 'Sentiment Score', 'value': '62%', 'change': '-1.5%', 'isPositive': false},
            {'title': 'Public Trust', 'value': '66%', 'change': '-2.3%', 'isPositive': false},
            {'title': 'Media Coverage', 'value': '73%', 'change': '+1.2%', 'isPositive': true},
            {'title': 'Social Engagement', 'value': '82%', 'change': '+5.8%', 'isPositive': true},
          ],
          'chartData': [],
          'topIssues': []
        };
    }
  }

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

    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _chartController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  void _onPeriodChanged(String period) {
    setState(() {
      selectedPeriod = period;
    });

    // Reset and restart chart animation
    _chartController.reset();
    Future.delayed(const Duration(milliseconds: 100), () {
      _chartController.forward();
    });
  }

  Future<void> _downloadReport() async {
    setState(() {
      isGeneratingReport = true;
    });

    // Simulate report generation
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      isGeneratingReport = false;
    });

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Report downloaded successfully for $selectedPeriod'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportData = currentReportData;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,color: Colors.blue,),
          onPressed: () => Navigator.of(context).pop(),
        ),
        
        backgroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'Reports',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 1, 46, 117),
            fontSize: 25,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildTimeRangeSelector(),
                    const SizedBox(height: 24),
                    _buildOverviewCards(reportData),
                    const SizedBox(height: 24),
                    _buildSentimentChart(reportData),
                    const SizedBox(height: 24),
                    _buildKeyMetrics(reportData),
                    const SizedBox(height: 24),
                    _buildTopIssues(reportData),
                    const SizedBox(height: 24),
                    _buildDownloadSection(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Time Period',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: timePeriods.length,
                itemBuilder: (context, index) {
                  final period = timePeriods[index];
                  final isSelected = selectedPeriod == period;

                  return GestureDetector(
                    onTap: () => _onPeriodChanged(period),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6)
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        period,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(Map<String, dynamic> data) {
    return SlideTransition(
      position: _slideAnimation,
      child: Row(
        children: [
          Expanded(
            child: _buildOverviewCard(
              'Overall Sentiment',
              '${data['positive']}%',
              data['improvement'],
              data['isImproved'],
              const Color(0xFF10B981),
              Icons.sentiment_very_satisfied,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildOverviewCard(
              'Total Mentions',
              _formatNumber(data['totalMentions']),
              '+12.5%',
              true,
              const Color(0xFF3B82F6),
              Icons.chat_bubble_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, String change,
      bool isPositive, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change,
                      style: TextStyle(
                        color: isPositive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentChart(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Sentiment Analysis Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 40,
                height: 40,
                child: Lottie.network(
                  'https://assets7.lottiefiles.com/packages/lf20_v4wq2ryq.json',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.show_chart,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSentimentLegend(
                  'Positive', '${data['positive']}%', const Color(0xFF10B981)),
              const SizedBox(width: 16),
              _buildSentimentLegend(
                  'Negative', '${data['negative']}%', const Color(0xFFEF4444)),
              const SizedBox(width: 16),
              _buildSentimentLegend(
                  'Neutral', '${data['neutral']}%', const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _chartAnimation,
            builder: (context, child) {
              return SizedBox(
                height: 200,
                child: CustomPaint(
                  painter: SentimentChartPainter(
                    data: data['chartData'] ?? [],
                    animationValue: _chartAnimation.value,
                  ),
                  child: Container(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentLegend(String label, String percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label $percentage',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

 Widget _buildKeyMetrics(Map<String, dynamic> data) {
  // Fix: Cast the list and its items properly
  final metricsList = data['keyMetrics'] as List;
  final metrics = metricsList.map((item) => item as Map<String, dynamic>).toList();

  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Key Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 40,
              height: 40,
              child: Lottie.network(
                'https://assets1.lottiefiles.com/packages/lf20_swnlcdei.json',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.dashboard,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return _buildMetricCard(metric);
          },
        ),
      ],
    ),
  );
}

  Widget _buildMetricCard(Map<String, dynamic> metric) {
    final isPositive = metric['isPositive'] as bool;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.05),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                metric['value'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFF10B981).withOpacity(0.2)
                      : const Color(0xFFEF4444).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  metric['change'],
                  style: TextStyle(
                    color: isPositive
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Text(
            metric['title'],
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIssues(Map<String, dynamic> data) {
  // Fix: Cast the list and its items properly
  final issuesList = data['topIssues'] as List;
  final issues = issuesList.map((item) => item as Map<String, dynamic>).toList();

  if (issues.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Lottie.network(
              'https://assets2.lottiefiles.com/packages/lf20_p21srrjo.json',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.inbox,
                  color: Color(0xFF64748B),
                  size: 40,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No data available for selected period',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Top Discussion Topics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 40,
              height: 40,
              child: Lottie.network(
                'https://assets4.lottiefiles.com/packages/lf20_d6s8b6n8.json',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.topic,
                    color: Color(0xFFE11D48),
                    size: 24,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...issues.map((issue) => _buildIssueItem(issue)),
      ],
    ),
  );
}  Widget _buildIssueItem(Map<String, dynamic> issue) {
    Color sentimentColor;
    IconData sentimentIcon;

    switch (issue['sentiment']) {
      case 'positive':
        sentimentColor = const Color(0xFF10B981);
        sentimentIcon = Icons.sentiment_very_satisfied;
        break;
      case 'negative':
        sentimentColor = const Color(0xFFEF4444);
        sentimentIcon = Icons.sentiment_very_dissatisfied;
        break;
      default:
        sentimentColor = const Color(0xFFF59E0B);
        sentimentIcon = Icons.sentiment_neutral;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sentimentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sentimentColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: sentimentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              sentimentIcon,
              color: sentimentColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              issue['title'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Text(
            '${_formatNumber(issue['mentions'])} mentions',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Lottie.network(
                  'https://assets1.lottiefiles.com/packages/lf20_c6k5zftb.json',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.download,
                      color: Colors.white,
                      size: 30,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Detailed Report',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Generate comprehensive PDF report for your team',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isGeneratingReport ? null : _downloadReport,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isGeneratingReport
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isGeneratingReport) ...[
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Generating Report...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.picture_as_pdf,
                            color: Color(0xFF3B82F6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Download PDF Report',
                            style: TextStyle(
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.share,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class SentimentChartPainter extends CustomPainter {
  final List<dynamic> data;
  final double animationValue;

  SentimentChartPainter({
    required this.data,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final positivePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final negativePaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final neutralPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final positiveAreaPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF10B981).withOpacity(0.3),
          const Color(0xFF10B981).withOpacity(0.01),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final stepX = data.length > 1 ? size.width / (data.length - 1) : size.width;

    // Draw positive sentiment line and area
    final positivePath = Path();
    final positiveAreaPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y =
          size.height - (data[i]['positive'] / 100 * size.height * animationValue);

      if (i == 0) {
        positivePath.moveTo(x, y);
        positiveAreaPath.moveTo(x, size.height);
        positiveAreaPath.lineTo(x, y);
      } else {
        positivePath.lineTo(x, y);
        positiveAreaPath.lineTo(x, y);
      }
    }

    if (data.isNotEmpty) {
       positiveAreaPath.lineTo(
        (data.length - 1) * stepX,
        size.height,
      );
      positiveAreaPath.close();
      canvas.drawPath(positiveAreaPath, positiveAreaPaint);
    }
    canvas.drawPath(positivePath, positivePaint);
    
    // Draw negative sentiment line
    final negativePath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y =
          size.height - (data[i]['negative'] / 100 * size.height * animationValue);

      if (i == 0) {
        negativePath.moveTo(x, y);
      } else {
        negativePath.lineTo(x, y);
      }
    }
    canvas.drawPath(negativePath, negativePaint);

    // Draw neutral sentiment line
    final neutralPath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y =
          size.height - (data[i]['neutral'] / 100 * size.height * animationValue);

      if (i == 0) {
        neutralPath.moveTo(x, y);
      } else {
        neutralPath.lineTo(x, y);
      }
    }
    canvas.drawPath(neutralPath, neutralPaint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}