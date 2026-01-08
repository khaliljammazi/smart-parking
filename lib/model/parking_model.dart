class ParkingSpot {
  final int id;
  final String name;
  final String address;
  final double pricePerHour;
  final int availableSpots;
  final double rating;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final double? carPrice;
  final double? motoPrice;
  final bool isPrepayment;
  final bool isOvernight;
  final double distance;

  ParkingSpot({
    required this.id,
    required this.name,
    required this.address,
    required this.pricePerHour,
    required this.availableSpots,
    required this.rating,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.carPrice,
    this.motoPrice,
    required this.isPrepayment,
    required this.isOvernight,
    required this.distance,
  });
}

// Mock data
List<ParkingSpot> mockParkingSpots = [
  ParkingSpot(
    id: 1,
    name: 'Centre Ville Tunis',
    address: '123 Avenue Habib Bourguiba, Tunis',
    pricePerHour: 3.0,
    availableSpots: 15,
    rating: 4.5,
    latitude: 36.8065,
    longitude: 10.1815,
    imageUrl: null,
    carPrice: 3.0,
    motoPrice: 1.5,
    isPrepayment: true,
    isOvernight: false,
    distance: 0.8,
  ),
  ParkingSpot(
    id: 2,
    name: 'Mall Sousse',
    address: '456 Rue de Carthage, Sousse',
    pricePerHour: 2.5,
    availableSpots: 8,
    rating: 4.2,
    latitude: 35.8256,
    longitude: 10.6369,
    imageUrl: null,
    carPrice: 2.5,
    motoPrice: 1.0,
    isPrepayment: false,
    isOvernight: true,
    distance: 1.2,
  ),
  ParkingSpot(
    id: 3,
    name: 'Aéroport Tunis-Carthage',
    address: '789 Route de l\'Aéroport, Tunis-Carthage',
    pricePerHour: 5.0,
    availableSpots: 25,
    rating: 4.8,
    latitude: 36.8516,
    longitude: 10.2272,
    imageUrl: null,
    carPrice: 5.0,
    motoPrice: 2.5,
    isPrepayment: true,
    isOvernight: true,
    distance: 2.1,
  ),
];