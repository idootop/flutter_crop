import 'package:crop/src/geometry_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CropRenderObjectWidget extends SingleChildRenderObjectWidget {
  @override
  final Key key;
  final double aspectRatio;
  final Color dimColor;
  final Color backgroundColor;
  final BoxShape shape;
  final EdgeInsetsGeometry padding;
  CropRenderObjectWidget({
    @required Widget child,
    @required this.aspectRatio,
    @required this.shape,
    this.key,
    this.padding,
    this.backgroundColor = Colors.black,
    this.dimColor = const Color.fromRGBO(0, 0, 0, 0.8),
  }) : super(key: key, child: child);
  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderCrop()
      ..aspectRatio = aspectRatio
      ..dimColor = dimColor
      ..backgroundColor = backgroundColor
      ..shape = shape
      ..padding = padding;
  }

  @override
  void updateRenderObject(BuildContext context, RenderCrop renderObject) {
    if (renderObject == null) return;

    var needsPaint = false;
    var needsLayout = false;

    if (renderObject.aspectRatio != aspectRatio) {
      renderObject.aspectRatio = aspectRatio;
      needsLayout = true;
    }

    if (renderObject.dimColor != dimColor) {
      renderObject.dimColor = dimColor;
      needsPaint = true;
    }

    if (renderObject.shape != shape) {
      renderObject.shape = shape;
      needsPaint = true;
    }

    if (renderObject.backgroundColor != backgroundColor) {
      renderObject.backgroundColor = backgroundColor;
      needsPaint = true;
    }

    if (needsLayout) {
      renderObject.markNeedsLayout();
    }
    if (needsPaint) {
      renderObject.markNeedsPaint();
    }

    super.updateRenderObject(context, renderObject);
  }
}

class RenderCrop extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  double aspectRatio;
  Color dimColor;
  Color backgroundColor;
  BoxShape shape;
  EdgeInsetsGeometry padding;

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  void performLayout() {
    final constraints = this.constraints;
    size = constraints.biggest;

    if (child != null) {
      final forcedSize =
          getSizeToFitByRatio(aspectRatio, size.width, size.height);
      child.layout(BoxConstraints.tight(forcedSize), parentUsesSize: true);
    }
  }

  Path _getDimClipPath() {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final forcedSize =
        getSizeToFitByRatio(aspectRatio, size.width, size.height);
    var rect = Rect.fromCenter(
      center: center,
      width: forcedSize.width - padding.horizontal,
      height: forcedSize.height - padding.vertical,
    );

    final path = Path();
    if (shape == BoxShape.circle) {
      path.addOval(rect);
    } else if (shape == BoxShape.rectangle) {
      path.addRect(rect);
    }

    path.addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height));
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {}

  @override
  void paint(PaintingContext context, Offset offset) {
    final bounds = offset & size;

    if (backgroundColor != null) {
      context.canvas.drawRect(bounds, Paint()..color = backgroundColor);
    }

    final forcedSize =
        getSizeToFitByRatio(aspectRatio, size.width, size.height);

    if (child != null) {
      final Offset tmp = size - forcedSize;
      context.paintChild(child, offset + tmp / 2);

      final clipPath = _getDimClipPath();

      context.pushClipPath(
        needsCompositing,
        offset,
        bounds,
        clipPath,
        (context, offset) {
          context.canvas.drawRect(bounds, Paint()..color = dimColor);
        },
      );
    }
  }
}
