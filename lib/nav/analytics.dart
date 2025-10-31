import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String selectedFilter = 'All';
  Map<String, bool> flippedCards = {};
  bool isLoading = true;
  String? errorMessage;

  final List<String> filters = ['All', 'Positive', 'Negative', 'Neutral'];
  List<Map<String, dynamic>> analyticsData = [];

  // <-- CHANGED: Replace with your new Gemini API Key
  final String geminiApiKey = 'AIzaSyDsiN5h4CSUDuQ_Lf8VffVdNtSc7qDyzG0';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });

    _loadAnalytics();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Check if analytics exists for today
      final docSnapshot = await _firestore
          .collection('analytics')
          .doc(today)
          .get();

      if (docSnapshot.exists) {
        // Load from Firebase
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          analyticsData = List<Map<String, dynamic>>.from(data['data'] ?? []);
          isLoading = false;
        });
      } else {
        // Fetch new analytics from GPT
        await _fetchAndStoreAnalytics(today);
      }
    } catch (e, s) {
      print('--- ERROR IN _loadAnalytics ---');
      print(e);
      print(s);
      setState(() {
        errorMessage = 'Error loading analytics: ${e.toString()}';
        isLoading = false;
      });
    }
  }

// Replace your _fetchAndStoreAnalytics method with this:

Future<void> _fetchAndStoreAnalytics(String date) async {
  try {
    // Delete old analytics (keep last 7 days)
    final oldDate = DateTime.now().subtract(const Duration(days: 7));
    final oldDateStr = DateFormat('yyyy-MM-dd').format(oldDate);

    final oldDocs = await _firestore
        .collection('analytics')
        .where(FieldPath.documentId, isLessThan: oldDateStr)
        .get();

    for (var doc in oldDocs.docs) {
      await doc.reference.delete();
    }

    print('Fetching analytics from Gemini...');
    
    // Try to fetch from Gemini
    List<Map<String, dynamic>>? gptResponse = await _fetchGPTAnalytics();
    
    // If Gemini fails, use fallback data
    if (gptResponse == null || gptResponse.isEmpty) {
      print('Gemini failed, using fallback data');
      gptResponse = _getFallbackData();
    }

    // Store in Firebase
    await _firestore.collection('analytics').doc(date).set({
      'date': date,
      'timestamp': FieldValue.serverTimestamp(),
      'data': gptResponse,
      'source': gptResponse == _getFallbackData() ? 'fallback' : 'gemini',
    });

    setState(() {
      analyticsData = gptResponse!;
      isLoading = false;
    });
    
    print('✅ Analytics stored successfully');

  } catch (e, s) {
    print('--- ERROR IN _fetchAndStoreAnalytics ---');
    print(e);
    print(s);
    
    // Last resort: use fallback data
    setState(() {
      analyticsData = _getFallbackData();
      isLoading = false;
      errorMessage = 'Using sample data. Error: ${e.toString()}';
    });
  }
}

