import 'package:flutter/material.dart';
import '../models/test_result.dart';

class MetricsCard extends StatelessWidget {
  final TremorMetrics metrics;

  const MetricsCard({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _MetricItem(
            icon: Icons.graphic_eq,
            title: '떨림의 주파수',
            value: '${metrics.frequency.toStringAsFixed(2)} Hz',
            description: '떨림이 발생하는 빈도',
            color: Colors.blue,
          ),
          const Divider(height: 32),
          _MetricItem(
            icon: Icons.waves,
            title: '떨림의 세기',
            value: metrics.amplitude.toStringAsFixed(2),
            description: '떨림의 진폭 크기',
            color: Colors.purple,
          ),
          if (metrics.deviationFromBaseline > 0) ...[
            const Divider(height: 32),
            _MetricItem(
              icon: Icons.straighten,
              title: '목표선에서 벗어난 거리',
              value: '${metrics.deviationFromBaseline.toStringAsFixed(2)} px',
              description: '기준선으로부터의 평균 거리',
              color: Colors.orange,
            ),
          ],
          const Divider(height: 32),
          _MetricItem(
            icon: Icons.timer,
            title: '검사 수행 시간',
            value: '${metrics.testDuration.toStringAsFixed(1)} 초',
            description: '검사를 완료한 시간',
            color: Colors.teal,
          ),
          const Divider(height: 32),
          _MetricItem(
            icon: Icons.speed,
            title: '검사 평균 속도',
            value: '${metrics.averageSpeed.toStringAsFixed(2)} px/s',
            description: '그리기 속도',
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String description;
  final Color color;

  const _MetricItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
