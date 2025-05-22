import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/pages/VendorsPage.dart';
import 'package:fyp_namaste_events/pages/notification_page.dart';
import 'package:fyp_namaste_events/pages/vendor_detail_page.dart';
import 'package:fyp_namaste_events/utils/shared_preferences.dart';
import 'package:fyp_namaste_events/utils/theme/custom_themes/text_theme.dart';
import 'package:fyp_namaste_events/pages/login_register_page.dart';
import '../components/bottom_nav_bar.dart';
import '../services/Api/vendorService.dart';
import '../utils/costants/api_constants.dart';
import 'package:fyp_namaste_events/pages/vendor_list_page.dart';


class HomePage extends StatefulWidget {
  final String token;

  const HomePage({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late VendorService vendorService;
  List<dynamic> venues = [];
  List<dynamic> photographers = [];
  List<dynamic> decorations = [];
  bool isLoading = true;
  int _unreadNotificationCount = 0; // Add this to track unread notifications

  // Add featuredCategories list
  final List<Map<String, dynamic>> featuredCategories = [
    {
      'title': 'Venues\nfor Events',
      'image': 'assets/eventvenue.png',
      'type': 'venue'
    },
    {
      'title': 'Photography\nServices',
      'image': 'assets/photography.png',
      'type': 'photographer'
    },
    {
      'title': 'Decoration\nServices',
      'image': 'assets/decorartion.png',
      'type': 'decorator'
    },
    {'title': 'Catering\nServices', 'image': 'assets/food.png', 'type': 'food'},
  ];

  // Add search and filter states
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> filteredVenues = [];
  List<dynamic> filteredPhotographers = [];
  List<dynamic> filteredDecorations = [];
  String _selectedFilter = 'All'; // For category filtering

  @override

  void initState() {
    super.initState();
    vendorService = VendorService(APIConstants.baseUrl);
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final fetchedInventory = await vendorService.fetchAllInventory();
      if (fetchedInventory['success']) {
        setState(() {
          venues = fetchedInventory['data']['venues'];
          photographers = fetchedInventory['data']['photographers'];
          decorations = fetchedInventory['data']['decorators'];
          // Initialize filtered lists
          filteredVenues = venues;
          filteredPhotographers = photographers;
          filteredDecorations = decorations;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Failed to fetch data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Add search method
  void _searchVendors(String query) {
    setState(() {
      if (query.isEmpty && _selectedFilter == 'All') {
        filteredVenues = venues;
        filteredPhotographers = photographers;
        filteredDecorations = decorations;
      } else {
        // Venues filtering
        filteredVenues = venues
            .where((venue) =>
                venue['venueName']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                venue['address']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();

        // Photographers filtering
        filteredPhotographers = photographers
            .where((photographer) =>
                photographer['photographyName']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                photographer['address']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();

        // Decorations filtering
        filteredDecorations = decorations
            .where((decoration) =>
                decoration['decoratorName']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                decoration['address']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();

        // Apply category filter
        switch (_selectedFilter) {
          case 'Venues':
            filteredPhotographers = [];
            filteredDecorations = [];
            break;
          case 'Photographers':
            filteredVenues = [];
            filteredDecorations = [];
            break;
          case 'Decorators':
            filteredVenues = [];
            filteredPhotographers = [];
            break;
        }
      }
    });
  }

// In your logout function
void logout() async {
  // Set the logout flag
  await SharedPreferencesService.setWasLoggedOut(true);
  
  // Clear token and user data
  await SharedPreferencesService.clearAll();
  
  // Navigate to login page
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const LoginPage()),
    (route) => false, // This removes all previous routes
  );
}

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).brightness == Brightness.dark
        ? TTextTheme.darkTextTheme
        : TTextTheme.lightTextTheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Pokhara',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(width: 10),
            // Search field in AppBar
            Expanded(
              child: Container(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchVendors,
                  decoration: InputDecoration(
                    hintText: 'Search venues, photographers...',
                    hintStyle: TextStyle(fontSize: 14),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchVendors('');
                            },
                          )
                        : null,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ),
            ),
            // Add notification icon with badge
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // Navigate to notification page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationPage(),
                      ),
                    ).then((_) {
                      // Reset badge count after returning from notification page
                      setState(() {
                        _unreadNotificationCount = 0;
                      });
                    });
                  },
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadNotificationCount > 9 ? '9+' : _unreadNotificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/namaste eventslogo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add filter chips
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _selectedFilter == 'All',
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = 'All';
                                _searchVendors(_searchController.text);
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Venues'),
                            selected: _selectedFilter == 'Venues',
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = 'Venues';
                                _searchVendors(_searchController.text);
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Photographers'),
                            selected: _selectedFilter == 'Photographers',
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = 'Photographers';
                                _searchVendors(_searchController.text);
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('Decorators'),
                            selected: _selectedFilter == 'Decorators',
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = 'Decorators';
                                _searchVendors(_searchController.text);
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Featured Section continues...
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Featured', style: textTheme.headlineSmall),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VendorsPage(
                                  token: widget.token,
                                ),
                              ),
                            );
                          },
                          style: ButtonStyle(
                            overlayColor: MaterialStateProperty.all(
                              Colors.grey.withOpacity(0.1),
                            ),
                            padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Featured Categories
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: featuredCategories.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemBuilder: (context, index) {
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              if (featuredCategories[index]['type'] == 'food') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'No catering services available at the moment'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VendorListPage(
                                      vendors: featuredCategories[index]
                                                  ['type'] ==
                                              'venue'
                                          ? venues
                                          : featuredCategories[index]['type'] ==
                                                  'photographer'
                                              ? photographers
                                              : decorations,
                                      category: featuredCategories[index]
                                              ['title']
                                          .split('\n')[0],
                                      token: widget.token,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: AssetImage(
                                            featuredCategories[index]['image']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  featuredCategories[index]['title'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Venues in your city section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Venues in your city',
                            style: textTheme.headlineSmall),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VendorListPage(
                                  vendors: venues,
                                  category: 'Venue',
                                  token: widget.token,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Venues Horizontal List
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredVenues.length, // Use filtered list
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VendorDetailPage(
                                  vendorData: filteredVenues[
                                      index], // Use filtered list
                                  vendorType: 'venue',
                                  token: widget.token,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 180,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(10)),
                                      child: filteredVenues[index]['images'] !=
                                                  null && // Change this line
                                              filteredVenues[index]['images']
                                                  .isNotEmpty // Change this line
                                          ? Image.network(
                                              filteredVenues[index]['images'][
                                                          0] // Change this line
                                                      ['fullUrl'] ??
                                                  '',
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey.shade300,
                                                  child: const Icon(
                                                      Icons.image_not_supported,
                                                      size: 40),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: Colors.grey.shade300,
                                              child: const Icon(Icons.home,
                                                  size: 40),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          filteredVenues[index][
                                                  'venueName'] ?? // Change this line
                                              'Unknown Venue',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          filteredVenues[index][
                                                  'address'] ?? // Change this line
                                              'Location',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          'Rs ${filteredVenues[index]['price'] ?? '1000'} per plate', // Change this line
                                          style: TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Photographer for you
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Photographer for you',
                            style: textTheme.headlineSmall),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VendorListPage(
                                  vendors: photographers,
                                  category: 'Photographer',
                                  token: widget.token,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Photographers Horizontal List
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      // For Photographers List
                      itemCount:
                          filteredPhotographers.length, // Update this line
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VendorDetailPage(
                                  vendorData: filteredPhotographers[
                                      index], // Update this line
                                  vendorType: 'photographer',
                                  token: widget.token,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 180,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(10)),
                                      child: photographers[index]['images'] !=
                                                  null &&
                                              photographers[index]['images']
                                                  .isNotEmpty
                                          ? Image.network(
                                              photographers[index]['images'][0]
                                                      ['fullUrl'] ??
                                                  '',
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey.shade300,
                                                  child: const Icon(
                                                      Icons.image_not_supported,
                                                      size: 40),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: Colors.grey.shade300,
                                              child: const Icon(
                                                  Icons.camera_alt,
                                                  size: 40),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          photographers[index]
                                                  ['photographyName'] ??
                                              'Unknown',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          photographers[index]['address'] ??
                                              'Location',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ), // Added missing closing parenthesis
                                        Text(
                                          'Rs ${photographers[index]['price'] ?? '50,000'} per Event',
                                          style: TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Decoration for events
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Decoration for events',
                            style: textTheme.headlineSmall),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VendorListPage(
                                  vendors: decorations,
                                  category: 'Decorator',
                                  token: widget.token,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Decorations Horizontal List
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredDecorations.length, // Change this line
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VendorDetailPage(
                                  vendorData: filteredDecorations[
                                      index], // Change this line
                                  vendorType: 'decorator',
                                  token: widget.token,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 180,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(10)),
                                      child: filteredDecorations[index][
                                                      'images'] != // Change this line
                                                  null &&
                                              filteredDecorations[index][
                                                      'images'] // Change this line
                                                  .isNotEmpty
                                          ? Image.network(
                                              filteredDecorations[index]
                                                              ['images'][
                                                          0] // Change this line
                                                      ['fullUrl'] ??
                                                  '',
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey.shade300,
                                                  child: const Icon(
                                                      Icons.image_not_supported,
                                                      size: 40),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: Colors.grey.shade300,
                                              child: const Icon(
                                                  Icons.celebration,
                                                  size: 40),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          filteredDecorations[index][
                                                  'decoratorName'] ?? // Change this line
                                              'Unknown',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          filteredDecorations[index][
                                                  'address'] ?? // Change this line
                                              'Location',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          'Rs ${filteredDecorations[index]['price'] ?? '45,000'} per event', // Change this line
                                          style: TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavBar(
        token: widget.token,
      ),
    );
  }
}

Widget _buildHorizontalScrollWithButtons(
  BuildContext context,
  List<dynamic> items,
  String Function(dynamic) nameGetter,
  dynamic Function(dynamic) imagesGetter,
  IconData fallbackIcon,
  String vendorType,
  String token,
) {
  final textTheme = Theme.of(context).brightness == Brightness.dark
      ? TTextTheme.darkTextTheme
      : TTextTheme.lightTextTheme;

  final ScrollController scrollController = ScrollController();

  return SizedBox(
    height: 220,
    child: Stack(
      children: [
        // Main ListView
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ListView.builder(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  // Navigate to vendor detail page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VendorDetailPage(
                        vendorData: items[index],
                        vendorType: vendorType,
                        token: token,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10)),
                            child: imagesGetter(items[index]) != null &&
                                    imagesGetter(items[index]).isNotEmpty
                                ? Image.network(
                                    imagesGetter(items[index])[0]['fullUrl'] ??
                                        '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                            Icons.image_not_supported,
                                            size: 40),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey.shade300,
                                    child: Icon(fallbackIcon, size: 40),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            nameGetter(items[index]),
                            style: textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),


        // Left scroll button
        if (items.isNotEmpty)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                  ],
                  stops: const [0.0, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Center(
                child: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.7),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      final currentPosition = scrollController.offset;
                      final scrollAmount = currentPosition - 200.0;
                      scrollController.animateTo(
                        scrollAmount < 0 ? 0 : scrollAmount,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        if (items.isNotEmpty)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Center(
                child: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.7),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white),
                    onPressed: () {
                      final currentPosition = scrollController.offset;
                      final maxScrollExtent =
                          scrollController.position.maxScrollExtent;
                      final scrollAmount = currentPosition + 200.0;
                      scrollController.animateTo(
                        scrollAmount > maxScrollExtent
                            ? maxScrollExtent
                            : scrollAmount,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}