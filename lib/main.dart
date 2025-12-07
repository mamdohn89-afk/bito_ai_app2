import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'IOSSubscriptionPage.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

// ----------------------------------------------------------------------
// ✅ تهيئة الإشعارات والدوال المساعدة
// ----------------------------------------------------------------------

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduledDate =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  return scheduledDate;
}

Future<void> initNotifications() async {
  tz_data.initializeTimeZones();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
  const InitializationSettings settings =
      InitializationSettings(android: androidSettings, iOS: iosSettings);

  await notificationsPlugin.initialize(settings);

  const AndroidNotificationDetails androidChannel = AndroidNotificationDetails(
    'bito_channel',
    'إشعارات Bito AI',
    channelDescription: 'إشعارات من منصة Bito AI للتعلم',
    importance: Importance.high,
    priority: Priority.high,
    enableVibration: true,
  );

  // إشعار ترحيبي بعد دقيقة
  await notificationsPlugin.zonedSchedule(
    100,
    '🎉 مرحباً بك في BitoAI!',
    'ابدأ تجربتك الآن واكتشف أدواتك الذكية.',
    tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1)),
    const NotificationDetails(android: androidChannel),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );

  // إشعارات يومية ثابتة
  await notificationsPlugin.zonedSchedule(
    0,
    'وقت المذاكرة 🎯',
    'ابدأ يومك بالمذاكرة مع BitoAI',
    _nextInstanceOfTime(10, 0),
    const NotificationDetails(android: androidChannel),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );

  await notificationsPlugin.zonedSchedule(
    1,
    'لا تراكمها 📚',
    'راجع دروسك قبل نهاية اليوم مع BitoAI',
    _nextInstanceOfTime(18, 0),
    const NotificationDetails(android: androidChannel),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'bito_channel',
    'إشعارات Bito AI',
    channelDescription: 'إشعارات من منصة Bito AI للتعلم',
    importance: Importance.high,
    priority: Priority.high,
    enableVibration: true,
  );

  const NotificationDetails details = NotificationDetails(android: androidDetails);
  await notificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    details,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  await initNotifications();
  print('✅ التطبيق بدأ بنجاح وتم تهيئة الإشعارات');
  runApp(const MyApp());
}