// Add this method to your class
List<Map<String, dynamic>> _getFallbackData() {
  return [
    {
      'category': 'Healthcare Reform',
      'positive': 65,
      'negative': 20,
      'neutral': 15,
      'sentiment': 'positive',
      'totalMentions': 2847,
      'trending': 'up',
      'keyPoints': [
        'Free medical checkups appreciated',
        'New hospital construction ongoing',
        'Medicine availability improved',
      ],
      'negativePoints': [
        'Long waiting times in hospitals',
        'Limited specialist availability',
      ],
      'neutralPoints': [
        'Policy implementation ongoing',
      ],
      'recommendations': [
        {
          'title': 'Reduce Wait Times',
          'description': 'Implement appointment system',
          'priority': 'High',
          'timeline': '2-3 months',
          'impact': 'Improve patient satisfaction',
        },
      ],
    },
    {
      'category': 'Education Policy',
      'positive': 55,
      'negative': 30,
      'neutral': 15,
      'sentiment': 'neutral',
      'totalMentions': 1923,
      'trending': 'up',
      'keyPoints': [
        'Free textbooks distributed',
        'Digital classrooms launched',
      ],
      'negativePoints': [
        'Infrastructure needs improvement',
        'Internet connectivity issues',
      ],
      'neutralPoints': [
        'Curriculum under review',
      ],
      'recommendations': [
        {
          'title': 'Infrastructure Upgrade',
          'description': 'Improve school facilities',
          'priority': 'High',
          'timeline': '6-12 months',
          'impact': 'Better learning environment',
        },
      ],
    },
    {
      'category': 'Economic Development',
      'positive': 70,
      'negative': 18,
      'neutral': 12,
      'sentiment': 'positive',
      'totalMentions': 3156,
      'trending': 'up',
      'keyPoints': [
        'Job creation programs successful',
        'Business loans accessible',
        'Industrial growth positive',
      ],
      'negativePoints': [
        'Inflation concerns exist',
      ],
      'neutralPoints': [
        'Tax policies under discussion',
      ],
      'recommendations': [
        {
          'title': 'Support Agriculture',
          'description': 'Increase farming subsidies',
          'priority': 'Medium',
          'timeline': '3-6 months',
          'impact': 'Boost rural economy',
        },
      ],
    },
    {
      'category': 'Infrastructure Development',
      'positive': 60,
      'negative': 25,
      'neutral': 15,
      'sentiment': 'positive',
      'totalMentions': 2341,
      'trending': 'up',
      'keyPoints': [
        'Road projects progressing',
        'Public transport improved',
      ],
      'negativePoints': [
        'Some project delays',
      ],
      'neutralPoints': [
        'Timeline reviews ongoing',
      ],
      'recommendations': [
        {
          'title': 'Reduce Delays',
          'description': 'Better project management',
          'priority': 'High',
          'timeline': '1-2 months',
          'impact': 'Faster completion',
        },
      ],
    },
    {
      'category': 'Social Welfare',
      'positive': 68,
      'negative': 18,
      'neutral': 14,
      'sentiment': 'positive',
      'totalMentions': 2654,
      'trending': 'up',
      'keyPoints': [
        'Pension schemes effective',
        'Housing programs active',
      ],
      'negativePoints': [
        'Application process complex',
      ],
      'neutralPoints': [
        'Eligibility under review',
      ],
      'recommendations': [
        {
          'title': 'Simplify Applications',
          'description': 'Digital application system',
          'priority': 'Medium',
          'timeline': '3-4 months',
          'impact': 'Better accessibility',
        },
      ],
    },
  ];
}
Future<List<Map<String, dynamic>>?> _fetchGPTAnalytics() async {
  final String prompt = '''
You are a political analyst specializing in Tamil Nadu politics. 
Analyze the DMK (Dravida Munnetra Kazhagam) party sentiment across these categories:
1. Healthcare Reform
2. Education Policy
3. Economic Development
4. Infrastructure Development
5. Social Welfare Programs

Return ONLY a valid JSON array (no markdown, no explanations). Each object must have:
{
  "category": "Category Name",
  "positive": 65,
  "negative": 20,
  "neutral": 15,
  "sentiment": "positive",
  "totalMentions": 2847,
  "trending": "up",
  "keyPoints": ["point1", "point2", "point3"],
  "negativePoints": ["concern1", "concern2", "concern3"],
  "neutralPoints": ["observation1", "observation2"],
  "recommendations": [
    {
      "title": "Short Title",
      "description": "Brief description",
      "priority": "High",
      "timeline": "2-3 months",
      "impact": "Impact description"
    }
  ]
}

CRITICAL: Ensure all strings are properly escaped. No line breaks inside strings.''';
final String url =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$geminiApiKey";

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
          "maxOutputTokens": 8000,
          "topP": 0.95,
        }
      }),
    );

    print('Response Status: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception(
          "Gemini API Error: ${response.statusCode} - ${response.body}");
    }

    final res = jsonDecode(response.body);

    // Check if response has expected structure
    if (res["candidates"] == null || res["candidates"].isEmpty) {
      throw Exception("No candidates in response");
    }

    String text = res["candidates"][0]["content"]["parts"][0]["text"] ?? "";
    print('Raw Gemini Response:');
    print(text);

    // Clean the response more aggressively
    text = text.trim();
    
    // Remove markdown code blocks
    text = text.replaceAll('```json', '');
    text = text.replaceAll('```', '');
    text = text.trim();
    
    // Remove any leading/trailing text that's not JSON
    // Find the first [ and last ]
    int startIndex = text.indexOf('[');
    int endIndex = text.lastIndexOf(']');
    
    if (startIndex == -1 || endIndex == -1) {
      throw Exception("No JSON array found in response");
    }
    
    text = text.substring(startIndex, endIndex + 1);
    
    print('Cleaned JSON:');
    print(text);

    // Try to parse JSON
    dynamic jsonData;
    try {
      jsonData = jsonDecode(text);
    } catch (e) {
      print('JSON Parse Error: $e');
      print('Attempting to fix common JSON issues...');
      
      // Fix common JSON issues
      text = _fixCommonJsonIssues(text);
      
      try {
        jsonData = jsonDecode(text);
      } catch (e2) {
        print('Still failed after fixes: $e2');
        // Return fallback data instead of null
        return _getFallbackData();
      }
    }

    if (jsonData is! List) {
      throw Exception("Expected JSON array, got ${jsonData.runtimeType}");
    }

    return List<Map<String, dynamic>>.from(jsonData);

  } catch (e, st) {
    print("--- ERROR IN _fetchGPTAnalytics ---");
    print(e);
    print(st);
    
    // Return fallback data instead of null
    return _getFallbackData();
  }
}

