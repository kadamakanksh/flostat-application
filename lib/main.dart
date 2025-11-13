import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/org_provider.dart';
import 'providers/device_provider.dart';
import 'providers/user_provider.dart';
import 'providers/support_ticket_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrgProvider()),

        ChangeNotifierProxyProvider<AuthProvider, DeviceProvider>(
          create: (_) => DeviceProvider(authProvider: AuthProvider()),
          update: (_, auth, previous) =>
              previous!..updateAuthProvider(auth),
        ),

        ChangeNotifierProvider(create: (_) => UserProvider()),

        ChangeNotifierProxyProvider<AuthProvider, SupportTicketProvider>(
          create: (context) => SupportTicketProvider(authProvider: context.read<AuthProvider>()),
          update: (_, auth, previous) => previous ?? SupportTicketProvider(authProvider: auth),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Water Management App',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const SplashScreen(),
      ),
    );
  }
}
