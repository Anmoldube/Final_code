import 'package:dio/dio.dart';

/// Debug script to test authentication and token refresh
/// Run this with: dart debug_auth.dart
void main() async {
  print('🔍 Starting Authentication Debug...\n');

  await testAuthenticationStatus();
}

Future<void> testAuthenticationStatus() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.6:5000',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  // Test 1: Check if backend is running
  print('1️⃣ Testing Backend Connection...');
  try {
    final healthResponse = await dio.get('/health');
    print('✅ Backend is running: ${healthResponse.statusCode}');
  } catch (e) {
    print('❌ Backend connection failed: $e');
    return;
  }

  // Test 2: Test authenticated endpoint without token
  print('\n2️⃣ Testing authenticated endpoint without token...');
  try {
    final response = await dio.post(
      '/api/messages/685bf28e186eda90af89be6e',
      data: {'content': 'test'},
    );
    print('Unexpected success: ${response.statusCode}');
  } catch (e) {
    if (e is DioException && e.response?.statusCode == 401) {
      print('✅ Got expected 401 error: ${e.response?.data}');
    } else {
      print('❌ Unexpected error: $e');
    }
  }

  // Test 3: Manual token refresh test
  print('\n3️⃣ Testing token refresh endpoint...');
  print('💡 You need to provide a refresh token to test this');
  print('   Check your Flutter app\'s secure storage for the refresh token');

  // Test 4: Test login endpoint
  print('\n4️⃣ Testing login endpoint...');
  print('💡 To fix the authentication issue, you can:');
  print('   1. Re-login in your Flutter app');
  print('   2. Check if tokens are being saved properly');
  print('   3. Verify token refresh logic is working');

  print('\n🔧 Recommended fixes:');
  print('   1. Add better logging to your auth interceptors');
  print('   2. Implement a force re-authentication mechanism');
  print('   3. Add token expiry validation before making requests');
}
