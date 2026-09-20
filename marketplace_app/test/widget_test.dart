import 'package:marketplace_app/features/listings/data/listing.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marketplace_app/main.dart';
import 'helpers/mock_auth_repository.dart';
import 'package:marketplace_app/features/listings/data/listing_repository.dart';

class MockListingRepository extends Mock implements ListingRepository {}

void main() {
  testWidgets('Startup shows loading and allows retry after failure', (
    tester,
  ) async {
    final pending = Completer<Widget>();
    var attempts = 0;
    await tester.pumpWidget(
      AppBootstrap(
        initialize: () {
          attempts++;
          return attempts == 1
              ? pending.future
              : Future.value(const MaterialApp(home: Text('Ready')));
        },
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(StateError('Missing configuration'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
  });

  for (final storageFails in [false, true]) {
    testWidgets('Shows login when storage fails: $storageFails', (
      tester,
    ) async {
      final auth = MockAuthRepository();
      when(() => auth.isAuthenticated()).thenAnswer((_) async {
        if (storageFails) throw StateError('Storage unavailable');
        return false;
      });
      await tester.pumpWidget(
        MyApp(authRepository: auth, listingRepository: MockListingRepository()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Email'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Saved session opens listings', (tester) async {
    final auth = MockAuthRepository();
    final listings = MockListingRepository();
    when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
    when(() => listings.getListings()).thenAnswer((_) async => []);
    await tester.pumpWidget(
      MyApp(authRepository: auth, listingRepository: listings),
    );
    await tester.pumpAndSettle();
    expect(find.text('Listings'), findsOneWidget);
    expect(find.text('No listings found.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Expired session returns to login', (tester) async {
    final expired = StreamController<void>.broadcast();
    final auth = MockAuthRepository();
    final listings = MockListingRepository();
    when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
    when(() => listings.getListings()).thenAnswer((_) async => []);
    await tester.pumpWidget(
      MyApp(
        authRepository: auth,
        listingRepository: listings,
        sessionExpired: expired.stream,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Listings'), findsOneWidget);
    expired.add(null);
    await tester.pumpAndSettle();
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Listings'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await expired.close();
  });
  testWidgets('Refresh waits for request and displays updated listings', (
    tester,
  ) async {
    final auth = MockAuthRepository();
    final listings = MockListingRepository();
    final refreshed = Completer<List<Listing>>();
    var calls = 0;
    when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
    when(() => listings.getListings()).thenAnswer((_) {
      calls++;
      return calls == 1
          ? Future.value([
              const Listing(id: '1', title: 'Old listing', description: ''),
            ])
          : refreshed.future;
    });
    await tester.pumpWidget(
      MyApp(authRepository: auth, listingRepository: listings),
    );
    await tester.pumpAndSettle();
    final indicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    var completed = false;
    final refresh = indicator.onRefresh().then((_) => completed = true);
    await tester.pump();
    expect(completed, isFalse);
    expect(find.text('Old listing'), findsOneWidget);
    refreshed.complete([
      const Listing(id: '2', title: 'New listing', description: ''),
    ]);
    await refresh;
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(find.text('New listing'), findsOneWidget);
  });
}