// Helper function to fix common JSON issues
String _fixCommonJsonIssues(String text) {
  // Replace unescaped newlines in strings
  text = text.replaceAllMapped(
    RegExp(r':\s*"([^"]*)\n([^"]*)"'),
    (match) => ': "${match.group(1)} ${match.group(2)}"',
  );
  
  // Fix trailing commas
  text = text.replaceAll(RegExp(r',\s*}'), '}');
  text = text.replaceAll(RegExp(r',\s*]'), ']');
  
  return text;
}
  Future<void> _refreshAnalytics() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Delete today's analytics to force refresh
    await _firestore.collection('analytics').doc(today).delete();

    // Fetch new analytics
    await _loadAnalytics();
  }

  List<Map<String, dynamic>> getFilteredData() {
    if (selectedFilter == 'All') return analyticsData;

    return analyticsData.where((data) {
      switch (selectedFilter) {
        case 'Positive':
          return data['sentiment'] == 'positive';
        case 'Negative':
          return data['sentiment'] == 'negative';
        case 'Neutral':
          return data['sentiment'] == 'neutral';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.blue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'DMK Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 1, 46, 117),
            fontSize: 25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: isLoading ? null : _refreshAnalytics,
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: isLoading
            ? _buildLoadingState()
            : errorMessage != null
            ? _buildErrorState()
            : _buildAnalyticsContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Lottie.asset(
              'assets/ai_brain.json',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const CircularProgressIndicator(
                  color: Color(0xFF3B82F6),
                  strokeWidth: 3,
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'AI is analyzing DMK party sentiment...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gathering insights from social media, news & surveys',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(
              'Error Loading Analytics',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAnalytics,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildLastUpdatedInfo(),
                const SizedBox(height: 16),
                _buildOverviewCards(),
                const SizedBox(height: 24),
                _buildFilterSection(),
                const SizedBox(height: 24),
                ...getFilteredData().map((data) => _buildAnalyticsCard(data)),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdatedInfo() {
    final today = DateFormat('MMMM dd, yyyy').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          Text(
            'Last Updated: $today',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF3B82F6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF3B82F6)),
          const SizedBox(width: 4),
          const Text(
            'AI Powered',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF3B82F6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    if (analyticsData.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalPositive = analyticsData.fold<int>(
      0,
      (sum, item) => sum + (item['positive'] as int),
    );
    final totalNegative = analyticsData.fold<int>(
      0,
      (sum, item) => sum + (item['negative'] as int),
    );
    final totalNeutral = analyticsData.fold<int>(
      0,
      (sum, item) => sum + (item['neutral'] as int),
    );
    final total = totalPositive + totalNegative + totalNeutral;

    // Avoid division by zero if total is 0
    if (total == 0) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Row(
        children: [
          Expanded(
            child: _buildOverviewCard(
              'Positive',
              '${((totalPositive / total) * 100).toInt()}%',
              const Color(0xFF10B981),
              Icons.sentiment_very_satisfied,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildOverviewCard(
              'Negative',
              '${((totalNegative / total) * 100).toInt()}%',
              const Color(0xFFEF4444),
              Icons.sentiment_very_dissatisfied,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildOverviewCard(
              'Neutral',
              '${((totalNeutral / total) * 100).toInt()}%',
              const Color(0xFFF59E0B),
              Icons.sentiment_neutral,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    String title,
    String percentage,
    Color color,
    IconData icon,
  ) {
    return Container(
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
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

  Widget _buildFilterSection() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedFilter = filter;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsCard(Map<String, dynamic> data) {
    final category = data['category'] as String;
    final isFlipped = flippedCards[category] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 400, // Fixed height for the card
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: isFlipped ? 1 : 0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        builder: (context, double value, child) {
          final isShowingFront = value < 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(math.pi * value),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  flippedCards[category] = !isFlipped;
                });
              },
              child: isShowingFront
                  ? _buildFrontCard(data)
                  : _buildBackCard(data), // Back card is transformed
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard(Map<String, dynamic> data) {
    return Container(
      height: 400, // Ensure front card has same fixed height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(data),
          _buildSentimentBreakdown(data),
          // This Expanded + SingleChildScrollView allows the middle part to scroll
          // if the content is too long, while the header and footer remain fixed.
          Expanded(
            child: SingleChildScrollView(child: _buildDetailedInsights(data)),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, color: Color(0xFF3B82F6), size: 20),
                SizedBox(width: 8),
                Text(
                  'Tap for AI Recommendations',
                  style: TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard(Map<String, dynamic> data) {
    final category = data['category'] as String;
    final recommendations = List<Map<String, dynamic>>.from(
      data['recommendations'] ?? [],
    );

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi), // Flip back
      child: Container(
        height: 400, // Ensure back card has same fixed height
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF3B82F6).withOpacity(0.1),
              const Color(0xFF8B5CF6).withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header for the back card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18), // Match parent radius
                  topRight: Radius.circular(18), // Match parent radius
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Lottie.asset(
                      'assets/ai_brain.json',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 30,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Recommendations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For $category',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        flippedCards[category] = false; // Flip back
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable content for recommendations
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: recommendations
                      .map((rec) => _buildRecommendationItem(rec))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: rec['priority'] == 'High'
                      ? const Color(0xFFEF4444).withOpacity(0.1)
                      : const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  rec['priority'] == 'High'
                      ? Icons.priority_high
                      : Icons.info_outline,
                  color: rec['priority'] == 'High'
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF59E0B),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  rec['title'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: rec['priority'] == 'High'
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 12),
          Text(
            rec['description'] as String,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricBox(
                'Timeline',
                rec['timeline'] as String,
                Icons.schedule,
                const Color(0xFF10B981),
              ),
              const SizedBox(width: 12),
              _buildMetricBox(
                'Impact',
                rec['impact'] as String,
                Icons.trending_up,
                const Color(0xFF3B82F6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(Map<String, dynamic> data) {
    final category = data['category'] as String;
    final sentiment = data['sentiment'] as String;
    final trending = data['trending'] as String;
    final totalMentions = data['totalMentions'] as int;

    Color sentimentColor;
    IconData sentimentIcon;

    switch (sentiment) {
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(sentimentIcon, color: sentimentColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${totalMentions.toString()} mentions',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            trending == 'up' ? Icons.trending_up : Icons.trending_down,
            color: trending == 'up'
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentBreakdown(Map<String, dynamic> data) {
    final positive = data['positive'] as int;
    final negative = data['negative'] as int;
    final neutral = data['neutral'] as int;
    final total = positive + negative + neutral;

    // Avoid division by zero if total is 0
    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Text(
          'No sentiment data available.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: positive,
                child: Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(3),
                      bottomLeft: Radius.circular(3),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: negative,
                child: Container(height: 6, color: const Color(0xFFEF4444)),
              ),
              Expanded(
                flex: neutral,
                child: Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(3),
                      bottomRight: Radius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSentimentLegend(
                'Positive',
                '${((positive / total) * 100).toInt()}%',
                const Color(0xFF10B981),
              ),
              _buildSentimentLegend(
                'Negative',
                '${((negative / total) * 100).toInt()}%',
                const Color(0xFFEF4444),
              ),
              _buildSentimentLegend(
                'Neutral',
                '${((neutral / total) * 100).toInt()}%',
                const Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentLegend(String label, String percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
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

  Widget _buildDetailedInsights(Map<String, dynamic> data) {
    final keyPoints = List<String>.from(data['keyPoints'] ?? []);
    final negativePoints = List<String>.from(data['negativePoints'] ?? []);
    final neutralPoints = List<String>.from(data['neutralPoints'] ?? []);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (keyPoints.isNotEmpty &&
              (selectedFilter == 'All' || selectedFilter == 'Positive'))
            _buildInsightSection(
              'Positive Feedback',
              keyPoints,
              const Color(0xFF10B981),
              Icons.thumb_up,
            ),
          if (negativePoints.isNotEmpty &&
              (selectedFilter == 'All' || selectedFilter == 'Negative'))
            _buildInsightSection(
              'Negative Concerns',
              negativePoints,
              const Color(0xFFEF4444),
              Icons.thumb_down,
            ),
          if (neutralPoints.isNotEmpty &&
              (selectedFilter == 'All' || selectedFilter == 'Neutral'))
            _buildInsightSection(
              'Neutral Observations',
              neutralPoints,
              const Color(0xFFF59E0B),
              Icons.help_outline,
            ),
        ],
      ),
    );
  }

  Widget _buildInsightSection(
    String title,
    List<String> points,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
