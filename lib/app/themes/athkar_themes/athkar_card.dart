// lib/app/widgets/athkar_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:share_plus/share_plus.dart';
import '../theme_constants.dart';
import '../glassmorphism_widgets.dart';
import '../app_theme.dart';
import './action_buttons.dart';

/// بطاقة عرض الذكر قابلة لإعادة الاستخدام
class AthkarCard extends StatefulWidget {
  final String content;
  final String? source;
  final int currentCount;
  final int totalCount;
  final bool isFavorite;
  final Color? primaryColor;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onInfo;
  final bool showActions;
  final bool showCounter;
  final bool isCompleted;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool hasGradientBackground;
  final List<Color>? gradientColors;
  final IconData? categoryIcon;

  const AthkarCard({
    Key? key,
    required this.content,
    this.source,
    this.currentCount = 0,
    this.totalCount = 1,
    this.isFavorite = false,
    this.primaryColor,
    this.onTap,
    this.onFavoriteToggle,
    this.onCopy,
    this.onShare,
    this.onInfo,
    this.showActions = true,
    this.showCounter = true,
    this.isCompleted = false,
    this.width,
    this.margin,
    this.borderRadius = 24,
    this.hasGradientBackground = false,
    this.gradientColors,
    this.categoryIcon,
  }) : super(key: key);

  @override
  State<AthkarCard> createState() => _AthkarCardState();
}

class _AthkarCardState extends State<AthkarCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      HapticFeedback.lightImpact();
      setState(() => _isPressed = true);
      _animationController.forward().then((_) {
        _animationController.reverse();
        setState(() => _isPressed = false);
      });
      widget.onTap!();
    }
  }

  void _handleCopy() {
    String textToCopy = widget.content;
    if (widget.source != null) {
      textToCopy += '\n\nالمصدر: ${widget.source}';
    }
    
    Clipboard.setData(ClipboardData(text: textToCopy)).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم نسخ الذكر'),
            backgroundColor: widget.primaryColor ?? AppTheme.getPrimaryColor(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusMedium),
            ),
          ),
        );
      }
    });
    
    widget.onCopy?.call();
  }

  void _handleShare() {
    String textToShare = widget.content;
    if (widget.source != null) {
      textToShare += '\n\nالمصدر: ${widget.source}';
    }
    
    Share.share(textToShare, subject: 'ذكر من تطبيق الأذكار');
    widget.onShare?.call();
  }

  // الحصول على تدرج الألوان
  List<Color> _getGradientColors() {
    if (widget.gradientColors != null) {
      return widget.gradientColors!;
    }
    
    Color baseColor = widget.primaryColor ?? AppTheme.getPrimaryColor(context);
    Color darkColor = HSLColor.fromColor(baseColor)
        .withLightness(HSLColor.fromColor(baseColor).lightness * 0.7)
        .toColor();
    
    return [baseColor.withOpacity(0.9), darkColor];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPressed ? _scaleAnimation.value : 1.0,
          child: Container(
            width: widget.width,
            margin: widget.margin ?? const EdgeInsets.symmetric(
              horizontal: ThemeSizes.marginMedium,
              vertical: 10,
            ),
            child: _buildCardContent(context, isDark),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(BuildContext context, bool isDark) {
    return Card(
      elevation: 15,
      shadowColor: (widget.primaryColor ?? AppTheme.getPrimaryColor(context)).withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: _getGradientColors(),
            stops: const [0.3, 1.0],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: InkWell(
            onTap: widget.onTap != null ? _handleTap : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              clipBehavior: Clip.none,
              children: [

                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with counter and favorite button
                      if (widget.showCounter || widget.onFavoriteToggle != null)
                        _buildHeader(context, isDark),
                      
                      if (widget.showCounter || widget.onFavoriteToggle != null)
                        const SizedBox(height: 12),
                      
                      // Content with background
                      _buildContent(context, isDark),
                      
                      // Source
                      if (widget.source != null) ...[
                        const SizedBox(height: 12),
                        _buildSource(context, isDark),
                      ],
                      
                      // Actions
                      if (widget.showActions) ...[
                        const SizedBox(height: 16),
                        _buildActions(context, isDark),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Counter
        if (widget.showCounter)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.categoryIcon != null) ...[
                  Icon(
                    widget.categoryIcon,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  'عدد التكرار ${widget.currentCount}/${widget.totalCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        
        // Favorite button
        if (widget.onFavoriteToggle != null)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isFavorite ? _pulseAnimation.value : 1.0,
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Icon(
                      widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onFavoriteToggle!();
                      if (widget.isFavorite == false) {
                        _animationController.reset();
                        _animationController.forward();
                      }
                    },
                    tooltip: widget.isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
                    splashRadius: 20,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 25,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // علامة اقتباس في البداية
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.format_quote,
              size: 18,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          
          Column(
            children: [
              Text(
                widget.content,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  height: 2.0,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Amiri-Bold',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          
          // علامة اقتباس في النهاية
          Positioned(
            bottom: 0,
            left: 0,
            child: Transform.rotate(
              angle: 3.14159, // 180 درجة
              child: Icon(
                Icons.format_quote,
                size: 18,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSource(BuildContext context, bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          widget.source!,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // زر النسخ
        _buildActionButton(
          icon: Icons.copy,
          label: 'نسخ',
          onPressed: _handleCopy,
        ),
        const SizedBox(width: 12),
        
        // زر المشاركة
        _buildActionButton(
          icon: Icons.share,
          label: 'مشاركة',
          onPressed: _handleShare,
        ),
        
        // زر فضل الذكر
        if (widget.onInfo != null) ...[
          const SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.info_outline,
            label: 'فضل الذكر',
            onPressed: widget.onInfo!,
          ),
        ],
      ],
    );
  }

  // زر الإجراء بنفس نمط athkar_details_screen
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}