import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/components/bottom_nav_bar.dart';
import 'package:fyp_namaste_events/services/Api/vendorService.dart';
import 'package:fyp_namaste_events/utils/costants/api_constants.dart';
import 'package:fyp_namaste_events/pages/vendor_detail_page.dart';
import 'package:fyp_namaste_events/pages/vendor_list_page.dart';

class VendorsPage extends StatefulWidget {
  final String token;
  const VendorsPage({Key? key,
    required this.token,
  
  }) : super(key: key);

  @override
  State<VendorsPage> createState() => _VendorsPageState();
}

class _VendorsPageState extends State<VendorsPage> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late VendorService vendorService;
  
  // For image slider
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> _sliderImages = [
    'assets/onboarding1.JPG',
    'assets/onboarding2.JPG',
    'assets/onboarding3.JPG',
    'assets/furthermore.JPG',
  ];
  
  // For vendor data
  List<dynamic> venues = [];
  List<dynamic> photographers = [];
  List<dynamic> foodServices = [];
  List<dynamic> decorServices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    vendorService = VendorService(APIConstants.baseUrl);
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Create slide animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuad,
    ));
    
    _animationController.forward();
    
    // Auto-scroll for image slider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScroll();
    });
    
    // Fetch vendor data
    fetchVendors();
  }
  
  // Fetch vendors from MongoDB
  Future<void> fetchVendors() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final response = await vendorService.fetchAllInventory();
      
      if (response['success']) {
        setState(() {
          venues = response['data']['venues'];
          photographers = response['data']['photographers'];
          foodServices = response['data']['foodServices'] ?? [];
          decorServices = response['data']['decorators'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching vendors: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _autoScroll() {
    Future.delayed(const Duration(seconds: 3)).then((_) {
      if (_pageController.hasClients) {
        if (_currentPage < _sliderImages.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }

        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
      _autoScroll();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Build page indicator dots
  List<Widget> _buildPageIndicator() {
    List<Widget> indicators = [];
    for (int i = 0; i < _sliderImages.length; i++) {
      indicators.add(
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == i
                ? Colors.white
                : Colors.white.withOpacity(0.5),
          ),
        ),
      );
    }
    return indicators;
  }

  // Build category card
  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required String image,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                    height: double.infinity,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(fontSize: 14),
                    prefixIcon: const Icon(Icons.search, size: 20),
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Image Slider at the top
                Container(
                  height: 250,  // Changed from 180 to 250
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // PageView for sliding images
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (int page) {
                          setState(() {
                            _currentPage = page;
                          });
                        },
                        itemCount: _sliderImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(_sliderImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
  
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
  
                      // Page indicator dots
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _buildPageIndicator(),
                        ),
                      ),
                    ],
                  ),
                ),
  
                // Rest of the content in a scrollable area
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Venues Category
                        _buildCategoryCard(
                          context,
                          title: 'Venues',
                          subtitle: venues.isNotEmpty 
                              ? '${venues.length} venues available'
                              : 'Banquet Halls, Event Halls, Party Palace',
                          color: Colors.purple[200]!,
                          image: 'assets/eventvenue.png',
                          onTap: () {
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
                        ),
  
                        // Photographers Category
                        _buildCategoryCard(
                          context,
                          title: 'Photographers',
                          subtitle: photographers.isNotEmpty 
                              ? '${photographers.length} photographers available'
                              : 'Johna Photography, Rahul Clicks...',
                          color: Colors.green[200]!,
                          image: 'assets/photography.png',
                          onTap: () {
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
                        ),
  
                        // Planning and Decor Category
                        _buildCategoryCard(
                          context,
                          title: 'Planning and Decor',
                          subtitle: decorServices.isNotEmpty 
                              ? '${decorServices.length} decor services available'
                              : 'Wedding Planners, Decoration Experts...',
                          color: Colors.pink[100]!,
                          image: 'assets/decorartion.png',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VendorListPage(
                                  vendors: decorServices,
                                  category: 'Decorator',
                                  token: widget.token,

                                ),
                              ),
                            );
                          },
                        ),
  
                        // Food Category
                        _buildCategoryCard(
                          context,
                          title: 'Food',
                          subtitle: foodServices.isNotEmpty 
                              ? '${foodServices.length} food services available'
                              : 'Catering Services, Cake, Drinks...',
                          color: Colors.yellow[200]!,
                          image: 'assets/food.png',
                          onTap: () {
                            if (foodServices.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No food services available at the moment'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VendorDetailPage(
                                    vendorData: foodServices,
                                    vendorType: 'food',
                                  token: widget.token,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
  
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar:  BottomNavBar(token: widget.token,),
    );
  }
}
