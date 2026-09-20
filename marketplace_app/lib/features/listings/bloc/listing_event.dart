import 'package:equatable/equatable.dart';

sealed class ListingEvent extends Equatable {
  const ListingEvent();

  @override
  List<Object?> get props => [];
}

final class ListingsRequested extends ListingEvent {
  const ListingsRequested();
}