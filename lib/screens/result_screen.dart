import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/test_result.dart';
import '../widgets/score_gauge.dart';
import '../widgets/drawing_comparison.dart';
import '../widgets/metrics_card.dart';

class ResultScreen extends StatelessWidget {
  final TestResult result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('검사 결과'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Test date
              Text(
                DateFormat('yyyy년 MM월 dd일 HH:mm').format(result.timestamp),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Overall Score
              _OverallScoreCard(result: result),
              const SizedBox(height: 24),

              // Result Category with Gauge
              _ResultCategoryCard(result: result),
              const SizedBox(height: 24),

              // Drawing Comparison
              const Text(
                '그림 비교',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              DrawingComparison(result: result),
              const SizedBox(height: 24),

              // Detailed Metrics
              const Text(
                '세부항목 수치 계산',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              MetricsCard(metrics: result.metrics),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Share functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('공유 기능 준비 중입니다')),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('결과 공유'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF4A90E2)),
                        foregroundColor: const Color(0xFF4A90E2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('홈으로'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverallScoreCard extends StatelessWidget {
  final TestResult result;

  const _OverallScoreCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4A90E2),
            const Color(0xFF357ABD),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90E2).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '종합 점수',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${result.overallScore.toStringAsFixed(0)}점',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              result.resultCategory,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCategoryCard extends StatelessWidget {
  final TestResult result;

  const _ResultCategoryCard({required this.result});

  Color _getCategoryColor(String category) {
    switch (category) {
      case '매우 좋음':
        return Colors.green;
      case '좋음':
        return Colors.lightGreen;
      case '보통':
        return Colors.orange;
      case '주의 필요':
        return Colors.deepOrange;
      case '병원 방문 권장':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryDescription(String category) {
    switch (category) {
      case '매우 좋음':
        return '떨림이 거의 없으며 매우 안정적입니다.';
      case '좋음':
        return '떨림이 적고 안정적인 편입니다.';
      case '보통':
        return '일반적인 수준의 떨림입니다.';
      case '주의 필요':
        return '떨림이 다소 있습니다. 지속적인 관찰이 필요합니다.';
      case '병원 방문 권장':
        return '떨림이 심합니다. 전문의 상담을 권장합니다.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(result.resultCategory);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.assessment,
                  color: categoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '검사 결과',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      result.resultCategory,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getCategoryDescription(result.resultCategory),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Score Gauge
          ScoreGauge(score: result.overallScore),
        ],
      ),
    );
  }
}
