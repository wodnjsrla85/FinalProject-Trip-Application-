class Save {
  final String id; // Firestore 문서 ID
  final List<String> flights;
  final List<String> packages;

  Save({
    required this.id,
    required this.flights,
    required this.packages,
  });

  factory Save.fromMap(Map<String, dynamic> map, String docId) {
    return Save(
      id: docId,
      flights: List<String>.from(map['flights'] ?? []),
      packages: List<String>.from(map['packages'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'flights': flights,
      'packages': packages,
    };
  }
}
