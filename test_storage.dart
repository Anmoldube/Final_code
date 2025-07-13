import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'lib/core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize storage service
  await StorageService.initialize();
  
  print('✅ Storage service initialized successfully');
  
  // Test token storage
  try {
    await StorageService.saveAccessToken('test_token_123');
    print('✅ Access token saved successfully');
    
    final token = await StorageService.getAccessToken();
    print('✅ Access token retrieved: ${token != null ? 'SUCCESS' : 'FAILED'}');
    
    if (token == 'test_token_123') {
      print('✅ Token storage test PASSED');
    } else {
      print('❌ Token storage test FAILED - token mismatch');
    }
  } catch (e) {
    print('❌ Token storage test FAILED: $e');
  }
  
  print('🎉 Storage test completed');
}