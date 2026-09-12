import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../controllers/seller_analytics_controller.dart';
import '../../widgets/app_cached_image.dart';

class SellerAnalyticsScreen extends StatelessWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerAnalyticsController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text(
          'تحليلات المتجر 📊',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          Obx(() {
            if (controller.isRefreshing.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              );
            }
            return IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => controller.fetchAnalytics(isManual: true),
              tooltip: 'تحديث البيانات',
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.analyticsData.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchAnalytics(),
          color: AppTheme.primary,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.space16),
            children: [
              // ── Period Selector ──
              _buildPeriodSelector(controller, context),
              const SizedBox(height: AppTheme.space16),

              // ── Key Metrics Grid ──
              _buildMetricsGrid(controller, context),
              const SizedBox(height: AppTheme.space24),

              // ── Trend Line Chart ──
              _buildTrendChart(controller, context),
              const SizedBox(height: AppTheme.space24),

              // ── Top Products ──
              _buildTopProductsSection(controller, context, theme),
              const SizedBox(height: AppTheme.space24),

              // ── Recent Inquiries ──
              _buildRecentInquiriesSection(controller, context, theme),

              // ── Ad Performance (if any) ──
              if (controller.adPerformance.isNotEmpty) ...[
                const SizedBox(height: AppTheme.space24),
                _buildAdPerformanceSection(controller, context, theme),
              ],

              const SizedBox(height: AppTheme.space32),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPeriodSelector(
    SellerAnalyticsController controller,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: context.colors.divider),
      ),
      child: Obx(
        () => Row(
          children: [
            _buildPeriodTab(controller, context, 7, 'آخر 7 أيام'),
            _buildPeriodTab(controller, context, 14, 'آخر 14 يوماً'),
            _buildPeriodTab(controller, context, 30, 'آخر 30 يوماً'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(
    SellerAnalyticsController controller,
    BuildContext context,
    int days,
    String title,
  ) {
    final isSelected = controller.selectedPeriod.value == days;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setPeriod(days),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : context.colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(
    SellerAnalyticsController controller,
    BuildContext context,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'إجمالي المشاهدات',
                value: '${controller.totalViews}',
                subtitle: 'منتجات + المتجر',
                iconWidget: const Icon(Icons.visibility_rounded, size: 16, color: Color(0xFF1976D2)),
                bgColor: const Color(0xFFE3F2FD),
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'استفسارات واتساب',
                value: '${controller.totalInquiries}',
                subtitle: 'عملاء تواصلوا معك',
                iconWidget: const FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: AppTheme.whatsapp),
                bgColor: const Color(0xFFE8F8EE),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'إضافات للمفضلة',
                value: '${controller.totalFavorites}',
                subtitle: 'عملاء مهتمون',
                iconWidget: const Icon(Icons.favorite_rounded, size: 16, color: Color(0xFFE91E63)),
                bgColor: const Color(0xFFFCE4EC),
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: _buildMetricCard(
                context,
                title: 'متابعو المتجر',
                value: '${controller.totalFollowers}',
                subtitle: 'متابعون نشطون',
                iconWidget: const Icon(Icons.group_rounded, size: 16, color: Color(0xFF7B1FA2)),
                bgColor: const Color(0xFFF3E5F5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required Widget iconWidget,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: iconWidget,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: context.colors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(
    SellerAnalyticsController controller,
    BuildContext context,
  ) {
    final viewsData = controller.productViewsByDay;
    final inquiryData = controller.inquiriesByDay;

    final List<FlSpot> viewSpots = [];
    final List<FlSpot> inquirySpots = [];

    double maxY = 5;

    for (int i = 0; i < viewsData.length; i++) {
      final v = (viewsData[i]['count'] as num?)?.toDouble() ?? 0.0;
      if (v > maxY) maxY = v;
      viewSpots.add(FlSpot(i.toDouble(), v));
    }

    for (int i = 0; i < inquiryData.length; i++) {
      final inq = (inquiryData[i]['count'] as num?)?.toDouble() ?? 0.0;
      if (inq > maxY) maxY = inq;
      inquirySpots.add(FlSpot(i.toDouble(), inq));
    }

    maxY = (maxY * 1.25).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'مؤشر التفاعل اليومي 📈',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _buildLegendItem('مشاهدات', AppTheme.primary),
                  const SizedBox(width: 12),
                  _buildLegendItem('واتساب', AppTheme.whatsapp),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: context.colors.divider.withValues(alpha: 0.6),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == maxY) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: context.colors.textHint,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (viewsData.length / 5).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < viewsData.length) {
                          final dateStr = viewsData[idx]['date']?.toString() ?? '';
                          final parts = dateStr.split('-');
                          if (parts.length >= 3) {
                            return Text(
                              '${parts[1]}/${parts[2]}',
                              style: TextStyle(
                                fontSize: 9,
                                color: context.colors.textHint,
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Views Line
                  LineChartBarData(
                    spots: viewSpots,
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                  // Inquiries Line
                  LineChartBarData(
                    spots: inquirySpots,
                    isCurved: true,
                    color: AppTheme.whatsapp,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.whatsapp.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildTopProductsSection(
    SellerAnalyticsController controller,
    BuildContext context,
    ThemeData theme,
  ) {
    final topList = controller.topProducts;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'أكثر المنتجات تفاعلاً 🌟',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'أعلى 10',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          if (topList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'لا توجد بيانات مشاهدات للمنتجات في هذه الفترة.',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textHint,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topList.length,
              separatorBuilder: (_, __) => Divider(
                height: 16,
                color: context.colors.divider.withValues(alpha: 0.6),
              ),
              itemBuilder: (context, index) {
                final p = topList[index] as Map<String, dynamic>;
                final cover = p['coverImage'] != null
                    ? ApiClient.getImageUrl(p['coverImage'])
                    : '';
                return Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: index < 3
                            ? AppTheme.accent.withValues(alpha: 0.15)
                            : context.colors.divider,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: index < 3 ? Colors.amber.shade900 : context.colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: cover.isNotEmpty
                            ? AppCachedImage(imageUrl: cover)
                            : Container(
                                color: context.colors.divider,
                                child: const Icon(Icons.image, size: 20),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title and stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['title'] ?? 'منتج',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: 12,
                                color: context.colors.textHint,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${p['views'] ?? 0} مشاهدة',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.colors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const FaIcon(
                                FontAwesomeIcons.whatsapp,
                                size: 11,
                                color: AppTheme.whatsapp,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${p['inquiries'] ?? 0} استفسار',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentInquiriesSection(
    SellerAnalyticsController controller,
    BuildContext context,
    ThemeData theme,
  ) {
    final list = controller.recentInquiries;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'آخر استفسارات الواتساب 💬',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'لم يتم تسجيل أي استفسارات عبر الواتساب حتى الآن.',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textHint,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => Divider(
                height: 14,
                color: context.colors.divider.withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final inq = list[index] as Map<String, dynamic>;
                final isStore = inq['inquiryType'] == 'STORE';
                final dateStr = inq['createdAt'] != null
                    ? DateTime.tryParse(inq['createdAt'].toString())
                            ?.toString()
                            .substring(0, 16) ??
                        ''
                    : '';

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8EE),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.whatsapp,
                        size: 16,
                        color: AppTheme.whatsapp,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isStore
                                ? 'استفسار عام عن المتجر'
                                : 'استفسار عن منتج: ${inq['productTitle'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 10,
                              color: context.colors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAdPerformanceSection(
    SellerAnalyticsController controller,
    BuildContext context,
    ThemeData theme,
  ) {
    final ads = controller.adPerformance;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أداء إعلانات المتجر 📢',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ad = ads[index] as Map<String, dynamic>;
              final imgUrl = ApiClient.getImageUrl(ad['imageUrl'] ?? '');

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.background,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      child: SizedBox(
                        width: 55,
                        height: 45,
                        child: AppCachedImage(imageUrl: imgUrl),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildAdStatItem('ظهور', '${ad['impressions'] ?? 0}'),
                          _buildAdStatItem('نقرات', '${ad['clicks'] ?? 0}'),
                          _buildAdStatItem('نسبة النقر', '${ad['ctr'] ?? 0}%'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textHint),
        ),
      ],
    );
  }
}
