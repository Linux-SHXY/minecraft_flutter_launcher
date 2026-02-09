import 'package:flutter/material.dart';

// 自定义动画卡片组件
class AnimeCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget? icon;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final Color? borderColor;
  
  const AnimeCard({
    Key? key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.onTap,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderColor,
  }) : super(key: key);
  
  @override
  _AnimeCardState createState() => _AnimeCardState();
}

class _AnimeCardState extends State<AnimeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 150),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final cardBackgroundColor = widget.backgroundColor ?? theme.cardColor;
    final defaultBorderColor = widget.borderColor ?? theme.dividerColor;
    final hoverBorderColor = theme.primaryColor;
    
    return MouseRegion(
      onEnter: (_) {
        if (widget.onTap != null) {
          setState(() => _isHovered = true);
          _controller.forward();
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            side: BorderSide(
              color: _isHovered 
                  ? hoverBorderColor 
                  : defaultBorderColor,
              width: 1.0,
            ),
          ),
          color: cardBackgroundColor,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            overlayColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.hovered)) {
                return theme.primaryColor.withOpacity(0.1);
              }
              if (states.contains(MaterialState.pressed)) {
                return theme.primaryColor.withOpacity(0.2);
              }
              return Colors.transparent;
            }),
            child: Padding(
              padding: widget.padding,
              child: Row(
                children: [
                  // 图标区域
                  if (widget.icon != null) ...[
                    _buildIconContainer(widget.icon!, theme),
                    const SizedBox(width: 16),
                  ],
                  
                  // 文本内容区域
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // 箭头图标
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    transform: Matrix4.translationValues(_isHovered ? 4.0 : 0.0, 0.0, 0.0),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: _isHovered ? theme.primaryColor : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // 构建图标容器
  Widget _buildIconContainer(Widget icon, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isHovered 
            ? theme.primaryColor.withOpacity(0.1) 
            : theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isHovered 
              ? theme.primaryColor.withOpacity(0.3) 
              : theme.dividerColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: icon,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
