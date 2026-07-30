import 'package:flutter/material.dart';

class LocalModel {
  final String id;
  final String name;
  final String size;
  final double requiredRamGb;
  final String urlGguf;
  final String badge;
  final Color badgeColor;
  final String description;
  bool isDownloaded;

  LocalModel({
    required this.id,
    required this.name,
    required this.size,
    required this.requiredRamGb,
    required this.urlGguf,
    required this.badge,
    required this.badgeColor,
    required this.description,
    this.isDownloaded = false,
  });
}
