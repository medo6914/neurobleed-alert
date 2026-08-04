import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

enum LoadingSize { small, medium, large }

class AppLoading extends StatelessWidget {
  final String? message;
  final bool fullscreen;
  final LoadingSize size;

  const AppLoading({
    super.key,
    this.message,
    this.fullscreen = false,
    this.size = LoadingSize.medium,
  });

  double get _indicatorSize {
    switch (size) {
      case LoadingSize.small:
        return 20;
      case LoadingSize.medium:
        return 36;
      case LoadingSize.large:
        return 48;
    }
  }

  @override
  Widget build(BuildContext context) {
    final indicator = Semantics(
      label: 'Loading',
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: const AlwaysStoppedAnimation<Color>(NeuroColors.primary),
        strokeAlign: CircularProgressIndicator.strokeAlignInside,
      ),
    );

    if (!fullscreen) {
      if (message != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: _indicatorSize,
                height: _indicatorSize,
                child: indicator,
              ),
              const SizedBox(height: NeuroSpacing.md),
              Text(
                message!,
                style: NeuroTypography.textTheme.bodyMedium?.copyWith(
                  color: NeuroColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }
      return Center(
        child: SizedBox(
          width: _indicatorSize,
          height: _indicatorSize,
          child: indicator,
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black54,
        body: Center(
          child: Semantics(
            label: 'Loading',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: _indicatorSize,
                  height: _indicatorSize,
                  child: indicator,
                ),
                if (message != null) ...[
                  const SizedBox(height: NeuroSpacing.lg),
                  Text(
                    message!,
                    style: NeuroTypography.textTheme.bodyMedium?.copyWith(
                      color: NeuroColors.textOnPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppShimmerLoading extends StatefulWidget {
  final Widget Function(BuildContext) childBuilder;
  final int itemCount;
  final Axis scrollDirection;
  final double? height;

  const AppShimmerLoading({
    super.key,
    required this.childBuilder,
    this.itemCount = 4,
    this.scrollDirection = Axis.vertical,
    this.height,
  });

  @override
  State<AppShimmerLoading> createState() => _AppShimmerLoadingState();
}

class _AppShimmerLoadingState extends State<AppShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? NeuroColors.bgElevated
        : NeuroColors.chartGrid;
    final highlightColor = isDark
        ? NeuroColors.primaryGlass
        : NeuroColors.chartFill;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform:
                  GradientSliding(_animation.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcOver,
          child: ListView.separated(
            scrollDirection: widget.scrollDirection,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.itemCount,
            shrinkWrap: true,
            separatorBuilder: (_, __) => SizedBox(
              height: widget.scrollDirection == Axis.vertical
                  ? NeuroSpacing.sm
                  : 0,
              width: widget.scrollDirection == Axis.horizontal
                  ? NeuroSpacing.sm
                  : 0,
            ),
            itemBuilder: (context, index) {
              return Container(
                height: widget.height,
                child: widget.childBuilder(context),
              );
            },
          ),
        );
      },
    );
  }
}

class GradientSliding extends GradientTransform {
  final double value;
  const GradientSliding(this.value);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * value, 0, 0);
  }
}
