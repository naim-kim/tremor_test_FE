import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';

String _compactCategory(String value) {
  final head = value.split(':').first.trim();
  return head.isEmpty ? value : head;
}

class AllResultsScreen extends StatefulWidget {
  const AllResultsScreen({super.key});

  @override
  State<AllResultsScreen> createState() => _AllResultsScreenState();
}

class _AllResultsScreenState extends State<AllResultsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiClient = Provider.of<ApiClient>(context, listen: false);
      final userId = userProvider.userId;
      if (userId == null) {
        setState(() {
          _error = '먼저 회원가입/로그인을 해주세요.';
          _isLoading = false;
        });
        return;
      }
      final results = await apiClient.getUserTests(userId: userId);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '기록을 불러오지 못했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withOpacity(0.08),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 15, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '모든 기록',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A18),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _loadResults,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withOpacity(0.08),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(Icons.refresh_rounded,
                          size: 17, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.teal800,
                        strokeWidth: 2,
                      ),
                    )
                  : _error != null
                      ? _buildError()
                      : _results.isEmpty
                          ? _buildEmpty()
                          : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 36, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _loadResults,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal800,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 36, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            '저장된 기록이 없습니다',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '검사를 진행하면 이곳에 기록이 표시됩니다',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
    return RefreshIndicator(
      onRefresh: _loadResults,
      color: AppColors.teal800,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final r = _results[index];
          final type = (r['testType'] as String?) ?? '';
          final isSpiral = type.toLowerCase() == 'spiral';
          final performedAtStr = r['performedAt'] as String?;
          DateTime? performedAt;
          if (performedAtStr != null) {
            try {
              performedAt = DateTime.parse(performedAtStr);
            } catch (_) {}
          }
          final score = r['overallScore'] as num?;
          final category = r['resultCategory'] as String?;

          return _ResultCard(
            isSpiral: isSpiral,
            performedAt: performedAt,
            dateFormat: dateFormat,
            score: score,
            category: category,
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final bool isSpiral;
  final DateTime? performedAt;
  final DateFormat dateFormat;
  final num? score;
  final String? category;

  const _ResultCard({
    required this.isSpiral,
    required this.performedAt,
    required this.dateFormat,
    required this.score,
    required this.category,
  });

  Color get _color => isSpiral ? AppColors.teal800 : AppColors.teal600;
  Color get _lightColor => const Color(0xFFE1F5EE);
  IconData get _icon =>
      isSpiral ? Icons.refresh_rounded : Icons.pentagon_outlined;
  String get _title => isSpiral ? '나선 그리기' : '오각형 그리기';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _lightColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A18),
                  ),
                ),
                if (performedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    dateFormat.format(performedAt!),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
          if (score != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${score!.toStringAsFixed(0)}점',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
                if (category != null && category!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _lightColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _compactCategory(category!),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
