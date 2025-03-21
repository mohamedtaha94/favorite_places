import 'dart:io';
import 'package:favorite_places/models/place.dart';
import 'package:favorite_places/models/place_location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart' as syspath;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';

Future<Database> _getDatabase() async {
  final dbpath = await sql.getDatabasesPath();
  final db = await sql.openDatabase(
    path.join(dbpath, 'palces.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE user_places(id TEXT PRIMARY KEY, title TEXT, image TEXT,lat REAL,lng REAL,address TEXT)',
      );
    },
    version: 1,
  );
  return db;
}

class UserPlacesNotifier extends StateNotifier<List<Place>> {
  UserPlacesNotifier() : super(const []);

  Future<void> loadPlaces() async {
  final db = await _getDatabase();
  final data = await db.query('user_places');

  final places = await Future.wait(data.map((row) async {
    final imageFile = File(row['image'] as String);

    if (!await imageFile.exists() || await imageFile.length() == 0) {
      // ignore: avoid_print
      print("Warning: Image file does not exist at path ${row['image']}");
      return null; // Skip this entry
    }

    return Place(
      id: row['id'] as String,
      image: imageFile,
      title: row['title'] as String,
      placeLocation: PlaceLocation(
        latitude: row['lat'] as double,
        longitude: row['lng'] as double,
        address: row['address'] as String,
      ),
    );
  }));

  state = places.whereType<Place>().toList(); // Remove null values
}

  void addPlace(String title, File image, PlaceLocation location) async {
    final appDir = await syspath.getApplicationDocumentsDirectory();
    final filename = path.basename(image.path);
    final copiedImage = await image.copy('${appDir.path}/$filename');
    final newPlace = Place(
      title: title,
      image: copiedImage,
      placeLocation: location,
    );

    final db = await _getDatabase();
   await db.insert('user_places', {
      'id': newPlace.id,
      'title': newPlace.title,
      'image': newPlace.image.path,
      'lat': newPlace.placeLocation.latitude,
      'lng': newPlace.placeLocation.longitude,
      'address': newPlace.placeLocation.address,
    });

    state = [newPlace, ...state];
  }
}

final userPlacesProvider =
    StateNotifierProvider<UserPlacesNotifier, List<Place>>(
      (ref) => UserPlacesNotifier(),
    );
