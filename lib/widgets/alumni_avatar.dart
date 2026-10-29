import 'package:flutter/material.dart';

Widget alumniAvatar(String value, {double size = 96}) {
  final placeholder = Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(Icons.person, size: size / 2, color: const Color(0xFF1976D2)),
  );

  if (value.isEmpty) return placeholder;

  final Widget image;
  if (value.startsWith('data:image')) {
    image = Image.memory(
      Uri.parse(value).data!.contentAsBytes(),
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  } else {
    image = Image.network(
      value,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
  return ClipRRect(borderRadius: BorderRadius.circular(14), child: image);
}
