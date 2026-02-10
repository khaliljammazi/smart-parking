import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../model/parking_model.dart';
import '../parkinglist/parking_list_page.dart';
import '../location/map_page.dart';
import '../utils/constanst.dart';
import '../utils/text/regular.dart';
import '../utils/text/semi_bold.dart';
import '../utils/backend_api.dart';
import '../utils/favorites_provider.dart';
import 'favorites_page.dart';
import 'components/nearby_card.dart';
import 'components/nearby_shim_list.dart';
import 'components/parking_horizontal_card.dart';
import 'components/parking_horizontal_shim_list.dart';
import 'components/title_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String address = 'Tunis, Tunisie';
  double? lat;
  double? long;
  bool _locationLoading = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Hammamet coordinates: 36.4000, 10.6167
  // Tunis coordinates: 36.8065, 10.1815
  void _selectCity(String city) {
    setState(() {
      switch (city) {
        case 'Hammamet':
          lat = 36.4000;
          long = 10.6167;
          address = 'Hammamet, Tunisie';
          break;
        case 'Tunis':
          lat = 36.8065;
          long = 10.1815;
          address = 'Tunis, Tunisie';
          break;
        case 'Sousse':
          lat = 35.8256;
          long = 10.6411;
          address = 'Sousse, Tunisie';
          break;
        case 'Sfax':
          lat = 34.7406;
          long = 10.7603;
          address = 'Sfax, Tunisie';
          break;
        case 'Monastir':
          lat = 35.7777;
          long = 10.8264;
          address = 'Monastir, Tunisie';
          break;
        case 'Nabeul':
          lat = 36.4561;
          long = 10.7376;
          address = 'Nabeul, Tunisie';
          break;
        default:
          lat = 36.8065;
          long = 10.1815;
          address = 'Tunis, Tunisie';
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _locationLoading = true;
      _locationError = null;
    });

    // Skip location services on web platform - default to Hammamet
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          // Default to Hammamet for web users
          lat = 36.4000;
          long = 10.6167;
          address = 'Hammamet, Tunisie';
          _locationLoading = false;
        });
      }
      return;
    }

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied');
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services disabled');
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          String newAddress = '';
          if (place.locality != null && place.locality!.isNotEmpty) {
            newAddress = place.locality!;
          }
          if (place.country != null && place.country!.isNotEmpty) {
            newAddress += newAddress.isEmpty ? place.country! : ', ${place.country!}';
          }
          
          if (mounted) {
            setState(() {
              lat = position.latitude;
              long = position.longitude;
              address = newAddress.isEmpty ? 'Current Location' : newAddress;
              _locationLoading = false;
            });
          }
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Geocoding error: $e');
        }
        // Continue with coordinates even if geocoding fails
      }

      if (mounted) {
        setState(() {
          lat = position.latitude;
          long = position.longitude;
          address = 'Current Location';
          _locationLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Location error: $e');
      }
      
      // Fallback to default Tunis coordinates
      if (mounted) {
        setState(() {
          lat = 36.8065;
          long = 10.1815;
          address = 'Tunis, Tunisie';
          _locationError = e.toString().contains('denied') 
              ? 'Permission de localisation refusée'
              : 'Impossible d\'obtenir la position';
          _locationLoading = false;
        });
        
        // Show error message
        if (_locationError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_locationError!),
              action: SnackBarAction(
                label: 'Paramètres',
                onPressed: () async {
                  await openAppSettings();
                },
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.navyPale,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: <Widget>[
            // App Bar with Banner
            SliverAppBar(
              automaticallyImplyLeading: false,
              title: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: InkWell(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0, right: 8),
                          child: SvgPicture.asset(
                            'assets/icon/location.svg',
                            width: 26,
                            height: 26,
                          ),
                        ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RegularText(
                                text: 'Votre position',
                                fontSize: 12,
                                color: AppColor.navyPale,
                              ),
                              SemiBoldText(
                                maxLine: 1,
                                text: address,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        // City selector button
                        IconButton(
                          icon: const Icon(Icons.location_city, color: Colors.white),
                          tooltip: 'Changer de ville',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Sélectionner une ville'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.location_on),
                                      title: const Text('Hammamet'),
                                      onTap: () {
                                        _selectCity('Hammamet');
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.location_on),
                                      title: const Text('Tunis'),
                                      onTap: () {
                                        _selectCity('Tunis');
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.location_on),
                                      title: const Text('Sousse'),
                                      onTap: () {
                                        _selectCity('Sousse');
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.location_on),
                                      title: const Text('Sfax'),
                                      onTap: () {
                                        _selectCity('Sfax');
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.location_on),
                                      title: const Text('Monastir'),
                                      onTap: () {
                                        _selectCity('Monastir');
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.location_on),
                                      title: const Text('Nabeul'),
                                      onTap: () {
                                        _selectCity('Nabeul');
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MapPage()),
                      );
                    },
                  ),
                ),
              ),
              backgroundColor: AppColor.navy,
              pinned: true,
              expandedHeight: 280,
              flexibleSpace: FlexibleSpaceBar(
                background: Image.asset(
                  'assets/image/home_banner.png',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Nearby Parking Section
            const SliverToBoxAdapter(
              child: SizedBox(height: 12, width: double.infinity),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.only(left: 20.0, right: 16),
                      child: TitleList(
                        title: 'Près de chez vous',
                        page: ParkingListPage(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 340,
                      child: FutureBuilder<List<ParkingModel>>(
                        future: lat != null && long != null
                            ? BackendApi.getParkingSpots(lat!, long!, 5000)
                            : Future.value([]),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const NearByLoadingList();
                          } else if (snapshot.hasError) {
                            return const Center(child: Text('Error loading nearby parking'));
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No nearby parking found'));
                          } else {
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                final parking = snapshot.data![index];
                                return NearByCard(
                                  id: int.tryParse(parking.id) ?? 0,
                                  title: parking.name,
                                  imagePath: parking.imageUrl ?? 'https://via.placeholder.com/300x200',
                                  rating: parking.rating,
                                  carPrice: parking.pricePerHour,
                                  motoPrice: parking.pricePerHour * 0.6,
                                  address: parking.address,
                                  isPrepayment: true,
                                  isOvernight: false,
                                  distance: 1.5,
                                );
                              },
                              itemCount: snapshot.data!.length,
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Featured Parking Section
            const SliverToBoxAdapter(
              child: SizedBox(height: 12, width: double.infinity),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.only(left: 20.0, right: 16),
                      child: TitleList(
                        title: '♥ Lieux favoris',
                        page: FavoritesPage(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: FutureBuilder<List<ParkingModel>>(
                        future: BackendApi.getAllParkingSpots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const ParkinkCardHomeLoadingList();
                          } else if (snapshot.hasError) {
                            return const Center(child: Text('Error loading featured parking'));
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No featured parking found'));
                          } else {
                            return Consumer<FavoritesProvider>(
                              builder: (context, favoritesProvider, child) {
                                return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index) {
                                    final parking = snapshot.data![index];
                                    final isFavorite = favoritesProvider.isFavorite(parking.id);
                                    return ParkingCardHome(
                                      title: parking.name,
                                      imagePath: parking.imageUrl ?? 'https://via.placeholder.com/300x200',
                                      rating: parking.rating,
                                      motoPrice: parking.pricePerHour * 0.6,
                                      carPrice: parking.pricePerHour,
                                      address: parking.address,
                                      isFavorite: isFavorite,
                                      parkingId: parking.id, // Changed from id to parkingId
                                    );
                                  },
                                  itemCount: snapshot.data!.length > 4 ? 4 : snapshot.data!.length,
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      // Trigger rebuild to refresh FutureBuilders
    });
  }
}