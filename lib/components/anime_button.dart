import 'package:flutter/material.dart';

// 自定义动画按钮组件
class AnimeButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDisabled;
  final double borderRadius;
  final EdgeInsets padding;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  
  const AnimeButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.isDisabled = false,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.leadingIcon,
    this.trailingIcon,
  }) : super(key: key);
  
  @override
  _AnimeButtonState createState() => _AnimeButtonState();
}

class _AnimeButtonState extends State<AnimeButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 按钮颜色
    final backgroundColor = widget.isDisabled
        ? theme.disabledColor
        : widget.isPrimary
            ? theme.primaryColor
            : theme.colorScheme.secondary;
    
    final foregroundColor = Colors.white;
    
    final borderColor = widget.isDisabled
        ? theme.disabledColor
        : widget.isPrimary
            ? theme.primaryColor
            : theme.colorScheme.secondary;
    
    return MouseRegion(
      onEnter: (_) {
        if (!widget.isDisabled) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ElevatedButton(
            onPressed: (widget.isDisabled || widget.onPressed == null)
                ? null
                : () {
                    _controller.forward().then((_) {
                      _controller.reverse();
                      widget.onPressed!();
                    });
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                side: BorderSide(
                  color: _isHovered && !widget.isDisabled ? borderColor.withOpacity(0.8) : Colors.transparent,
                  width: 2,
                ),
              ),
              padding: widget.padding,
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: theme.textTheme.bodyLarge?.fontFamily,
              ),
              animationDuration: const Duration(milliseconds: 200),
            ).copyWith(
              backgroundColor: ButtonStyleButton.allOrNull<Color?>(backgroundColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.leadingIcon != null) ...[
                  widget.leadingIcon!,
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  textAlign: TextAlign.center,
                ),
                if (widget.trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  widget.trailingIcon!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
