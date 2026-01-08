import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../model/parking_model.dart';
import '../parkinglist/parking_list_page.dart';
import '../utils/constanst.dart';
import '../utils/text/regular.dart';
import '../utils/text/semi_bold.dart';
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
  bool isLoadingNearby = false;
  bool isLoadingFeatured = false;

  @override
  void initState() {
    super.initState();
    // Simulate loading
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isLoadingNearby = true;
        isLoadingFeatured = true;
      });
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
                      // Navigate to location page (for now just show snackbar)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Navigation vers la page de localisation'),
                        ),
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
                    isLoadingNearby
                        ? SizedBox(
                            height: 340,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(left: 12),
                              itemBuilder: (context, index) {
                                final parking = mockParkingSpots[index % mockParkingSpots.length];
                                return NearByCard(
                                  id: parking.id,
                                  title: parking.name,
                                  imagePath: parking.imageUrl,
                                  rating: parking.rating,
                                  carPrice: parking.carPrice,
                                  motoPrice: parking.motoPrice,
                                  address: parking.address,
                                  isPrepayment: parking.isPrepayment,
                                  isOvernight: parking.isOvernight,
                                  distance: parking.distance,
                                );
                              },
                              itemCount: mockParkingSpots.length,
                            ),
                          )
                        : const NearByLoadingList(),
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
                    isLoadingFeatured
                        ? ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final parking = mockParkingSpots[(index + 2) % mockParkingSpots.length];
                              return ParkingCardHome(
                                title: parking.name,
                                imagePath: parking.imageUrl,
                                rating: parking.rating,
                                motoPrice: parking.motoPrice,
                                carPrice: parking.carPrice,
                                address: parking.address,
                                isFavorite: index % 2 == 0,
                                id: parking.id,
                              );
                            },
                            itemCount: 4,
                          )
                        : const ParkinkCardHomeLoadingList(),
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
      isLoadingNearby = false;
      isLoadingFeatured = false;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isLoadingNearby = true;
      isLoadingFeatured = true;
    });
  }
}