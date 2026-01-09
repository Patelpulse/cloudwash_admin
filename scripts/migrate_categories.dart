import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

// Update these with your actual values
const String BACKEND_API_URL = 'https://cloudwashapi.onrender.com/api';
const String FIREBASE_PROJECT_ID = 'cloudwash-6ceb6';

Future<void> main() async {
  print('🚀 Starting category migration...\n');

  // Initialize Firebase
  print('📱 Initializing Firebase...');
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDQgMfagJiN16By-sS4fbAM0Kf6omkSRG8',
      authDomain: 'cloudwash-6ceb6.firebaseapp.com',
      projectId: 'cloudwash-6ceb6',
      storageBucket: 'cloudwash-6ceb6.firebasestorage.app',
      messagingSenderId: '864806051234',
      appId: '1:864806051234:web:ce326d49512cc22f8a26fb',
    ),
  );
  print('✅ Firebase initialized\n');

  // Fetch categories from MongoDB backend
  print('📥 Fetching categories from MongoDB backend...');
  final categories = await fetchCategoriesFromBackend();
  print('✅ Found ${categories.length} categories\n');

  if (categories.isEmpty) {
    print('⚠️  No categories found in backend. Exiting.');
    return;
  }

  // Upload to Firebase
  print('📤 Uploading categories to Firebase Firestore...');
  final firestore = FirebaseFirestore.instance;
  int successCount = 0;
  int errorCount = 0;

  for (var category in categories) {
    try {
      final categoryData = {
        'name': category['name'] ?? '',
        'description': category['description'] ?? '',
        'price': category['price'] ?? 0,
        'imageUrl': category['imageUrl'] ?? '',
        'isActive': category['isActive'] ?? true,
        'mongoId': category['_id'], // Keep reference to MongoDB ID
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await firestore.collection('categories').add(categoryData);
      successCount++;
      print('✅ Migrated: ${category['name']}');
    } catch (e) {
      errorCount++;
      print('❌ Failed to migrate ${category['name']}: $e');
    }
  }

  print('\n📊 Migration Summary:');
  print('   Total: ${categories.length}');
  print('   Success: $successCount');
  print('   Failed: $errorCount');
  print('\n🎉 Migration complete!');
}

Future<List<dynamic>> fetchCategoriesFromBackend() async {
  try {
    final response = await http.get(
      Uri.parse('$BACKEND_API_URL/categories'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Adjust based on your actual API response structure
      if (data is List) {
        return data;
      } else if (data is Map && data['categories'] != null) {
        return data['categories'];
      } else if (data is Map && data['data'] != null) {
        return data['data'];
      }
      return [];
    } else {
      print('⚠️  Backend returned status code: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('❌ Error fetching categories: $e');
    return [];
  }
}
