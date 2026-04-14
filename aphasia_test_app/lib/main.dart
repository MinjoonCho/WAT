import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/main_menu.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
bool _isShowingErrorDialog = false;

void _showGlobalErrorDialog(String source, Object error, StackTrace stack) {
  if (_isShowingErrorDialog) return;

  final context = _rootNavigatorKey.currentContext;
  if (context == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGlobalErrorDialog(source, error, stack);
    });
    return;
  }

  _isShowingErrorDialog = true;
  final summary = error.toString();

  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      title: const Text('오류 발생'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$source에서 오류가 발생했습니다.'),
            const SizedBox(height: 12),
            SelectableText(
              summary,
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '같은 오류가 계속 나면 이 화면을 캡처해서 전달해주세요.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('닫기'),
        ),
      ],
    ),
  ).whenComplete(() {
    _isShowingErrorDialog = false;
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _showGlobalErrorDialog(
      'FlutterError',
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    _showGlobalErrorDialog('PlatformDispatcher', error, stack);
    return false;
  };

  ErrorWidget.builder = (details) {
    _showGlobalErrorDialog(
      'ErrorWidget',
      details.exception,
      details.stack ?? StackTrace.current,
    );
    return Material(
      color: const Color(0xFFFFEBEE),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '화면 오류가 발생했습니다.\n앱 문서 폴더의 wat_error_log.txt를 확인해주세요.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFD32F2F),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  };

  runApp(
    MaterialApp(
      navigatorKey: _rootNavigatorKey,
      title: 'Word Access Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9C27B0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      home: const MainMenu(),
    ),
  );
}
