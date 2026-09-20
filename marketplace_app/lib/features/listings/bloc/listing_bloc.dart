import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/listing_repository.dart';
import 'listing_event.dart';
import 'listing_state.dart';

class ListingBloc extends Bloc<ListingEvent, ListingState> {
  final ListingRepository listingRepository;

  ListingBloc({
    required this.listingRepository,
  }) : super(const ListingInitial()) {
    on<ListingsRequested>(_onListingsRequested);
  }

  Future<void> _onListingsRequested(
    ListingsRequested event,
    Emitter<ListingState> emit,
  ) async {
    emit(const ListingLoading());

    try {
      final listings = await listingRepository.getListings();

      emit(ListingLoaded(listings));
    } catch (_) {
      emit(
        const ListingFailure(
          'Unable to load listings.',
        ),
      );
    }
  }
}