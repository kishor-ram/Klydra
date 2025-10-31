import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _typingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _typingAnimation;
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
   final FlutterTts _flutterTts = FlutterTts();
  
  List<ChatMessage> messages = [];
  bool isTyping = false;
  bool isSpeaking = false;
  String selectedLanguage = 'en-US';
  String currentSpeakingMessage = '';
  
  final List<String> quickAccessQuestions = [
    "What are the current trending issues in Tamil Nadu?",
    "How should I handle negative media coverage?",
    "What talking points should I use for healthcare policy?",
    "How can I improve public sentiment in my constituency?",
    "What are the key issues affecting youth voters?",
    "How should I respond to opposition criticism?",
    "What development projects should I prioritize?",
    "How can I address environmental concerns effectively?"
  ];

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
    
    // Add welcome message
    _addWelcomeMessage();
    _initTts();
  }

  // NEW: Setup TTS listeners
  void _initTts() {
    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = true;
        });
      }
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = false;
          currentSpeakingMessage = '';
        });
      }
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          isSpeaking = false;
          currentSpeakingMessage = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _typingController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.blue,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'Klydra AI Assistant',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 1, 46, 117),
            fontSize: 25,
          ),
        ),
        // NEW: Language selection menu
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Colors.blue),
            onSelected: (String languageCode) {
              setState(() {
                selectedLanguage = languageCode;
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Language changed to ${languageCode == 'en-US' ? 'English' : 'Tamil'}'),
              ));
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'en-US',
                child: Text('English'),
              ),
              const PopupMenuItem<String>(
                value: 'ta-IN',
                child: Text('தமிழ் (Tamil)'),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildQuickAccessQuestions(),
              Expanded(child: _buildChatArea()),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }
    super.dispose();
  }

 void _addWelcomeMessage() {
    // MODIFIED: Welcome message is now in Tamil
    messages.add(ChatMessage(
      text: "வணக்கம்! நான் உங்கள் கைத்ரா AI அரசியல் உதவியாளர். உங்களுக்கு அரசியல் நுண்ணறிவுகள் மற்றும் வியூக ஆலோசனைகள் வழங்க இங்கே இருக்கிறேன். இன்று உங்களுக்கு நான் எப்படி உதவ முடியும்?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }


  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();
    _typingController.repeat();

    // Simulate AI response delay
    await Future.delayed(const Duration(seconds: 2));

    final response = _generateAIResponse(text);
    
    setState(() {
      isTyping = false;
      messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    
    _typingController.stop();
    _scrollToBottom();
  }

  Future<void> _speakMessage(String message) async {
    if (isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        isSpeaking = false;
        currentSpeakingMessage = '';
      });
    } else {
      setState(() {
        currentSpeakingMessage = message;
      });
      await _flutterTts.setLanguage(selectedLanguage);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.speak(message);
    }
  }
String _generateAIResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    if (message.contains('trending issues') || message.contains('current issues') || message.contains('பிரச்சனைகள்')) {
      return """Current Trending Issues in Tamil Nadu (Today):

🔥 Top Priority Issues:
1. Chennai Water Crisis - 15,420 mentions (+12%)
   - Immediate concern for 8M+ residents
   - Requires emergency water management

2. NEET Exam Controversy - 12,890 mentions (+25%)
   - Student protests continue
   - Language barrier concerns

3. Industrial Pollution in Cuddalore - 8,750 mentions (+8%)
   - Environmental health crisis
   - Local community outrage

Recommended Actions:
✅ Address water crisis with immediate relief measures.
✅ Engage with student communities on education policy.
✅ Strengthen environmental protection laws.

Would you like detailed strategies for any specific issue?

--- (தமிழ்) ---

தமிழ்நாட்டில் தற்போதைய முக்கிய பிரச்சனைகள்:

🔥 உயர் முன்னுரிமை சிக்கல்கள்:
1.  சென்னை குடிநீர் பற்றாக்குறை - 15,420 குறிப்புகள் (+12%)
    - 8 மில்லியனுக்கும் அதிகமான குடியிருப்பாளர்களுக்கு உடனடி கவலை.
    - அவசர நீர் மேலாண்மை தேவை.

2.  நீட் தேர்வு சர்ச்சை - 12,890 குறிப்புகள் (+25%)
    - மாணவர்கள் போராட்டம் தொடர்கிறது.
    - மொழித் தடை குறித்த கவலைகள்.

3.  கடலூரில் தொழில்துறை மாசுபாடு - 8,750 குறிப்புகள் (+8%)
    - சுற்றுச்சூழல் சுகாதார நெருக்கடி.
    - உள்ளூர் சமூகத்தின் எதிர்ப்பு.

பரிந்துரைக்கப்பட்ட நடவடிக்கைகள்:
✅ குடிநீர் பிரச்சனைக்கு உடனடி நிவாரண நடவடிக்கைகளை மேற்கொள்ளுங்கள்.
✅ கல்வி கொள்கை குறித்து மாணவர் சமூகங்களுடன் கலந்துரையாடுங்கள்.
✅ சுற்றுச்சூழல் பாதுகாப்பு சட்டங்களை வலுப்படுத்துங்கள்.

இந்த குறிப்பிட்ட பிரச்சினைகளில் ஏதேனும் விரிவான வியூகங்கள் வேண்டுமா?""";
    }

    if (message.contains('meeting') || message.contains('speech') || message.contains('attract people')) {
      return """Meeting Strategy for Party Improvement:

🎯 Key Talking Points:
1. Connect with Local Issues: Start with immediate concerns (water, power, transport) and share specific action plans.
2. Youth Engagement: Address education, employment, and digital governance.
3. Development Focus: Highlight infrastructure, healthcare, and agricultural support.

Communication Tips:
🗣️ Use simple, relatable language.
📊 Present data with visual aids.
🤝 Include interactive Q&A sessions.

Would you like me to prepare specific responses for potential questions?

--- (தமிழ்) ---

கட்சியை மேம்படுத்துவதற்கான கூட்ட வியூகம்:

🎯 முக்கிய அம்சங்கள்:
1. உள்ளூர் பிரச்சினைகளுடன் இணையுங்கள்: உடனடி கவலைகளுடன் (நீர், மின்சாரம், போக்குவரத்து) தொடங்கி, குறிப்பிட்ட செயல் திட்டங்களைப் பகிர்ந்து கொள்ளுங்கள்.
2. இளைஞர்களை ஈடுபடுத்துதல்: கல்வி, வேலைவாய்ப்பு மற்றும் டிஜிட்டல் ஆளுமை குறித்துப் பேசுங்கள்.
3. வளர்ச்சியில் கவனம்: உள்கட்டமைப்பு, சுகாதாரம் மற்றும் விவசாய ஆதரவை முன்னிலைப்படுத்துங்கள்.

தகவல்தொடர்பு குறிப்புகள்:
🗣️ எளிய, தொடர்புபடுத்தக்கூடிய மொழியைப் பயன்படுத்துங்கள்.
📊 தரவுகளை காட்சிப்படங்களுடன் வழங்குங்கள்.
🤝 ஊடாடும் கேள்வி-பதில் அமர்வுகளைச் சேர்க்கவும்.

சாத்தியமான கேள்விகளுக்கு நான் குறிப்பிட்ட பதில்களைத் தயாரிக்க வேண்டுமா?""";
    }

    if (message.contains('media') || message.contains('handle media') || message.contains('negative coverage')) {
      return """Media Management Strategy:

🛡️ Handling Negative Coverage:
1. Immediate Response Protocol: Acknowledge concerns quickly and provide factual clarifications.
2. Proactive Measures: Hold regular press briefings and maintain a positive social media presence.
3. Crisis Communication: Appoint a dedicated spokesperson and focus on solutions.

Do's & Don'ts:
✅ Stay factual and show empathy.
❌ Avoid personal attacks and making promises you can't keep.

Need help with specific media scenarios?

--- (தமிழ்) ---

ஊடக மேலாண்மை வியூகம்:

🛡️ எதிர்மறை செய்திகளை கையாளுதல்:
1. உடனடி பதில்: கவலைகளை விரைவாக ஏற்றுக்கொண்டு, உண்மையான விளக்கங்களை வழங்குங்கள்.
2. முன்னெச்சரிக்கை நடவடிக்கைகள்: வழக்கமான பத்திரிகையாளர் சந்திப்புகளை நடத்துங்கள் மற்றும் சமூக ஊடகங்களில் நேர்மறையான இருப்பை பேணுங்கள்.
3. நெருக்கடி தொடர்பு: ஒரு பிரத்யேக செய்தித் தொடர்பாளரை நியமித்து, தீர்வுகளில் கவனம் செலுத்துங்கள்.

செய்ய வேண்டியவை & செய்யக்கூடாதவை:
✅ உண்மையாக இருங்கள் மற்றும் பச்சாதாபம் காட்டுங்கள்.
❌ தனிப்பட்ட தாக்குதல்களைத் தவிர்க்கவும், நிறைவேற்ற முடியாத வாக்குறுதிகளை அளிப்பதைத் தவிர்க்கவும்.

குறிப்பிட்ட ஊடகச் சூழ்நிலைகளுக்கு உதவி தேவையா?""";
    }

    if (message.contains('youth') || message.contains('young voters') || message.contains('students') || message.contains('இளைஞர்கள்')) {
      return """Youth Engagement Strategy:

👥 Key Youth Issues:
1. Education & Employment: NEET concerns, tech jobs, skill development.
2. Digital Governance: Online service accessibility, startup support.
3. Infrastructure: Affordable housing, transportation.

Engagement Tactics:
📱 Digital First Approach: Active social media, live Q&A sessions.
🎓 Education Focus: College campus visits, student council interactions.
💼 Employment Initiatives: Job fairs, skill workshops.

Would you like specific content for youth-focused campaigns?

--- (தமிழ்) ---

இளைஞர்களைக் கவரும் உத்திகள்:

👥 இளைஞர்களின் முக்கிய பிரச்சினைகள்:
1. கல்வி மற்றும் வேலைவாய்ப்பு: நீட் தேர்வு கவலைகள், தொழில்நுட்ப வேலைகள், திறன் மேம்பாடு.
2. டிஜிட்டல் ஆளுமை: ஆன்லைன் சேவை அணுகல், ஸ்டார்ட்அப் ஆதரவு.
3. உள்கட்டமைப்பு: குறைந்த விலை வீடுகள், போக்குவரத்து.

செயல்பாட்டு உத்திகள்:
📱 டிஜிட்டல் அணுகுமுறை: தீவிர சமூக ஊடக இருப்பு, நேரடி கேள்வி-பதில் அமர்வுகள்.
🎓 கல்வியில் கவனம்: கல்லூரி வளாக வருகைகள், மாணவர் மன்ற கலந்துரையாடல்கள்.
💼 வேலைவாய்ப்பு முயற்சிகள்: வேலைவாய்ப்பு முகாம்கள், திறன் பட்டறைகள்.

இளைஞர்களை மையமாகக் கொண்ட பிரச்சாரங்களுக்கு குறிப்பிட்ட உள்ளடக்கங்கள் வேண்டுமா?""";
    }

    if (message.contains('healthcare') || message.contains('health policy') || message.contains('medical')) {
      return """Healthcare Policy Talking Points:

🏥 Priorities:
1. Accessibility: 24/7 primary health centers, mobile medical units, telemedicine.
2. Infrastructure: New hospitals, equipment upgrades.
3. Preventive Care: Health checkup camps, vaccination drives.

Success Stories:
✅ 15 new primary health centers opened this year.
✅ 40% increase in doctor-to-patient ratio.
✅ Maternal mortality reduced by 25%.

Ready to discuss specific healthcare challenges?

--- (தமிழ்) ---

சுகாதாரக் கொள்கைக்கான முக்கிய அம்சங்கள்:

🏥 முன்னுரிமைகள்:
1. அணுகல்: 24/7 ஆரம்ப சுகாதார நிலையங்கள், கிராமப்புறங்களுக்கு நடமாடும் மருத்துவப் பிரிவுகள், டெலிமெடிசின்.
2. உள்கட்டமைப்பு: புதிய மருத்துவமனைகள், உபகரணங்களை மேம்படுத்துதல்.
3. தடுப்புப் பாதுகாப்பு: சுகாதாரப் பரிசோதனை முகாம்கள், தடுப்பூசி இயக்கங்கள்.

வெற்றிக் கதைகள்:
✅ இந்த ஆண்டு 15 புதிய ஆரம்ப சுகாதார நிலையங்கள் திறக்கப்பட்டுள்ளன.
✅ மருத்துவர்-நோயாளி விகிதத்தில் 40% அதிகரிப்பு.
✅ தாய்வழி இறப்பு விகிதம் 25% குறைக்கப்பட்டது.

குறிப்பிட்ட சுகாதார சவால்களைப் பற்றி விவாதிக்கத் தயாரா?""";
    }

    if (message.contains('opposition') || message.contains('criticism') || message.contains('respond to')) {
      return """Handling Opposition Criticism:

🎯 Response Strategy Framework:
1. Acknowledge & Redirect: Understand the concern and shift focus to your actions and solutions.
2. Fact-Based Defense: Use clear data and evidence to support your position.
3. Positive Positioning: Highlight achievements and share your future vision.

Key Principle: Stay factual, avoid personal attacks, and show empathy for public concerns.

Need help with specific criticism scenarios?

--- (தமிழ்) ---

எதிர்க்கட்சி விமர்சனங்களைக் கையாளுதல்:

🎯 பதில் அளிக்கும் வியூகம்:
1. ஏற்றுக்கொண்டு திசை திருப்புங்கள்: கவலையைப் புரிந்துகொண்டு, உங்கள் செயல்கள் மற்றும் தீர்வுகளுக்கு கவனத்தை மாற்றுங்கள்.
2. உண்மை அடிப்படையிலான பாதுகாப்பு: உங்கள் நிலையை ஆதரிக்க தெளிவான தரவு மற்றும் ஆதாரங்களைப் பயன்படுத்தவும்.
3. நேர்மறையான நிலைப்பாடு: சாதனைகளை முன்னிலைப்படுத்தி, உங்கள் எதிர்காலப் பார்வையைப் பகிர்ந்து கொள்ளுங்கள்.

முக்கிய கொள்கை: உண்மையாக இருங்கள், தனிப்பட்ட தாக்குதல்களைத் தவிர்க்கவும், பொது மக்களின் கவலைகளுக்கு பச்சாதாபம் காட்டுங்கள்.

குறிப்பிட்ட விமர்சனச் சூழ்நிலைகளுக்கு உதவி தேவையா?""";
    }

    if (message.contains('environment') || message.contains('pollution') || message.contains('green')) {
      return """Environmental Strategy & Talking Points:

🌱 Priorities:
1. Air Quality: Industrial emission monitoring, green belt development.
2. Water Conservation: Rainwater harvesting, river restoration.
3. Waste Management: Plastic ban enforcement, waste-to-energy projects.

Immediate Actions:
✅ ₹500 crore for air quality monitoring.
✅ 50 new sewage treatment plants.
✅ Solar panel subsidies for homes.

Want specific strategies for your constituency?

--- (தமிழ்) ---

சுற்றுச்சூழல் வியூகம் மற்றும் முக்கிய அம்சங்கள்:

🌱 முன்னுரிமைகள்:
1. காற்றின் தரம்: தொழில்துறை உமிழ்வைக் கண்காணித்தல், பசுமைப் பகுதிகளை உருவாக்குதல்.
2. நீர் பாதுகாப்பு: மழைநீர் சேகரிப்பு, நதி புனரமைப்பு.
3. கழிவு மேலாண்மை: பிளாஸ்டிக் தடை அமலாக்கம், கழிவிலிருந்து ஆற்றல் திட்டங்கள்.

உடனடி நடவடிக்கைகள்:
✅ காற்றின் தர கண்காணிப்புக்கு ₹500 கோடி.
✅ 50 புதிய கழிவுநீர் சுத்திகரிப்பு நிலையங்கள்.
✅ வீடுகளுக்கு சோலார் பேனல் மானியங்கள்.

உங்கள் தொகுதிக்கு குறிப்பிட்ட வியூகங்கள் வேண்டுமா?""";
    }

    // Default response
    return """I understand. I can help you with:

🏛️ Political Strategy & Communication
📊 Issues & Analytics
🗣️ Campaign Support

Please be more specific about what you need assistance with.

--- (தமிழ்) ---

நான் புரிந்துகொள்கிறேன். நான் உங்களுக்கு உதவக்கூடிய சில விஷயங்கள்:

🏛️ அரசியல் உத்தி மற்றும் தகவல் தொடர்பு
📊 பிரச்சனைகள் மற்றும் பகுப்பாய்வு
🗣️ பிரச்சார ஆதரவு

உங்களுக்கு எந்த বিষয়ে உதவி வேண்டும் என்று இன்னும் குறிப்பிட்டு கூற முடியுமா?""";
  }
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.blue,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'Klydra AI Assistant',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 1, 46, 117),
            fontSize: 25,
          ),
        ),
        // NEW: Language selection menu
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Colors.blue),
            onSelected: (String languageCode) {
              setState(() {
                selectedLanguage = languageCode;
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Language changed to ${languageCode == 'en-US' ? 'English' : 'Tamil'}'),
              ));
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'en-US',
                child: Text('English'),
              ),
              const PopupMenuItem<String>(
                value: 'ta-IN',
                child: Text('தமிழ் (Tamil)'),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildQuickAccessQuestions(),
              Expanded(child: _buildChatArea()),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessQuestions() {
    return Container(
      height: 130,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Quick Access Questions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: quickAccessQuestions.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _sendMessage(quickAccessQuestions[index]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.help_outline,
                          color: Color(0xFF3B82F6),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Text(
                            quickAccessQuestions[index],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: messages.length + (isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length && isTyping) {
            return _buildTypingIndicator();
          }
          
          final message = messages[index];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: message.isUser ? 
                      const Color(0xFF3B82F6) : Colors.white,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
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
                      Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: message.isUser ? Colors.white : const Color(0xFF1E293B),
                          height: 1.5,
                        ),
                      ),
                      if (!message.isUser) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _speakMessage(message.text),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSpeaking && currentSpeakingMessage == message.text ? 
                                    const Color(0xFFEF4444).withOpacity(0.1) : 
                                    const Color(0xFF3B82F6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSpeaking && currentSpeakingMessage == message.text ? 
                                        Icons.stop : Icons.volume_up,
                                      color: isSpeaking && currentSpeakingMessage == message.text ? 
                                        const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isSpeaking && currentSpeakingMessage == message.text ? 
                                        'Stop' : 'Listen',
                                      style: TextStyle(
                                        color: isSpeaking && currentSpeakingMessage == message.text ? 
                                          const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                selectedLanguage,
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 20,
                  child: AnimatedBuilder(
                    animation: _typingAnimation,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDot(0),
                          _buildDot(1),
                          _buildDot(2),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI is thinking...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final delay = index * 0.3;
    final animationValue = (_typingAnimation.value - delay).clamp(0.0, 1.0);
    final scale = math.sin(animationValue * math.pi);
    
    return Transform.scale(
      scale: 0.5 + (scale * 0.5),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF3B82F6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Ask me about political strategy, issues, or advice...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  hintStyle: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}