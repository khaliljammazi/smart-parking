import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../model/parking_model.dart';
import '../parkinglist/parking_list_page.dart';
import '../location/map_page.dart';
import '../utils/constanst.dart';
import '../utils/text/regular.dart';
import '../utils/text/semi_bold.dart';
import '../utils/backend_api.dart';
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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    // TODO: Get current location using geolocator
    // For now, use default Tunis coordinates
    setState(() {
      lat = 36.8065;
      long = 10.1815;
    });
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
                        )
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
                        title: 'Liste en vedette',
                        page: ParkingListPage(),
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
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                final parking = snapshot.data![index];
                                return ParkingCardHome(
                                  title: parking.name,
                                  imagePath: parking.imageUrl ?? 'https://via.placeholder.com/300x200',
                                  rating: parking.rating,
                                  motoPrice: parking.pricePerHour * 0.6,
                                  carPrice: parking.pricePerHour,
                                  address: parking.address,
                                  isFavorite: index % 2 == 0,
                                  id: int.tryParse(parking.id) ?? 0,
                                );
                              },
                              itemCount: snapshot.data!.length > 4 ? 4 : snapshot.data!.length,
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