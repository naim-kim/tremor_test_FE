import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'providers/user_provider.dart';
import 'providers/test_provider.dart';
import 'models/test_result.dart';
import 'config/api_config.dart';
import 'services/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file (hot-reload safe; failures are logged but not fatal)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
  }

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TestResultAdapter());
  Hive.registerAdapter(TestTypeAdapter());
  Hive.registerAdapter(DrawingPointAdapter());
  Hive.registerAdapter(TremorMetricsAdapter());
  await Hive.openBox<TestResult>('test_results');

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const TremorDetectionApp());
}

class TremorDetectionApp extends StatelessWidget {
  const TremorDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient(resolveBaseUrl())),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TestProvider()),
      ],
      child: MaterialApp(
        title: '떨림 검사',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF4A90E2),
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'NotoSansKR',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black87),
            titleTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'NotoSansKR',
            ),
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            headlineMedium: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: TextStyle(fontSize: 16),
            bodyMedium: TextStyle(fontSize: 14),
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
