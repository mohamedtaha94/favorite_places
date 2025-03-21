import 'dart:io';

import 'package:favorite_places/models/place_location.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Place {
  final String id;
  final String title;
  final File image;
  final PlaceLocation placeLocation;

  Place( {required this.image, required this.title, required this.placeLocation ,String? id})
    : id = id??uuid.v4();
}
