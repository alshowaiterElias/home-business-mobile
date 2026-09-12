import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_business_mobile/screens/ai/marketplace_assistant_sheet.dart';

/// A sleek, compact glassmorphic AI Assistant Orb (The Aurora Orb).
/// Replaces the bulky rectangular FAB with a vibrant emerald-to-purple gradient,
/// breathing ambient glow, and tactile haptic response.
class AskMarketplaceAiButton extends StatefulWidget {
  final Map<String, dynamic> contextData;

  const AskMarketplaceAiButton({super.key, required this.contextData});

  @override
  State<AskMarketplaceAiButton> createState() => _AskMarketplaceAiButtonState();
}

class _AskMarketplaceAiButtonState extends State<AskMarketplaceAiButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 8.0, end: 18.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openAssistant() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MarketplaceAssistantSheet(contextData: widget.contextData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = 'ai_orb_${widget.contextData['screen'] ?? 'default'}';

    return Tooltip(
      message: 'المساعد الذكي للسوق ✨',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = _isPressed ? 0.92 : _scaleAnimation.value;

          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: _openAssistant,
          child: Hero(
            tag: heroTag,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Aurora Multi-Stop Gradient: Emerald brand -> Amethyst -> Vivid Violet
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2E7D32), // Brand Emerald
                        Color(0xFF6A1B9A), // Amethyst
                        Color(0xFF8E24AA), // Vivid Violet
                      ],
                      stops: [0.0, 0.52, 1.0],
                    ),
                    boxShadow: [
                      // Breathing ambient violet glow
                      BoxShadow(
                        color: const Color(0xFF8E24AA).withValues(
                          alpha: 0.20 + (0.22 * _controller.value),
                        ),
                        blurRadius: _glowAnimation.value,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                      // Subtle emerald brand counter-glow
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.22),
                        blurRadius: 8,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.38),
                      width: 1.4,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glass specular highlight for tactile depth
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: const Alignment(-0.35, -0.4),
                            radius: 0.75,
                            colors: [
                              Colors.white.withValues(alpha: 0.32),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Core Sparkle Icon
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
