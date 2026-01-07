import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

import 'services/microblog_service.dart';
import 'services/x_service.dart';
import 'services/posting_service.dart';
import 'services/theme_service.dart';
import 'views/compose_view.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Window Manager only on desktop
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(400, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      // Set the window/taskbar icon
      await windowManager.setIcon('assets/app_icon.png');
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MicroBlogService()),
        ChangeNotifierProvider(create: (_) => XService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProxyProvider2<MicroBlogService, XService, PostingService>(
          create: (context) => PostingService(
            microBlogService: Provider.of<MicroBlogService>(context, listen: false),
            xService: Provider.of<XService>(context, listen: false),
          ),
          update: (_, microBlog, x, previous) =>
              previous!..update(microBlog, x),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  final bool _isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      windowManager.addListener(this);
      _initSystemTray();
    }
  }

  @override
  void dispose() {
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
  }

  Future<void> _initSystemTray() async {
    if (!Platform.isLinux) return; // Only init tray on Linux for now as requested

    // Prevent app from closing when X is clicked, so we can hide it instead
    await windowManager.setPreventClose(true);

    String path = 'assets/app_icon.png'; 

    final AppWindow appWindow = AppWindow();
    final SystemTray systemTray = SystemTray();

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: 'Show', onClicked: (menuItem) => appWindow.show()),
      MenuItemLabel(label: 'Hide', onClicked: (menuItem) => appWindow.hide()),
      MenuItemLabel(label: 'Exit', onClicked: (menuItem) async {
        await windowManager.setPreventClose(false);
        await windowManager.close();
        exit(0);
      }),
    ]);

    await systemTray.initSystemTray(
      title: "SendIt",
      iconPath: path, 
    );
    
    await systemTray.setContextMenu(menu);

    systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        Platform.isWindows ? appWindow.show() : systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        Platform.isWindows ? systemTray.popUpContextMenu() : appWindow.show();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    return MaterialApp(
      title: 'SendIt',
      theme: AppTheme.getTheme(themeService.currentTheme),
      home: const ComposeView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
