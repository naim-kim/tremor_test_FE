import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_client.dart';

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
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('모든 기록 보기'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadResults,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  )
                : _results.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text('저장된 기록이 없습니다.'),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, index) {
                          final r = _results[index];
                          final type = (r['testType'] as String?) ?? '';
                          final isSpiral =
                              type.toLowerCase() == 'spiral';
                          final performedAtStr =
                              r['performedAt'] as String?;
                          DateTime? performedAt;
                          if (performedAtStr != null) {
                            try {
                              performedAt = DateTime.parse(performedAtStr);
                            } catch (_) {}
                          }
                          final score = r['overallScore'] as num?;
                          final category = r['resultCategory'] as String?;

                          return ListTile(
                            leading: Icon(
                              isSpiral
                                  ? Icons.refresh
                                  : Icons.pentagon_outlined,
                              color:
                                  isSpiral ? const Color(0xFF4A90E2) : const Color(0xFF9B59B6),
                            ),
                            title: Text(
                              isSpiral ? '나선 그리기 검사' : '오각형 따라 그리기 검사',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (performedAt != null)
                                  Text(dateFormat.format(performedAt)),
                                if (score != null)
                                  Text('점수: ${score.toStringAsFixed(1)}'),
                                if (category != null && category.isNotEmpty)
                                  Text('결과: $category'),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}


