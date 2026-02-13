import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import 'package:app_links/app_links.dart';

import 'services/mastodon_service.dart';
import 'services/bluesky_service.dart';
import 'services/nostr_service.dart';
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
        ChangeNotifierProvider(create: (_) => MastodonService()),
        ChangeNotifierProvider(create: (_) => BlueskyService()),
        ChangeNotifierProvider(create: (_) => NostrService()),
        ChangeNotifierProvider(create: (_) => XService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProxyProvider4<MastodonService, BlueskyService, NostrService, XService, PostingService>(
          create: (context) => PostingService(
            mastodonService: Provider.of<MastodonService>(context, listen: false),
            blueskyService: Provider.of<BlueskyService>(context, listen: false),
            nostrService: Provider.of<NostrService>(context, listen: false),
            xService: Provider.of<XService>(context, listen: false),
          ),
          update: (_, mastodon, bluesky, nostr, x, previous) =>
              previous!..update(mastodon, bluesky, nostr, x),
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
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      windowManager.addListener(this);
      _initSystemTray();
    }
    
    // Initialize deep link handling for Amber callbacks (Android only)
    if (Platform.isAndroid) {
      _initDeepLinks();
    }
  }

  @override
  void dispose() {
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    _linkSubscription?.cancel();
    super.dispose();
  }

  /// Initialize deep link listener for Amber callbacks
  void _initDeepLinks() async {
    _appLinks = AppLinks();
    
    try {
      // Handle initial deep link if app was launched by one
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }

      // Listen for deep links while app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          _handleDeepLink(uri);
        },
        onError: (err) {
          debugPrint('Deep link error: $err');
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize deep links: $e');
    }
  }

  /// Handle deep link callback (legacy - amberflutter now handles Amber internally)
  void _handleDeepLink(Uri uri) async {
    debugPrint('Received deep link: $uri');
    
    // Note: Amber integration now uses amberflutter package which handles
    // activity results internally. This deep link handler is kept for
    // potential future use or other deep link scenarios.
    
    debugPrint('Deep link received but not processed (amberflutter handles Amber)');
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
