import 'package:flutter/material.dart';

class CategoryTile extends StatelessWidget {
  final String title;
  final String image;
  final VoidCallback onTap;

  const CategoryTile(
      {super.key,
        required this.title,
        required this.image,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(image, width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(height: 5),
          Text(title,
              style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}