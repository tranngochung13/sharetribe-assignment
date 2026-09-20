import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/storage/token_storage.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/auth_service.dart';

import 'core/api/api_client.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/listings/bloc/listing_bloc.dart';
import 'features/listings/data/listing_repository.dart';
import 'features/listings/data/listing_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}

Future<Widget> initializeApp() async {
  await dotenv.load(fileName: '.env');

  final tokenStorage = TokenStorage();
  final authService = AuthService();

  final authRepository = AuthRepository(
    authService: authService,
    tokenStorage: tokenStorage,
  );

  final apiClient = ApiClient(
    tokenStorage: tokenStorage,
    authService: authService,
  );

  final listingService = ListingService(apiClient: apiClient);

  final listingRepository = ListingRepository(listingService: listingService);

  return MyApp(
    authRepository: authRepository,
    listingRepository: listingRepository,
    sessionExpired: apiClient.sessionExpired,
  );
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key, this.initialize = initializeApp});

  final Future<Widget> Function() initialize;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late Future<Widget> _app;

  @override
  void initState() {
    super.initState();
    _app = Future.sync(widget.initialize);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _app,
      builder: (context, snapshot) {
        if (snapshot.hasData) return snapshot.data!;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Unable to start app. Check your .env configuration.',
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => setState(() {
                            _app = Future.sync(widget.initialize);
                          }),
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final ListingRepository listingRepository;
  final Stream<void>? sessionExpired;

  const MyApp({
    required this.authRepository,
    required this.listingRepository,
    this.sessionExpired,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(
            authRepository: authRepository,
            sessionExpired: sessionExpired,
          )..add(const AuthStatusChecked()),
        ),
        BlocProvider(
          create: (_) => ListingBloc(listingRepository: listingRepository),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sharetribe Marketplace',
        theme: ThemeData(useMaterial3: true),
        home: const AuthGate(),
      ),
    );
  }
}
