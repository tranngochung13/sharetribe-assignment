import 'package:equatable/equatable.dart';

import '../data/listing.dart';

sealed class ListingState extends Equatable {
  const ListingState();

  @override
  List<Object?> get props => [];
}

final class ListingInitial extends ListingState {
  const ListingInitial();
}

final class ListingLoading extends ListingState {
  const ListingLoading();
}

final class ListingLoaded extends ListingState {
  final List<Listing> listings;

  const ListingLoaded(this.listings);

  @override
  List<Object?> get props => [listings];
}

final class ListingFailure extends ListingState {
  final String message;

  const ListingFailure(this.message);

  @override
  List<Object?> get props => [message];
}