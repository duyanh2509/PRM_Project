import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/customer_list_provider.dart';
import 'providers/history_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/login_screen.dart';

/// ============================================================================
/// MAIN - Entry Point của ứng dụng Water Meter App
/// ============================================================================
/// SETUP:
/// - Lock orientation: CHỈ PORTRAIT (không cho xoay ngang)
/// - Firebase initialization
/// - MultiProvider: Cung cấp 4 providers cho toàn app
///   + AuthProvider: Quản lý đăng nhập
///   + CustomerListProvider: Danh sách khách hàng
///   + HistoryProvider: Lịch sử ghi số/thu tiền
///   + SettingsProvider: Cài đặt & đồng bộ
/// - MaterialApp: Theme + màn hình đầu tiên (LoginScreen)
/// ============================================================================

/// Entry point của ứng dụng
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // *** LOCK ORIENTATION - CHỈ CHO PHÉP PORTRAIT ***
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

/// Root widget của ứng dụng
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CustomerListProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Water Meter App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
