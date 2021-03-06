import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kalpaniksaathi/models/user.dart';
import 'package:kalpaniksaathi/pages/podcast/listen_page.dart';
import 'package:kalpaniksaathi/pages/wrapper.dart';
import 'package:kalpaniksaathi/services/auth.dart';
import 'package:kalpaniksaathi/theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  //forcing the app to run in portrait mode
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());

  WidgetsBinding.instance?.addObserver(const ListenPage());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<MyUser?>.value(
      catchError: (_, __) => null,
      initialData: null,
      value: AuthService().user,
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Kalpanik Saathi',
          themeMode: ThemeMode.system,
          theme: light,
          darkTheme: dark,
          home: AnimatedSplashScreen(
              duration: 3000,
              splash: 'assets/img/ic_launcher.png',
              nextScreen: const Wrapper(),
              splashTransition: SplashTransition.slideTransition,
              backgroundColor: Colors.white)),
    );
  }
}
