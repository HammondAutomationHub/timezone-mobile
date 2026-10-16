import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A line of text that ellipsizes inside a tight width and does not impose
/// its own min-content width. Desktop Chrome and Edge use that min-content
/// width as the smallest size a dragged app window can reach.
class EllipsisLine extends StatelessWidget {
  const EllipsisLine({
    required this.text,
    required this.style,
    this.maxLines = 1,
    super.key,
  });

  final String text;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return _ZeroMinWidth(
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        softWrap: maxLines > 1,
        style: style,
      ),
    );
  }
}

class _ZeroMinWidth extends SingleChildRenderObjectWidget {
  const _ZeroMinWidth({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderZeroMinWidth();
}

class _RenderZeroMinWidth extends RenderProxyBox {
  @override
  double computeMinIntrinsicWidth(double height) => 0;
}
