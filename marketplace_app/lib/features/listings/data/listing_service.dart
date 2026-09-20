import '../../../core/api/api_client.dart';
import 'listing.dart';

class ListingService {
  final ApiClient apiClient;

  ListingService({
    required this.apiClient,
  });

  Future<List<Listing>> getListings() async {
    final response = await apiClient.dio.get(
      '/v1/api/listings/query',
    );

    final data = response.data['data'] as List<dynamic>? ?? [];

    return data
        .map(
          (item) => Listing.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}