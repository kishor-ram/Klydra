// enhanced_opinion_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EnhancedOpinionChart extends StatefulWidget {
  const EnhancedOpinionChart({Key? key}) : super(key: key);

  @override
  State<EnhancedOpinionChart> createState() => _EnhancedOpinionChartState();
}

class _EnhancedOpinionChartState extends State<EnhancedOpinionChart>
    with TickerProviderStateMixin {
  int touchedIndex = -1;
  late AnimationController _animationController;
  late AnimationController _pointerController;
  late Animation<double> _slideAnimation;
  late Animation<double> _pointerAnimation;
  late Animation<double> _positionAnimation;
late Animation<double> _opacityAnimation;

  
  final List<OpinionData> opinionData = [
    OpinionData('Positive', 50, const Color(0xFF34D399)),
    OpinionData('Neutral', 30, const Color(0xFF60A5FA)),
    OpinionData('Negative', 20, const Color(0xFFFBBF24)),
  ];

@override
void initState() {
  super.initState();
  _animationController = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  );
  _pointerController = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  );

  // Slide-in main chart animation
  _slideAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOut,
  ));

  // ✅ Separate animations
  _positionAnimation = CurvedAnimation(
    parent: _pointerController,
    curve: Curves.elasticOut, // bounce for position
  );

  _opacityAnimation = CurvedAnimation(
    parent: _pointerController,
    curve: Curves.easeOut, // safe fade
  );

  _animationController.forward();
}

  @override
  void dispose() {
    _animationController.dispose();
    _pointerController.dispose();
    super.dispose();
  }

  Widget _buildOpinionChart() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: FadeTransition(
        opacity: _slideAnimation,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildChartWithLegend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Public Opinion Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              DateTime.now().toString().substring(0, 10),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF34D399)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '+5.2%',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartWithLegend() {
    return Row(
      children: [
        // Pie Chart
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          final touchedIdx = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                          if (touchedIndex != touchedIdx) {
                            touchedIndex = touchedIdx;
                            _pointerController.forward().then((_) {
                              Future.delayed(const Duration(milliseconds: 2000), () {
                                if (mounted) {
                                  _pointerController.reverse();
                                }
                              });
                            });
                          }
                        });
                      },
                    ),
                    sectionsSpace: 4,
                    centerSpaceRadius: 45,
                    borderData: FlBorderData(show: false),
                    sections: _buildChartSections(),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 800),
                  swapAnimationCurve: Curves.easeOut,
                ),
              ),
              if (touchedIndex != -1) _buildPointer(),
            ],
          ),
        ),
        const SizedBox(width: 30),
        // Legend
        Expanded(
          flex: 2,
          child: _buildLegend(),
        ),
      ],
    );
  }
Widget _buildPointer() {
  if (touchedIndex == -1) return const SizedBox.shrink();

  final data = opinionData[touchedIndex];

  return AnimatedBuilder(
    animation: Listenable.merge([_positionAnimation, _opacityAnimation]),
    builder: (context, child) {
      return Positioned(
        right: 20,
        top: 80 + (touchedIndex * 30.0) * _positionAnimation.value, // bounce
        child: Opacity(
          opacity: _opacityAnimation.value, // ✅ safe 0–1
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: data.color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${data.title}: ${data.value.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}


  double _calculateAngle(int index) {
    double totalValue = opinionData.fold(0, (sum, item) => sum + item.value);
    double currentSum = 0;
    for (int i = 0; i < index; i++) {
      currentSum += opinionData[i].value;
    }
    return (currentSum + opinionData[index].value / 2) / totalValue * 360;
  }

  List<PieChartSectionData> _buildChartSections() {
    return opinionData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == touchedIndex;
      final radius = isTouched ? 70.0 : 60.0;
      
      return PieChartSectionData(
        value: data.value,
        title: '${data.value.toInt()}%',
        radius: radius,
        color: data.color,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isTouched ? _buildBadge(data) : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  Widget _buildBadge(OpinionData data) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: data.color, width: 2),
      ),
      child: Text(
        data.title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: data.color,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        ...opinionData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final isSelected = index == touchedIndex;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? data.color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? data.color : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 16 : 12,
                  height: isSelected ? 16 : 12,
                  decoration: BoxDecoration(
                    color: data.color,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: data.color.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: TextStyle(
                          fontSize: isSelected ? 14 : 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${data.value.toInt()}% of responses',
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.trending_up,
                    color: data.color,
                    size: 16,
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildOpinionChart();
  }
}

class OpinionData {
  final String title;
  final double value;
  final Color color;

  OpinionData(this.title, this.value, this.color);
}

// Usage example:
// Widget build(BuildContext context) {
//   return Scaffold(
//     body: const Center(
//       child: EnhancedOpinionChart(),
//     ),
//   );
// }