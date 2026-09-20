class Listing {
  final String id;
  final String title;
  final String description;

  const Listing({
    required this.id,
    required this.title,
    required this.description,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    final attributes =
        json['attributes'] as Map<String, dynamic>? ?? {};

    return Listing(
      id: json['id'] as String,
      title: attributes['title'] as String? ?? '',
      description: attributes['description'] as String? ?? '',
    );
  }
}