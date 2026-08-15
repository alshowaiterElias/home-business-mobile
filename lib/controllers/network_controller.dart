import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NetworkController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  final isConnected = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      print('Connectivity check failed: $e');
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final hasConnection = results.any((result) => result != ConnectivityResult.none);
    
    // Only show snackbar if state changes to disconnected
    if (!hasConnection && isConnected.value) {
      isConnected.value = false;
      Get.snackbar(
        'لا يوجد اتصال بالإنترنت',
        'يرجى التحقق من الاتصال بالشبكة للمتابعة',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.wifi_off, color: Colors.white),
      );
    } else if (hasConnection && !isConnected.value) {
      isConnected.value = true;
      Get.snackbar(
        'تم استعادة الاتصال',
        'أنت الآن متصل بالإنترنت',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.wifi, color: Colors.white),
      );
    }
  }
}
