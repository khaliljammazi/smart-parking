class ParkingSpot {
  final String id;
  final String name;
  final String address;
  final double pricePerHour;
  final int availableSpots;
  final double rating;
  final double latitude;
  final double longitude;

  ParkingSpot({
    required this.id,
    required this.name,
    required this.address,
    required this.pricePerHour,
    required this.availableSpots,
    required this.rating,
    required this.latitude,
    required this.longitude,
  });
}

// Mock data
List<ParkingSpot> mockParkingSpots = [
  ParkingSpot(
    id: '1',
    name: 'Parking Centre Ville',
    address: '123 Avenue Habib Bourguiba, Tunis',
    pricePerHour: 3.0,
    availableSpots: 15,
    rating: 4.5,
    latitude: 36.8065,
    longitude: 10.1815,
  ),
  ParkingSpot(
    id: '2',
    name: 'Parking Mall',
    address: '456 Rue de Carthage, Sousse',
    pricePerHour: 2.5,
    availableSpots: 8,
    rating: 4.2,
    latitude: 35.8256,
    longitude: 10.6369,
  ),
  ParkingSpot(
    id: '3',
    name: 'Parking Aéroport',
    address: '789 Route de l\'Aéroport, Tunis-Carthage',
    pricePerHour: 5.0,
    availableSpots: 25,
    rating: 4.8,
    latitude: 36.8510,
    longitude: 10.2272,
  ),
];