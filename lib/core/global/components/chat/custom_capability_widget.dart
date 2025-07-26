import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:freeaihub/core/models/ai/ai_model.dart';
import 'package:sizer/sizer.dart';

class CustomCapabilityWidget extends StatefulWidget {
  final double iconSize;
  final bool isWebSearchEnabled;
  final bool isImageGenEnabled;

  final VoidCallback onWebSearchToggle;
  final VoidCallback onImageGenToggle;

  final ToolCapabilities toolCapabilities;

  const CustomCapabilityWidget({
    super.key,
    required this.iconSize,
    required this.isWebSearchEnabled,
    required this.isImageGenEnabled,

    required this.onWebSearchToggle,
    required this.onImageGenToggle,
    required this.toolCapabilities,
  });

  @override
  State<CustomCapabilityWidget> createState() => _CustomCapabilityWidgetState();
}

class _CustomCapabilityWidgetState extends State<CustomCapabilityWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isExpanded = false;
  OverlayEntry? _backdropEntry;
  final GlobalKey _panelKey = GlobalKey();
  final GlobalKey _toolsButtonKey = GlobalKey();

  // Local states to reflect switch instantly
  late bool _webSearchEnabled;
  late bool _imageGenEnabled;

  @override
  void initState() {
    super.initState();
    _webSearchEnabled = widget.isWebSearchEnabled;
    _imageGenEnabled = widget.isImageGenEnabled;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant CustomCapabilityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync local state if parent updates
    _webSearchEnabled = widget.isWebSearchEnabled;
    _imageGenEnabled = widget.isImageGenEnabled;
  }

  @override
  void dispose() {
    _removeBackdrop();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        _insertBackdrop();
      } else {
        _animationController.reverse();
        _removeBackdrop();
      }
    });
  }

  void _insertBackdrop() {
    if (_backdropEntry != null) return;

    _backdropEntry = OverlayEntry(
      builder: (context) {
        // Recalculate position each build
        RenderBox? btnBox = _toolsButtonKey.currentContext?.findRenderObject() as RenderBox?;
        Offset btnPos = btnBox?.localToGlobal(Offset.zero) ?? Offset.zero;

        // Build current caps list with live state
        final caps = <_CapabilityConfig>[
          if (widget.toolCapabilities.webSearch)
            _CapabilityConfig(
              icon: Icons.language,
              label: 'Search the web',
              isOn: () => _webSearchEnabled,
              toggle: () {
                widget.onWebSearchToggle();
                _webSearchEnabled = !_webSearchEnabled;
                setState(() {});
                _backdropEntry?.markNeedsBuild();
              },
            ),
          if (widget.toolCapabilities.imageGeneration)
            _CapabilityConfig(
              icon: Icons.image,
              label: 'Image Generation',
              isOn: () => _imageGenEnabled,
              toggle: () {
                widget.onImageGenToggle();
                _imageGenEnabled = !_imageGenEnabled;
                setState(() {});
                _backdropEntry?.markNeedsBuild();
              },
            ),
        ];

        // Compute panel height to place it fully above the button
        final int capCount = caps.length;
        const double itemSpacing = 4.0;
        const double verticalPadding = 16.0; // 8 top + 8 bottom from panel
        final double panelHeight =
            capCount * (widget.iconSize * 1.1) + (capCount - 1) * itemSpacing + verticalPadding;

        return Stack(
          children: [
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) {
                if (_isClickOutsidePanel(event.position)) {
                  _toggleExpansion();
                }
              },
              child: const SizedBox.expand(),
            ),
            Positioned(
              left: btnPos.dx,
              top: btnPos.dy - panelHeight - 8, // 8 px gap above chip
              child: _buildPanelWidget(caps, 1.1),
            ),
          ],
        );
      },
    );
    Overlay.of(context, debugRequiredFor: widget).insert(_backdropEntry!);
  }

  void _removeBackdrop() {
    _backdropEntry?.remove();
    _backdropEntry = null;
  }

  bool _isClickOutsidePanel(Offset globalPosition) {
    final RenderBox? panelBox = _panelKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? toolsBox = _toolsButtonKey.currentContext?.findRenderObject() as RenderBox?;

    // Check if click is inside panel
    if (panelBox != null) {
      final Offset panelPosition = panelBox.localToGlobal(Offset.zero);
      final Size panelSize = panelBox.size;
      final Rect panelRect = Rect.fromLTWH(
        panelPosition.dx,
        panelPosition.dy,
        panelSize.width,
        panelSize.height,
      );
      if (panelRect.contains(globalPosition)) {
        return false; // Click is inside panel
      }
    }

    // Check if click is inside tools button
    if (toolsBox != null) {
      final Offset toolsPosition = toolsBox.localToGlobal(Offset.zero);
      final Size toolsSize = toolsBox.size;
      final Rect toolsRect = Rect.fromLTWH(
        toolsPosition.dx,
        toolsPosition.dy,
        toolsSize.width,
        toolsSize.height,
      );
      if (toolsRect.contains(globalPosition)) {
        return false; // Click is inside tools button
      }
    }

    return true; // Click is outside both panel and tools button
  }

  @override
  Widget build(BuildContext context) {
    bool anyEnabled = widget.isWebSearchEnabled || widget.isImageGenEnabled;
    return _buildToolsChip(context, anyEnabled);
  }

  /// Builds the dropdown panel widget
  Widget _buildPanelWidget(List<_CapabilityConfig> caps, double itemHeightFactor) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        alignment: Alignment.bottomLeft,
        child: Material(
          key: _panelKey,
          elevation: 4,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(maxHeight: 30.h, maxWidth: 50.w),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < caps.length; i++) ...[
                  _buildMenuItem(context, caps[i], itemHeightFactor),
                  if (i != caps.length - 1) const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the pill-shaped "Tools" chip button that toggles the dropdown
  Widget _buildToolsChip(BuildContext context, bool anyEnabled) {
    return GestureDetector(
      onTap: _toggleExpansion,
      child: Container(
        key: _toolsButtonKey,
        height: widget.iconSize,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: anyEnabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
          borderRadius: BorderRadius.circular(widget.iconSize / 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction,
              size: widget.iconSize * 0.55,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              'Tools',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: widget.iconSize * 0.33,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single menu item row in the dropdown
  Widget _buildMenuItem(BuildContext context, _CapabilityConfig config, double heightFactor) {
    final bool isEnabled = config.isOn();

    void handleToggle() {
      config.toggle();
      _backdropEntry?.markNeedsBuild();
    }

    return InkWell(
      onTap: handleToggle,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: widget.iconSize * heightFactor,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        child: Row(
          children: [
            Icon(
              config.icon,
              size: widget.iconSize * 0.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AutoSizeText(
                config.label,
                maxLines: 2,
                minFontSize: 8,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            Transform.scale(
              scale: 0.7, // Scale down the switch to match text size
              child: Switch.adaptive(
                value: isEnabled,
                onChanged: (_) => handleToggle(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: Theme.of(context).colorScheme.primary,
                activeTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                inactiveThumbColor: Theme.of(context).colorScheme.outline,
                inactiveTrackColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper class to bundle capability data
}

class _CapabilityConfig {
  final IconData icon;
  final String label;
  final bool Function() isOn;
  final VoidCallback toggle;

  _CapabilityConfig({
    required this.icon,
    required this.label,
    required this.isOn,
    required this.toggle,
  });
}
