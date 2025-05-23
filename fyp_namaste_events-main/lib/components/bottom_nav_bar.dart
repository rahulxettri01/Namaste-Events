import 'package:flutter/material.dart';
import 'package:fyp_namaste_events/pages/BookingListPage.dart';
import 'package:fyp_namaste_events/pages/ProfilePage.dart';
import 'package:fyp_namaste_events/pages/VendorsPage.dart';
import 'package:fyp_namaste_events/pages/chat_page.dart';
import 'package:fyp_namaste_events/pages/home_page.dart';

class BottomNavBar extends StatefulWidget {
  final String token;
  const BottomNavBar({super.key, required this.token});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 0; // Track the selected index

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1931),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            // Navigate to the corresponding page based on the index
            switch (index) {
              case 0:
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        HomePage(token: widget.token),
                    transitionDuration: const Duration(milliseconds: 500),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
                break;
              case 1:
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        VendorsPage(token: widget.token),
                    transitionDuration: const Duration(milliseconds: 500),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
                break;
              case 2:
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        BookingListPage(token: widget.token),
                    transitionDuration: const Duration(milliseconds: 500),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
                break;
              case 3:
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        ChatPage(token: widget.token),
                    transitionDuration: const Duration(milliseconds: 500),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
                break;
              case 4:
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        ProfilePage(token: widget.token),
                    transitionDuration: const Duration(milliseconds: 500),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: "Vendors"),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today), label: "Bookings"),
            BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble), label: "Chat"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
          backgroundColor: const Color(0xFF0A1931),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[400],
        ),
      ),
    );
  }
}
