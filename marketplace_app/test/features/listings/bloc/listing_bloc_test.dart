import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marketplace_app/features/listings/bloc/listing_bloc.dart';
import 'package:marketplace_app/features/listings/bloc/listing_event.dart';
import 'package:marketplace_app/features/listings/bloc/listing_state.dart';
import 'package:marketplace_app/features/listings/data/listing.dart';
import 'package:marketplace_app/features/listings/data/listing_repository.dart';

class MockListingRepository extends Mock implements ListingRepository {}

void main() {
  late MockListingRepository repository;
  setUp(() => repository = MockListingRepository());
  const listings = [
    Listing(id: '1', title: 'Bicycle', description: 'For rent'),
  ];
  blocTest<ListingBloc, ListingState>(
    'loads listings from repository',
    build: () {
      when(() => repository.getListings()).thenAnswer((_) async => listings);
      return ListingBloc(listingRepository: repository);
    },
    act: (bloc) => bloc.add(const ListingsRequested()),
    expect: () => [const ListingLoading(), const ListingLoaded(listings)],
  );
  blocTest<ListingBloc, ListingState>(
    'reports request failure',
    build: () {
      when(() => repository.getListings()).thenThrow(Exception('offline'));
      return ListingBloc(listingRepository: repository);
    },
    act: (bloc) => bloc.add(const ListingsRequested()),
    expect: () => [
      const ListingLoading(),
      const ListingFailure('Unable to load listings.'),
    ],
  );
}
