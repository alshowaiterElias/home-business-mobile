import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'screens/main/main_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/categories/category_products_screen.dart';
import 'screens/store/store_screen.dart';
import 'screens/seller/seller_dashboard_screen.dart';
import 'screens/seller/create_store_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/support_screen.dart';
import 'screens/profile/about_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/store/all_stores_screen.dart';
import 'controllers/auth_controller.dart';
import 'core/network/storage_service.dart';
import 'core/network/api_client.dart';
import 'controllers/data_controller.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/network_controller.dart';
import 'core/network/whatsapp_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize networking and storage
  await StorageService.init();
  ApiClient.init();
  await WhatsAppService.loadTemplates();

  Get.put(NetworkController(), permanent: true);
  Get.put(AuthController(), permanent: true);
  Get.put(DataController(), permanent: true);
  Get.put(FavoritesController(), permanent: true);
  runApp(const HomeBusinessApp());
}

class HomeBusinessApp extends StatelessWidget {
  const HomeBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'السوق المنزلي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Global RTL Support for Arabic
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'YE')],
      locale: const Locale('ar', 'YE'),

      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/auth', page: () => const AuthScreen()),
        GetPage(name: '/main', page: () => MainScreen()),
        GetPage(name: '/search', page: () => const SearchScreen()),
        GetPage(name: '/store', page: () => const StoreScreen()),
        GetPage(name: '/all-stores', page: () => const AllStoresScreen()),
        GetPage(
          name: '/category-products',
          page: () => const CategoryProductsScreen(),
        ),
        GetPage(name: '/create-store', page: () => const CreateStoreScreen()),
        GetPage(
          name: '/seller-dashboard',
          page: () => const SellerDashboardScreen(),
        ),
        GetPage(name: '/add-product', page: () => const AddProductScreen()),
        GetPage(name: '/edit-business', page: () => const EditBusinessScreen()),
        GetPage(
          name: '/notifications',
          page: () => const NotificationsScreen(),
        ),
        GetPage(name: '/support', page: () => const SupportScreen()),
        GetPage(name: '/about', page: () => const AboutScreen()),
      ],
    );
  }
}
