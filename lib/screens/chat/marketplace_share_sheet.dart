import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/data_service.dart';
import '../../core/network/api_client.dart';
import '../../controllers/conversation_controller.dart';
import '../../models/dummy_data.dart'; // for Product, Business

class MarketplaceShareSheet extends StatefulWidget {
  final ConversationController chatController;

  const MarketplaceShareSheet({super.key, required this.chatController});

  @override
  State<MarketplaceShareSheet> createState() => _MarketplaceShareSheetState();
}

class _MarketplaceShareSheetState extends State<MarketplaceShareSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _products = [];
  List<dynamic> _stores = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      _loadData();
    } else if (_products.isEmpty && _tabController.index == 0) {
      _loadData();
    } else if (_stores.isEmpty && _tabController.index == 1) {
      _loadData();
    }
  }

  Future<void> _loadData([String query = '']) async {
    setState(() => _isLoading = true);
    try {
      if (_tabController.index == 0) {
        final res = await DataService.getProducts(search: query.isNotEmpty ? query : null, limit: 10);
        setState(() => _products = res);
      } else {
        final res = await DataService.getBusinesses(search: query.isNotEmpty ? query : null, limit: 10);
        setState(() => _stores = res);
      }
    } catch (e) {
      debugPrint('Error loading share data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearch(String val) {
    _loadData(val.trim());
  }

  void _shareProduct(Map<String, dynamic> p) {
    final product = Product.fromJson(p);
    widget.chatController.sendReferenceMessage(
      type: 'PRODUCT_REFERENCE',
      referenceType: 'PRODUCT',
      referenceId: product.id,
      snapshotTitle: product.title,
      snapshotPrice: product.price.toString(),
      snapshotImage: product.imageUrl.isNotEmpty ? product.imageUrl : null,
    );
    Get.back();
  }

  void _shareStore(Map<String, dynamic> b) {
    // b is JSON for business
    widget.chatController.sendReferenceMessage(
      type: 'STORE_REFERENCE',
      referenceType: 'STORE',
      referenceId: b['id'] ?? '',
      snapshotTitle: b['businessName'] ?? b['business_name'] ?? 'متجر',
      snapshotImage: b['logoUrl'] ?? b['logo_url'],
    );
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.textHint.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Text(
            'مشاركة في المحادثة',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: context.colors.primary,
            unselectedLabelColor: context.colors.textSecondary,
            indicatorColor: context.colors.primary,
            tabs: const [
              Tab(text: 'منتجات'),
              Tab(text: 'متاجر'),
            ],
          ),
          
          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onSubmitted: _onSearch,
              decoration: InputDecoration(
                hintText: 'بحث...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _loadData();
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: context.colors.surface,
              ),
            ),
          ),
          
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsList(),
                _buildStoresList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_products.isEmpty) {
      return Center(
        child: Text('لا توجد منتجات', style: TextStyle(color: context.colors.textHint)),
      );
    }
    
    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final p = _products[index];
        final product = Product.fromJson(p);
        final imageUrl = product.imageUrl.isNotEmpty ? ApiClient.getImageUrl(product.imageUrl) : null;
        
        return ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(8),
              image: imageUrl != null ? DecorationImage(image: CachedNetworkImageProvider(imageUrl), fit: BoxFit.cover) : null,
            ),
            child: imageUrl == null ? Icon(Icons.image_outlined, color: context.colors.textHint) : null,
          ),
          title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${product.price} ر.ي', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold)),
          trailing: OutlinedButton(
            onPressed: () => _shareProduct(p),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
              side: BorderSide(color: context.colors.primary),
            ),
            child: Text('إرسال', style: TextStyle(color: context.colors.primary)),
          ),
        );
      },
    );
  }

  Widget _buildStoresList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_stores.isEmpty) {
      return Center(
        child: Text('لا توجد متاجر', style: TextStyle(color: context.colors.textHint)),
      );
    }
    
    return ListView.builder(
      itemCount: _stores.length,
      itemBuilder: (context, index) {
        final b = _stores[index];
        final logoUrl = b['logoUrl'] ?? b['logo_url'];
        final fullLogoUrl = logoUrl != null ? ApiClient.getImageUrl(logoUrl) : null;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: context.colors.surface,
            backgroundImage: fullLogoUrl != null ? CachedNetworkImageProvider(fullLogoUrl) : null,
            child: fullLogoUrl == null ? Icon(Icons.storefront_rounded, color: context.colors.primary) : null,
          ),
          title: Text(b['businessName'] ?? b['business_name'] ?? 'متجر', maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: OutlinedButton(
            onPressed: () => _shareStore(b),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
              side: BorderSide(color: context.colors.primary),
            ),
            child: Text('إرسال', style: TextStyle(color: context.colors.primary)),
          ),
        );
      },
    );
  }
}