// ----------------------------------------------------------------------
// 🎯 MyApp + SplashScreen
// ----------------------------------------------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bito AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
          backgroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _navigateToHome();
  }

  void _initAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  void _navigateToHome() {
    Future.delayed(const Duration(seconds: 4), () {
      showNotification('مرحباً بك في BitoAI 👋', 'ابدأ رحلة التعلم الذكي معنا');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BitoAIApp()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 3,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Image.network(
                        'https://studybito.com/wp-content/uploads/2025/10/اساسي.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.school,
                          size: 80,
                          color: Colors.deepPurple.shade700,
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.deepPurple.shade700,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [
                            Colors.deepPurple.shade700,
                            Colors.purple.shade600,
                            Colors.blue.shade700,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: Text(
                        'BitoAI',
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Arial',
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    AnimatedContainer(
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      child: Text(
                        'ادرس بذكاء',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade700,
                          letterSpacing: 1,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 💡 الكلاس الرئيسي BitoAIApp
// ----------------------------------------------------------------------

class BitoAIApp extends StatefulWidget {
  const BitoAIApp({super.key});

  @override
  State<BitoAIApp> createState() => _BitoAIAppState();
}

class _BitoAIAppState extends State<BitoAIApp> {
  InAppWebViewController? _controller;
  bool isLoading = true;
  double progress = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
      Permission.mediaLibrary,
      Permission.manageExternalStorage,
      Permission.notification,
    ].request();
  }

  // ------------------------------------------------------------------
  // 🔹 فتح شات المساعد
  // ------------------------------------------------------------------
  void _openChatWidget() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatWidget(),
      ),
    );
  }

  void _closeMenuOnly() {
    Navigator.pop(context);
  }

  // ✅ دالة إغلاق القائمة والعودة لصفحة الدراسة
  void _closeMenuAndGoHome() {
    Navigator.pop(context);

    if (mounted && _controller != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _controller?.loadUrl(
          urlRequest: URLRequest(
            url: WebUri('https://studybito.com/study/'),
          ),
        );
        print('✅ تم إغلاق القائمة بنجاح وتم العودة لصفحة study/.');
      });
    }
  }

  // ✅ دالة فتح القائمة الجانبية المضمونة القفل
  void _openLockedCustomDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 🔒 قفل كامل
      builder: (context) {
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.75,
            height: double.infinity,
            margin: EdgeInsets.zero,
            child: Material(
              borderRadius: BorderRadius.zero,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // رأس القائمة
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple, Colors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.only(
                      top: 40,
                      bottom: 20,
                      left: 20,
                      right: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 30,
                                child: Icon(
                                  Icons.school,
                                  size: 30,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Bito AI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'منصة التعلم الذكي',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: _closeMenuAndGoHome,
                        ),
                      ],
                    ),
                  ),

                  ListTile(
                    leading: const Icon(Icons.home, color: Colors.deepPurple),
                    title: const Text('الرئيسية'),
                    onTap: () {
                      _controller?.loadUrl(
                        urlRequest: URLRequest(
                          url: WebUri('https://studybito.com/study/'),
                        ),
                      );
                      _closeMenuAndGoHome();
                    },
                  ),

                  // الإيميل
                  ListTile(
                    leading: const Icon(Icons.email, color: Colors.deepPurple),
                    title: FutureBuilder<SharedPreferences>(
                      future: SharedPreferences.getInstance(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final userEmail =
                              snapshot.data!.getString('user_email') ??
                                  'غير معروف';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('البريد الإلكتروني'),
                              Text(
                                userEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          );
                        }
                        return const Text('البريد الإلكتروني');
                      },
                    ),
                    onTap: () {
                      _copyEmailToClipboard();
                      _closeMenuAndGoHome();
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.info, color: Colors.deepPurple),
                    title: const Text('حول التطبيق'),
                    onTap: () {
                      _closeMenuAndGoHome();
                      showAboutDialog(
                        context: context,
                        applicationName: 'Bito AI',
                        applicationVersion: '1.0.4',
                        applicationIcon: const Icon(
                          Icons.school,
                          color: Colors.deepPurple,
                        ),
                      );
                    },
                  ),

                  ListTile(
                    leading:
                        const Icon(Icons.privacy_tip, color: Colors.deepPurple),
                    title: const Text('سياسة الخصوصية'),
                    onTap: () {
                      _controller?.loadUrl(
                        urlRequest: URLRequest(
                          url: WebUri(
                            'https://studybito.com/privacy-policy/',
                          ),
                        ),
                      );
                      _closeMenuOnly();
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.rule, color: Colors.deepPurple),
                    title: const Text('الشروط والأحكام'),
                    onTap: () {
                      _controller?.loadUrl(
                        urlRequest: URLRequest(
                          url: WebUri(
                            'https://studybito.com/terms-of-use/',
                          ),
                        ),
                      );
                      _closeMenuOnly();
                    },
                  ),

                  if (Platform.isIOS)
                    ListTile(
                      leading:
                          const Text("💎", style: TextStyle(fontSize: 20)),
                      title: const Text('الاشتراك في بيتو'),
                      onTap: () {
                        _closeMenuAndGoHome();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const IOSSubscriptionPage(),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // 🧩 التسجيل والتسجيل التلقائي
  // ------------------------------------------------------------------
  Future<void> _autoRegisterUser() async {
    if (_controller == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');

      if (savedToken != null && savedToken.isNotEmpty) {
        print('🔑 تم العثور على توكن محفوظ مسبقاً: $savedToken');

        final cookieManager = CookieManager.instance();
        await cookieManager.setCookie(
          url: WebUri('https://studybito.com'),
          name: 'bito_token',
          value: savedToken,
          domain: '.studybito.com',
          path: '/',
          isSecure: true,
        );

        await _controller?.evaluateJavascript(source: '''
          localStorage.setItem('bito_token', '$savedToken');
          sessionStorage.setItem('bito_token', '$savedToken');
          document.cookie = 'bito_token=$savedToken; path=/; max-age=86400';
        ''');

        await Future.delayed(const Duration(seconds: 2));
        _controller?.loadUrl(
          urlRequest: URLRequest(
            url: WebUri('https://studybito.com/study/'),
          ),
        );
        return;
      }

      bool? isFirstTime = prefs.getBool('is_first_time');
      if (isFirstTime == null || isFirstTime == true) {
        final username = 'user_${DateTime.now().millisecondsSinceEpoch}';
        final email = '$username@bitoapp.com';

        final response = await http.post(
          Uri.parse('https://studybito.com/?rest_route=/bito/v1/register'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({'username': username, 'email': email}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            await prefs.setBool('is_first_time', false);
            await prefs.setString('user_id', username);

            await Future.delayed(const Duration(seconds: 2));
            final loginResponse = await http.post(
              Uri.parse('https://studybito.com/wp-json/bito/v1/login'),
              body: {'username': username, 'password': '123456'},
            );

            if (loginResponse.statusCode == 200) {
              final loginData = jsonDecode(loginResponse.body);
              if (loginData['success'] == true) {
                await prefs.setString('auth_token', loginData['token']);
                await prefs.setString('user_email', email);
                print(
                    '🔐 تم التسجيل وتسجيل الدخول - Token: ${loginData['token']}');
                await showNotification(
                  'تم التسجيل والدخول ✅',
                  'أهلاً ${loginData['username']}',
                );

                final cookieManager = CookieManager.instance();
                await cookieManager.setCookie(
                  url: WebUri('https://studybito.com'),
                  name: 'bito_token',
                  value: loginData['token'],
                  domain: '.studybito.com',
                  path: '/',
                  isSecure: true,
                );

                await _controller?.evaluateJavascript(source: '''
                  localStorage.setItem('bito_token', '${loginData['token']}');
                  sessionStorage.setItem('bito_token', '${loginData['token']}');
                  document.cookie = 'bito_token=${loginData['token']}; path=/; max-age=86400';
                ''');

                await Future.delayed(const Duration(seconds: 2));

                _controller?.loadUrl(
                  urlRequest: URLRequest(
                    url: WebUri('https://studybito.com/study/'),
                  ),
                );
              }
            }
          }
        } else {
          print('❌ فشل في التسجيل: ${response.body}');
          await showNotification('خطأ ❌', 'حدثت مشكلة أثناء التسجيل');
        }
      } else {
        print('👤 المستخدم مسجل مسبقًا محليًا');
      }
    } catch (e) {
      print('❌ خطأ في الاتصال بالسيرفر: $e');
      await showNotification(
        'خطأ في الاتصال 🔌',
        'تحقق من الإنترنت وحاول مجددًا',
      );
    }
  }

  // ------------------------------------------------------------------
  // 🧱 واجهة التطبيق الرئيسية
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://studybito.com/study/'),
            ),
            onWebViewCreated: (controller) {
              _controller = controller;
              _setupBlobHandler();
              _setupFileHandler();

              _controller?.addJavaScriptHandler(
                handlerName: 'openIOSSubscriptionPage',
                callback: (args) async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IOSSubscriptionPage(),
                    ),
                  );
                },
              );

              // 🔐 تشغيل التسجيل التلقائي بعد جاهزية الويب فيو
              _autoRegisterUser();
            },
            onLoadStart: (controller, url) {
              setState(() {
                isLoading = true;
                progress = 0;
              });

              if (Platform.isIOS && url != null) {
                final lowerUrl = url.toString().toLowerCase();
                if (lowerUrl.contains('/price') ||
                    lowerUrl.contains('pricing')) {
                  controller.stopLoading();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IOSSubscriptionPage(),
                    ),
                  );
                  return;
                }
              }
            },
            onProgressChanged: (controller, progressValue) {
              setState(() {
                progress = progressValue / 100;
              });
            },
            onLoadStop: (controller, url) {
              setState(() {
                isLoading = false;
                progress = 1.0;
              });
            },
            onCreateWindow: (controller, createWindowRequest) async {
              return true;
            },
            onDownloadStartRequest:
                (controller, DownloadStartRequest downloadStartRequest) async {
              final url = downloadStartRequest.url.toString();
              final suggestedName =
                  downloadStartRequest.suggestedFilename ??
                      'file_${DateTime.now().millisecondsSinceEpoch}';

              if (url.startsWith('blob:')) {
                _extractBlobData(url, suggestedName);
              } else {
                await launchUrl(Uri.parse(url));
              }
            },
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              allowFileAccess: true,
              allowFileAccessFromFileURLs: true,
              allowUniversalAccessFromFileURLs: true,
              javaScriptCanOpenWindowsAutomatically: true,
              supportMultipleWindows: true,
              mediaPlaybackRequiresUserGesture: false,
              allowContentAccess: true,
              thirdPartyCookiesEnabled: true,
            ),
          ),
          if (isLoading)
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () async {
                if (_controller != null && await _controller!.canGoBack()) {
                  _controller!.goBack();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('لا توجد صفحة سابقة'),
                      backgroundColor: Colors.deepPurple,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white, size: 24),
              onPressed: () {
                _controller?.loadUrl(
                  urlRequest: URLRequest(
                    url: WebUri('https://studybito.com/study/'),
                  ),
                );
              },
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple,
                ),
                child: const Text(
                  '💬',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              onPressed: _openChatWidget,
            ),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 24),
              onPressed: _openLockedCustomDialog,
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // الدوال المساعدة (Download, Camera, Email, etc.)
  // ----------------------------------------------------------------------

  Future<void> _copyEmailToClipboard() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('user_email') ?? 'غير معروف';

    await Clipboard.setData(ClipboardData(text: userEmail));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ الإيميل: $userEmail'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _setupBlobHandler() {
    _controller?.addJavaScriptHandler(
      handlerName: 'onBlobDataExtracted',
      callback: (args) {
        if (args.isNotEmpty) {
          final data = args[0]['data'] as String;
          final fileName = args[0]['fileName'] as String;
          _saveBase64File(data, fileName);
        }
      },
    );
  }

  void _setupFileHandler() {
    _controller?.addJavaScriptHandler(
      handlerName: 'openCamera',
      callback: (args) async {
        final XFile? pickedFile = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 90,
        );

        if (pickedFile != null) {
          final file = File(pickedFile.path);
          final bytes = await file.readAsBytes();
          final base64Image = base64Encode(bytes);
          return {
            'success': true,
            'data': 'data:image/jpeg;base64,$base64Image',
            'fileName':
                'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
          };
        }
        return {'success': false};
      },
    );

    _controller?.addJavaScriptHandler(
      handlerName: 'openGallery',
      callback: (args) async {
        final XFile? pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
        );
        if (pickedFile != null) {
          final file = File(pickedFile.path);
          final bytes = await file.readAsBytes();
          final base64Image = base64Encode(bytes);
          return {
            'success': true,
            'data': 'data:image/jpeg;base64,$base64Image',
            'fileName': pickedFile.name,
          };
        }
        return {'success': false};
      },
    );
  }

  void _extractBlobData(String blobUrl, String fileName) async {
    try {
      await _controller?.evaluateJavascript(source: '''
        function getFileExtensionFromName(filename) {
          const match = filename.match(/\\.([a-zA-Z0-9]+)\$/);
          return match ? match[1] : 'bin';
        }
        (async () => {
          try {
            const blobResponse = await fetch('$blobUrl');
            const blob = await blobResponse.blob();

            let name = "$fileName";
            if (!name || name === "Unknown" || name.startsWith("file_")) {
              let ext = blob.type.split('/')[1] || getFileExtensionFromName(name) || 'bin';
              if (blob.type.includes("msword")) ext = "docx";
              if (blob.type.includes("pdf")) ext = "pdf";
              if (blob.type.includes("plain")) ext = "txt";
              name = "BitoAI_" + new Date().getTime() + "." + ext;
            }

            const reader = new FileReader();
            reader.onloadend = function() {
              const base64data = reader.result.split(',')[1];
              if (window.flutter_inappwebview && base64data) {
                window.flutter_inappwebview.callHandler('onBlobDataExtracted', {
                  data: base64data,
                  fileName: name,
                  mimeType: blob.type
                });
              }
            };
            reader.readAsDataURL(blob);
          } catch (err) {
            console.error("❌ Blob extraction error:", err);
          }
        })();
      ''');

      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('⏳ جاري معالجة الملف...'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('❌ Blob extraction failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء استخراج الملف: $e'),
        ),
      );
    }
  }

  Future<void> _saveBase64File(String base64Data, String fileName) async {
    try {
      final cleanData =
          base64Data.replaceFirst(RegExp(r'data:[^;]+;base64,'), '');
      final bytes = base64.decode(cleanData);
      final directory = Platform.isIOS
          ? await getApplicationDocumentsDirectory()
          : await getExternalStorageDirectory();

      final bitoDir = Directory('${directory?.path}/BitoAI');
      await bitoDir.create(recursive: true);

      final filePath = '${bitoDir.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(bytes);

      await OpenFilex.open(filePath);

      await showNotification('تم التحميل بنجاح ✅', 'تم تحميل $fileName بنجاح');

      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('تم تحميل $fileName بنجاح')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      print('تم حفظ الملف: $filePath');
    } catch (e) {
      print('Error saving file: $e');
      await showNotification('خطأ في التحميل ❌', 'حدث خطأ أثناء تحميل $fileName');
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل الملف: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// 💬 ChatWidget المبسط جداً
// ----------------------------------------------------------------------

class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    if (messages.isEmpty) {
      messages.add({
        "sender": "bot",
        "text": "مرحباً! أنا مساعد بيتو. كيف يمكنني مساعدتك اليوم؟",
        "time": "الآن",
      });
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('simple_chat_history');
    if (saved != null) {
      final loaded = List<Map<String, dynamic>>.from(jsonDecode(saved));
      setState(() => messages = loaded);
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('simple_chat_history', jsonEncode(messages));
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userMessage = {
      "sender": "user",
      "text": text,
      "time": "الآن",
    };

    setState(() {
      messages.add(userMessage);
      isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();
    await _saveHistory();

    // محاكاة رد الذكاء الاصطناعي
    Future.delayed(const Duration(seconds: 1), () async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? "";

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? "";
        final userEmail = prefs.getString('user_email') ?? "";
        final userId = prefs.getString('user_id') ?? "";

        final res = await http.post(
          Uri.parse("https://studybito.com/wp-json/bito/v1/chat"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "message": text,
            "token": token,
            "email": userEmail,   // يمكن استخدام الإيميل
            "user_id": userId,    // أو اليوزر نيم
          }),
        );


        final reply = jsonDecode(res.body)["reply"] ??
            "شكراً لسؤالك! كيف يمكنني مساعدتك أكثر؟";

        setState(() {
          messages.add({
            "sender": "bot",
            "text": reply,
            "time": "الآن",
          });
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          messages.add({
            "sender": "bot",
            "text": "⚠️ حدث خطأ في الاتصال. حاول مرة أخرى.",
            "time": "الآن",
          });
          isLoading = false;
        });
      }

      _scrollToBottom();
      await _saveHistory();
    });
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg["sender"] == "user";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              radius: 16,
              child: Icon(Icons.school, size: 18, color: Colors.white),
            ),

          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: isUser ? 40 : 8,
                right: isUser ? 8 : 40,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.deepPurple : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg["text"],
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg["time"] ?? "",
                    style: TextStyle(
                      color: isUser ? Colors.white70 : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isUser)
            const CircleAvatar(
              backgroundColor: Colors.grey,
              radius: 16,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "💬 مساعد بيتو",
          style: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () {
              setState(() => messages.clear());
              _saveHistory();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                             size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "ابدأ محادثة جديدة",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(messages[index]);
                    },
                  ),
          ),

          if (isLoading)
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    radius: 16,
                    child: Icon(Icons.school, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.deepPurple,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text("يكتب..."),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "اكتب رسالتك هنا...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => _controller.clear(),
                            )
                          : null,
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.deepPurple,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

