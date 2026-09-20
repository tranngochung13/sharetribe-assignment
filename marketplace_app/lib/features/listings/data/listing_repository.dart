import 'listing.dart';
import 'listing_service.dart';

class ListingRepository {
  final ListingService listingService;

  ListingRepository({
    required this.listingService,
  });

  Future<List<Listing>> getListings() {
    return listingService.getListings();
  }
}