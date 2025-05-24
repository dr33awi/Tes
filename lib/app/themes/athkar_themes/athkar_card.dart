// lib/app/widgets/athkar_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.borderRadius = ThemeSizes.borderRadiusLarge,
    this.hasGradientBackground = false,
    this.gradientColors,
  }) : super(key: key);

  @override
  State<AthkarCard> createState() => _AthkarCardState();
}

class _AthkarCardState extends State<AthkarCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
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

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);
    final Color cardColor = widget.primaryColor ?? AppTheme.getPrimaryColor(context);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            margin: widget.margin ?? const EdgeInsets.symmetric(
              horizontal: ThemeSizes.marginMedium,
              vertical: ThemeSizes.marginSmall,
            ),
            child: _buildCardContent(context, isDark, cardColor),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(BuildContext context, bool isDark, Color cardColor) {
    if (widget.hasGradientBackground) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.gradientColors ?? [
              cardColor.withOpacity(0.8),
              cardColor,
            ],
          ),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: InkWell(
            onTap: widget.onTap != null ? _handleTap : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            splashColor: Colors.white.withOpacity(0.2),
            child: _buildInnerContent(context, isDark, cardColor, true),
          ),
        ),
      );
    }

    return SoftCard(
      borderRadius: widget.borderRadius,
      hasBorder: true,
      elevation: 2,
      onTap: widget.onTap != null ? _handleTap : null,
      child: _buildInnerContent(context, isDark, cardColor, false),
    );
  }

  Widget _buildInnerContent(BuildContext context, bool isDark, Color cardColor, bool isGradient) {
    return Padding(
      padding: const EdgeInsets.all(ThemeSizes.marginLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with counter and favorite button
          if (widget.showCounter || widget.onFavoriteToggle != null)
            _buildHeader(context, isDark, cardColor, isGradient),
          
          if (widget.showCounter || widget.onFavoriteToggle != null)
            const SizedBox(height: ThemeSizes.marginLarge),
          
          // Content
          _buildContent(context, isDark, isGradient),
          
          // Source
          if (widget.source != null) ...[
            const SizedBox(height: ThemeSizes.marginLarge),
            _buildSource(context, isDark, cardColor, isGradient),
          ],
          
          // Actions
          if (widget.showActions) ...[
            const SizedBox(height: ThemeSizes.marginLarge),
            _buildActions(context, isDark, cardColor, isGradient),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color cardColor, bool isGradient) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Counter
        if (widget.showCounter)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ThemeSizes.marginMedium,
              vertical: ThemeSizes.marginSmall,
            ),
            decoration: BoxDecoration(
              color: isGradient 
                  ? Colors.white.withOpacity(0.2)
                  : cardColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusCircular),
              border: isGradient ? Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.brightness_1,
                  size: 8,
                  color: isGradient ? Colors.white : cardColor,
                ),
                const SizedBox(width: ThemeSizes.marginSmall),
                Text(
                  'عدد التكرار ${widget.currentCount}/${widget.totalCount}',
                  style: TextStyle(
                    color: isGradient ? Colors.white : cardColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        
        // Favorite button
        if (widget.onFavoriteToggle != null)
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onFavoriteToggle!();
            },
            icon: Icon(
              widget.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isGradient 
                  ? Colors.white 
                  : (widget.isFavorite ? Colors.red : AppTheme.getTextColor(context, isSecondary: true)),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, bool isGradient) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeSizes.marginMedium,
        vertical: ThemeSizes.marginLarge,
      ),
      child: Stack(
        children: [
          // Opening quote
          Positioned(
            top: -5,
            right: -5,
            child: Icon(
              Icons.format_quote,
              size: 24,
              color: (isGradient ? Colors.white : AppTheme.getTextColor(context)).withOpacity(0.2),
            ),
          ),
          
          // Content text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ThemeSizes.marginMedium),
            child: Text(
              widget.content,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                height: 1.8,
                fontWeight: FontWeight.w500,
                color: isGradient ? Colors.white : AppTheme.getTextColor(context),
                fontFamily: 'Amiri',
              ),
            ),
          ),
          
          // Closing quote
          Positioned(
            bottom: -5,
            left: -5,
            child: Transform.rotate(
              angle: 3.14159,
              child: Icon(
                Icons.format_quote,
                size: 24,
                color: (isGradient ? Colors.white : AppTheme.getTextColor(context)).withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSource(BuildContext context, bool isDark, Color cardColor, bool isGradient) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ThemeSizes.marginLarge,
          vertical: ThemeSizes.marginSmall,
        ),
        decoration: BoxDecoration(
          color: isGradient 
              ? Colors.black.withOpacity(0.2)
              : cardColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ThemeSizes.borderRadiusCircular),
          border: isGradient ? Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ) : null,
        ),
        child: Text(
          widget.source!,
          style: TextStyle(
            color: isGradient ? Colors.white : cardColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDark, Color cardColor, bool isGradient) {
    return AthkarActionButtons(
      onCopy: _handleCopy,
      onShare: _handleShare,
      onInfo: widget.onInfo,
      color: isGradient ? Colors.white : cardColor,
      isGradientBackground: isGradient,
    );
  }
}