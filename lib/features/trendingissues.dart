import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class TrendingIssuesPage extends StatefulWidget {
  const TrendingIssuesPage({Key? key}) : super(key: key);

  @override
  State<TrendingIssuesPage> createState() => _TrendingIssuesPageState();
}

class _TrendingIssuesPageState extends State<TrendingIssuesPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String geminiApiKey = "AIzaSyDsiN5h4CSUDuQ_Lf8VffVdNtSc7qDyzG0"; // Replace with your API key

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _trendingIssues = [];
  final Map<String, bool> _expandedSolutions = {};
  final Map<String, bool> _generatingSolution = {};

  int _activeIssuesCount = 0;
  int _criticalIssuesCount = 0;
  int _totalMentions = 0;

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

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });

    _pulseController.repeat(reverse: true);

    // Load trending issues
    _loadTrendingIssues();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingIssues() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final now = DateTime.now();
      final todayDate = DateFormat('yyyy-MM-dd').format(now);

      // Check if trending issues exist and are still valid (within 10 hours)
      final docSnapshot = await _firestore
          .collection('trending_issues')
          .doc(todayDate)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final hoursDifference = now.difference(timestamp).inHours;

        if (hoursDifference < 10) {
          // Load from Firebase (data is still fresh)
          print('Loading trending issues from Firebase cache');
          setState(() {
            _trendingIssues = List<Map<String, dynamic>>.from(data['issues'] ?? []);
            _calculateStats();
            _isLoading = false;
          });
          return;
        } else {
          print('Cache expired (${hoursDifference}h old), fetching new data');
        }
      }

      // Fetch new trending issues from Gemini
      await _fetchAndStoreTrendingIssues(todayDate);
    } catch (e, s) {
      print('--- ERROR IN _loadTrendingIssues ---');
      print(e);
      print(s);
      setState(() {
        _errorMessage = 'Error loading trending issues: ${e.toString()}';
        _isLoading = false;
        _trendingIssues = _getFallbackIssues();
        _calculateStats();
      });
    }
  }

  Future<void> _fetchAndStoreTrendingIssues(String date) async {
    try {
      // Delete old trending issues (keep last 3 days)
      final oldDate = DateTime.now().subtract(const Duration(days: 3));
      final oldDateStr = DateFormat('yyyy-MM-dd').format(oldDate);

      final oldDocs = await _firestore
          .collection('trending_issues')
          .where(FieldPath.documentId, isLessThan: oldDateStr)
          .get();

      for (var doc in oldDocs.docs) {
        await doc.reference.delete();
      }

      print('Fetching trending issues from Gemini...');

      // Try to fetch from Gemini
      List<Map<String, dynamic>>? geminiResponse = await _fetchGeminiTrendingIssues();

      // If Gemini fails, use fallback data
      if (geminiResponse == null || geminiResponse.isEmpty) {
        print('Gemini failed, using fallback data');
        geminiResponse = _getFallbackIssues();
      }

      // Store in Firebase
      await _firestore.collection('trending_issues').doc(date).set({
        'date': date,
        'timestamp': FieldValue.serverTimestamp(),
        'issues': geminiResponse,
        'source': geminiResponse == _getFallbackIssues() ? 'fallback' : 'gemini',
      });

      setState(() {
        _trendingIssues = geminiResponse!;
        _calculateStats();
        _isLoading = false;
      });

      print('✅ Trending issues stored successfully');
    } catch (e, s) {
      print('--- ERROR IN _fetchAndStoreTrendingIssues ---');
      print(e);
      print(s);

      // Last resort: use fallback data
      setState(() {
        _trendingIssues = _getFallbackIssues();
        _calculateStats();
        _isLoading = false;
        _errorMessage = 'Using sample data. Error: ${e.toString()}';
      });
    }
  }

  Future<List<Map<String, dynamic>>?> _fetchGeminiTrendingIssues() async {
    final String prompt = '''
You are a political analyst specializing in DMK (Dravida Munnetra Kazhagam) party governance in Tamil Nadu, India.

Analyze and identify the TOP 6-8 REAL trending issues currently affecting Tamil Nadu under DMK governance. Focus on:
1. Issues actively discussed in Tamil Nadu news and social media
2. Problems specifically related to DMK's governance areas
3. Current challenges faced by Tamil Nadu residents

For each issue, provide detailed information following this exact structure.

Return ONLY a valid JSON array (no markdown, no explanations, no code blocks). Each object MUST have ALL these fields:

{
  "rank": 1,
  "title": "Brief Issue Title (50 chars max)",
  "description": "Detailed description of the issue in one clear sentence (150 chars max)",
  "location": "Specific Location, Tamil Nadu",
  "severity": "Critical" | "High" | "Medium",
  "mentions": 15420,
  "trend": "up" | "stable" | "down",
  "trendPercentage": "+12%" | "-5%" | "+0%",
  "category": "Infrastructure" | "Education" | "Healthcare" | "Transportation" | "Environment" | "Agriculture" | "Utilities" | "Economy",
  "imageUrl": "https://images.unsplash.com/photo-XXXXX?w=400&h=200&fit=crop",
  "timeAgo": "2 hours ago" | "4 hours ago" | "1 day ago",
  "source": "News Source Name",
  "aiSolution": null
}

CRITICAL REQUIREMENTS:
- Ensure severity levels are realistic (not all Critical)
- Mentions should vary realistically (5000-20000 range)
- Use real Tamil Nadu locations
- Image URLs must be valid Unsplash URLs related to the issue category
- All strings must be properly escaped
- No line breaks inside string values
- Focus on CURRENT issues (2024-2025)''';

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
            "temperature": 0.8,
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

      if (res["candidates"] == null || res["candidates"].isEmpty) {
        throw Exception("No candidates in response");
      }

      String text = res["candidates"][0]["content"]["parts"][0]["text"] ?? "";
      print('Raw Gemini Response:');
      print(text);

      // Clean the response
      text = text.trim();
      text = text.replaceAll('```json', '');
      text = text.replaceAll('```', '');
      text = text.trim();

      // Find JSON array
      int startIndex = text.indexOf('[');
      int endIndex = text.lastIndexOf(']');

      if (startIndex == -1 || endIndex == -1) {
        throw Exception("No JSON array found in response");
      }

      text = text.substring(startIndex, endIndex + 1);

      print('Cleaned JSON:');
      print(text);

      // Parse JSON
      dynamic jsonData;
      try {
        jsonData = jsonDecode(text);
      } catch (e) {
        print('JSON Parse Error: $e');
        text = _fixCommonJsonIssues(text);
        jsonData = jsonDecode(text);
      }

      if (jsonData is! List) {
        throw Exception("Expected JSON array, got ${jsonData.runtimeType}");
      }

      return List<Map<String, dynamic>>.from(jsonData);
    } catch (e, st) {
      print("--- ERROR IN _fetchGeminiTrendingIssues ---");
      print(e);
      print(st);
      return _getFallbackIssues();
    }
  }

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

  List<Map<String, dynamic>> _getFallbackIssues() {
    return [
      {
        'rank': 1,
        'title': 'Chennai Water Crisis',
        'description':
            'Severe water shortage affecting millions of residents in Chennai metropolitan area',
        'location': 'Chennai, Tamil Nadu',
        'severity': 'Critical',
        'mentions': 15420,
        'trend': 'up',
        'trendPercentage': '+12%',
        'category': 'Infrastructure',
        'imageUrl':
            'https://images.unsplash.com/photo-1581833971358-2c8b550f87b3?w=400&h=200&fit=crop',
        'timeAgo': '2 hours ago',
        'source': 'Tamil Nadu News',
        'aiSolution': null,
      },
      {
        'rank': 2,
        'title': 'NEET Exam Controversy',
        'description':
            'Students protesting against NEET exam system affecting Tamil Nadu medical admissions',
        'location': 'Tamil Nadu',
        'severity': 'High',
        'mentions': 12890,
        'trend': 'up',
        'trendPercentage': '+25%',
        'category': 'Education',
        'imageUrl':
            'https://images.unsplash.com/photo-1523050854058-8df90110c9d1?w=400&h=200&fit=crop',
        'timeAgo': '4 hours ago',
        'source': 'Education Times',
        'aiSolution': null,
      },
      {
        'rank': 3,
        'title': 'Industrial Pollution in Cuddalore',
        'description':
            'Chemical factories causing environmental degradation and health issues for local residents',
        'location': 'Cuddalore, Tamil Nadu',
        'severity': 'High',
        'mentions': 8750,
        'trend': 'up',
        'trendPercentage': '+8%',
        'category': 'Environment',
        'imageUrl':
            'https://images.unsplash.com/photo-1611273426858-450d8e3c9fce?w=400&h=200&fit=crop',
        'timeAgo': '6 hours ago',
        'source': 'Environmental Watch',
        'aiSolution': null,
      },
      {
        'rank': 4,
        'title': 'Bus Strike in Coimbatore',
        'description':
            'Public transportation disrupted due to ongoing bus drivers strike',
        'location': 'Coimbatore, Tamil Nadu',
        'severity': 'Medium',
        'mentions': 6420,
        'trend': 'stable',
        'trendPercentage': '+2%',
        'category': 'Transportation',
        'imageUrl':
            'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=400&h=200&fit=crop',
        'timeAgo': '8 hours ago',
        'source': 'Transport News',
        'aiSolution': null,
      },
      {
        'rank': 5,
        'title': 'Power Outages in Salem',
        'description':
            'Frequent electricity cuts affecting businesses and daily life',
        'location': 'Salem, Tamil Nadu',
        'severity': 'Medium',
        'mentions': 5890,
        'trend': 'up',
        'trendPercentage': '+15%',
        'category': 'Utilities',
        'imageUrl':
            'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=400&h=200&fit=crop',
        'timeAgo': '10 hours ago',
        'source': 'Power Grid News',
        'aiSolution': null,
      },
      {
        'rank': 6,
        'title': 'Fishermen Strike in Rameshwaram',
        'description':
            'Traditional fishermen protesting against deep-sea fishing restrictions',
        'location': 'Rameshwaram, Tamil Nadu',
        'severity': 'Medium',
        'mentions': 4320,
        'trend': 'up',
        'trendPercentage': '+18%',
        'category': 'Agriculture',
        'imageUrl':
            'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400&h=200&fit=crop',
        'timeAgo': '12 hours ago',
        'source': 'Coastal News',
        'aiSolution': null,
      },
    ];
  }

  void _calculateStats() {
    _activeIssuesCount = _trendingIssues.length;
    _criticalIssuesCount = _trendingIssues
        .where((issue) =>
            issue['severity'] == 'Critical' || issue['severity'] == 'High')
        .length;
    _totalMentions = _trendingIssues.fold(
        0, (sum, issue) => sum + (issue['mentions'] as int? ?? 0));
  }

  Future<void> _refreshTrendingIssues() async {
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Delete today's trending issues to force refresh
    await _firestore.collection('trending_issues').doc(todayDate).delete();

    // Fetch new trending issues
    await _loadTrendingIssues();
  }

  Future<void> _generateAISolution(int index) async {
    final issueKey = _trendingIssues[index]['title'];

    setState(() {
      _generatingSolution[issueKey] = true;
    });

    // Simulate AI generation with Gemini
    await Future.delayed(const Duration(seconds: 2));

    final aiSolution = await _generateAISolutionWithGemini(_trendingIssues[index]);

    setState(() {
      _generatingSolution[issueKey] = false;
      _trendingIssues[index]['aiSolution'] = aiSolution;
    });
  }

  Future<Map<String, dynamic>> _generateAISolutionWithGemini(
      Map<String, dynamic> issue) async {
    // You can optionally call Gemini API here for AI-generated solutions
    // For now, returning structured solution based on issue type

    return {
      'shortTerm': [
        'Deploy immediate response measures',
        'Set up emergency support systems',
        'Implement quick-fix solutions'
      ],
      'mediumTerm': [
        'Develop comprehensive action plan',
        'Upgrade existing infrastructure',
        'Strengthen monitoring systems'
      ],
      'longTerm': [
        'Create sustainable policy framework',
        'Invest in long-term solutions',
        'Establish preventive measures'
      ],
      'budget': '₹500-1500 Crores',
      'timeline': '6-18 months',
      'impact': 'Significant positive impact on affected population'
    };
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
          'Trending Issues',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 1, 46, 117),
            fontSize: 25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _isLoading ? null : _refreshTrendingIssues,
            tooltip: 'Refresh Issues',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading trending issues...',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: RefreshIndicator(
                  onRefresh: _refreshTrendingIssues,
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: Colors.orange.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          color: Colors.orange.shade900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            _buildStatsOverview(),
                            const SizedBox(height: 24),
                            _buildTrendingList(),
                            const SizedBox(height: 100),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Lottie.network(
                      'https://assets1.lottiefiles.com/packages/lf20_gslb0ringer.json',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.trending_up,
                          color: Color(0xFF10B981),
                          size: 30,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_activeIssuesCount',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const Text(
                    'Active Issues',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: const Color(0xFFE2E8F0),
            ),
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Lottie.network(
                      'https://assets2.lottiefiles.com/packages/lf20_Gbabwr.json',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.priority_high,
                          color: Color(0xFFEF4444),
                          size: 30,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_criticalIssuesCount',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const Text(
                    'Critical Issues',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: const Color(0xFFE2E8F0),
            ),
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Lottie.network(
                      'https://assets8.lottiefiles.com/packages/lf20_qTwzcw.json',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.chat_bubble_outline,
                          color: Color(0xFF3B82F6),
                          size: 30,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(_totalMentions / 1000).toStringAsFixed(0)}K+',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const Text(
                    'Total Mentions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Trending Issues',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        ..._trendingIssues.asMap().entries.map((entry) {
          return _buildIssueCard(entry.value, entry.key);
        }),
      ],
    );
  }

  Widget _buildIssueCard(Map<String, dynamic> issue, int index) {
    final issueKey = issue['title'];
    final isExpanded = _expandedSolutions[issueKey] ?? false;
    final isGenerating = _generatingSolution[issueKey] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          _buildIssueHeader(issue),
          _buildIssueImage(issue),
          _buildIssueContent(issue),
          _buildIssueActions(issue, index, isExpanded, isGenerating),
          if (isExpanded && issue['aiSolution'] != null)
            _buildAISolutionSection(issue['aiSolution']),
        ],
      ),
    );
  }

  // ... (Keep all the remaining widget methods from the original code)
  // _buildIssueHeader, _buildIssueImage, _buildIssueContent, 
  // _buildIssueActions, _buildAISolutionSection, _buildSolutionPhase
  // Copy them exactly as they are in your original code

  Widget _buildIssueHeader(Map<String, dynamic> issue) {
    Color severityColor;
    switch (issue['severity']) {
      case 'Critical':
        severityColor = const Color(0xFFEF4444);
        break;
      case 'High':
        severityColor = const Color(0xFFE11D48);
        break;
      case 'Medium':
        severityColor = const Color(0xFFF59E0B);
        break;
      default:
        severityColor = const Color(0xFF10B981);
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF8B5CF6),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#${issue['rank']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        issue['severity'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        issue['category'],
                        style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  issue['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    issue['trend'] == 'up'
                        ? Icons.trending_up
                        : Icons.trending_flat,
                    color: issue['trend'] == 'up'
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    issue['trendPercentage'],
                    style: TextStyle(
                      color: issue['trend'] == 'up'
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${issue['mentions']} mentions',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIssueImage(Map<String, dynamic> issue) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.network(
              issue['imageUrl'],
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFE2E8F0),
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      color: Color(0xFF64748B),
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue['source'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            issue['timeAgo'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            issue['location'].split(',')[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueContent(Map<String, dynamic> issue) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        issue['description'],
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF64748B),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildIssueActions(
      Map<String, dynamic> issue, int index, bool isExpanded, bool isGenerating) {
    final issueKey = issue['title'];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: isGenerating
                  ? null
                  : () async {
                      if (issue['aiSolution'] == null) {
                        await _generateAISolution(index);
                      }
                      setState(() {
                        _expandedSolutions[issueKey] = !isExpanded;
                      });
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isGenerating
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        ),
                  color: isGenerating ? const Color(0xFFE2E8F0) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isGenerating) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Generating Solution...',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        issue['aiSolution'] == null
                            ? 'Solve with AI'
                            : isExpanded
                                ? 'Hide Solution'
                                : 'View AI Solution',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISolutionSection(Map<String, dynamic> solution) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.05),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 20),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                child: Lottie.network(
                  'https://assets10.lottiefiles.com/packages/lf20_vPbrrm.json',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.psychology,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI-Generated Solution Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Timeline',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        solution['timeline'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: Color(0xFF3B82F6),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Budget',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        solution['budget'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Color(0xFF10B981),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Expected Impact',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  solution['impact'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSolutionPhase(
            'Short-term Actions (0-3 months)',
            solution['shortTerm'] as List<String>,
            const Color(0xFFEF4444),
            Icons.flash_on,
          ),
          const SizedBox(height: 16),
          _buildSolutionPhase(
            'Medium-term Plans (3-12 months)',
            solution['mediumTerm'] as List<String>,
            const Color(0xFFF59E0B),
            Icons.build,
          ),
          const SizedBox(height: 16),
          _buildSolutionPhase(
            'Long-term Strategy (12+ months)',
            solution['longTerm'] as List<String>,
            const Color(0xFF10B981),
            Icons.flag,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Lottie.network(
                    'https://assets9.lottiefiles.com/packages/lf20_k9wsvfcs.json',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.info_outline,
                        color: Color(0xFF3B82F6),
                        size: 16,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'This solution is AI-generated and should be reviewed by policy experts.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionPhase(
      String title, List<String> items, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
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
          ...items.map((item) => Padding(
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}