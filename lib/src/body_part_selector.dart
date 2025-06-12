import 'dart:math';

import 'package:body_part_selector/src/model/body_parts.dart';
import 'package:body_part_selector/src/model/body_side.dart';
import 'package:body_part_selector/src/service/svg_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:touchable/touchable.dart';

/// Defines the style for a single level on the Wong-Baker pain scale.
@immutable
class PainLevelStyle {
  const PainLevelStyle({
    required this.face,
    required this.description,
    required this.color,
    this.textColor = Colors.white,
  });

  /// The emoji representing the pain level.
  final String face;

  /// The text description for the pain level.
  final String description;

  /// The background color for this pain level.
  final Color color;

  /// The text color to be used on top of the background color.
  final Color textColor;
}

/// Configuration for the Wong-Baker FACES® Pain Rating Scale.
///
/// This class allows for full customization of the text and styles used in
/// the [PainLevelDialog].
@immutable
class WongBakerScale {
  const WongBakerScale({
    required this.dialogTitle,
    required this.painIndicatorText,
    required this.okButton,
    required this.cancelButton,
    required this.levels,
  });

  /// The title of the pain selection dialog.
  final String dialogTitle;

  /// The text prefix for the pain level display (e.g., "Pain").
  final String painIndicatorText;

  /// The text for the 'OK' button in the dialog.
  final String okButton;

  /// The text for the 'Cancel' button in the dialog.
  final String cancelButton;

  /// A map of pain values (0-10) to their corresponding styles.
  final Map<int, PainLevelStyle> levels;

  /// Default English configuration for the Wong-Baker scale with 6 standard levels.
  static const WongBakerScale english = WongBakerScale(
    dialogTitle: 'Select Pain Level',
    painIndicatorText: 'Pain',
    okButton: 'OK',
    cancelButton: 'Cancel',
    levels: {
      0: PainLevelStyle(
          face: '😄', description: 'No Hurt', color: Color(0xFF4CAF50)),
      2: PainLevelStyle(
          face: '😊',
          description: 'Hurts Little Bit',
          color: Color(0xFFFFCC80),
          textColor: Colors.black87),
      4: PainLevelStyle(
          face: '😐',
          description: 'Hurts Little More',
          color: Color(0xFFFFA726),
          textColor: Colors.black87),
      6: PainLevelStyle(
          face: '😕', description: 'Hurts Even More', color: Color(0xFFFF7043)),
      8: PainLevelStyle(
          face: '😢', description: 'Hurts Whole Lot', color: Color(0xFFF44336)),
      10: PainLevelStyle(
          face: '😭', description: 'Hurts Worst', color: Color(0xFFB71C1C)),
    },
  );
}

/// A widget that allows for selecting body parts and displays their pain level.
/// When a body part is tapped, a dialog is shown to select the pain level.
class BodyPartSelector extends StatelessWidget {
  /// Creates a [BodyPartSelector].
  const BodyPartSelector({
    required this.bodyParts,
    required this.side,
    this.onPainChanged,
    this.scale = WongBakerScale.english,
    this.unselectedColor,
    this.unselectedOutlineColor,
    super.key,
  });

  final BodyParts bodyParts;
  final BodySide side;
  final void Function(String bodyPartId, int painLevel)? onPainChanged;
  final WongBakerScale scale;
  final Color? unselectedColor;
  final Color? unselectedOutlineColor;

  void _showPainSelectorDialog(
      BuildContext context, String partId, int currentPain) async {
    final selectedPain = await showDialog<int>(
      context: context,
      builder: (context) =>
          PainLevelDialog(initialPain: currentPain, scale: scale),
    );

    if (selectedPain != null) {
      onPainChanged?.call(partId, selectedPain);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = SvgService.instance.getSide(side);
    return ValueListenableBuilder<DrawableRoot?>(
      valueListenable: notifier,
      builder: (context, value, _) {
        if (value == null) {
          return const Center(child: CircularProgressIndicator.adaptive());
        } else {
          return _buildBody(context, value);
        }
      },
    );
  }

  Widget _buildBody(BuildContext context, DrawableRoot drawable) {
    return AnimatedSwitcher(
      duration: kThemeAnimationDuration,
      child: SizedBox.expand(
        key: ValueKey(Object.hash(bodyParts, side)),
        child: CanvasTouchDetector(
          gesturesToOverride: const [GestureType.onTapDown],
          builder: (context) => CustomPaint(
            painter: _BodyPainter(
              root: drawable,
              bodyParts: bodyParts,
              onTap: (id) {
                final currentPain = bodyParts.toMap()[id] ?? 0;
                _showPainSelectorDialog(context, id, currentPain);
              },
              context: context,
              scale: scale,
              unselectedColor: unselectedColor ??
                  Theme.of(context).colorScheme.surfaceVariant,
              unselectedOutlineColor: unselectedOutlineColor ??
                  Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.root,
    required this.bodyParts,
    required this.onTap,
    required this.context,
    required this.scale,
    required this.unselectedColor,
    required this.unselectedOutlineColor,
  });

  final DrawableRoot root;
  final BuildContext context;
  final void Function(String) onTap;
  final BodyParts bodyParts;
  final WongBakerScale scale;
  final Color unselectedColor;
  final Color unselectedOutlineColor;

  int getPainLevel(String key) => bodyParts.toMap()[key] ?? 0;

  ({Color fill, Color stroke}) _getPainColors(int painLevel) {
    // If there is no pain, use the unselected colors.
    if (painLevel == 0) {
      return (fill: unselectedColor, stroke: unselectedOutlineColor);
    }

    // Get the scale points, excluding 0, to start the gradient from the first pain level.
    final scalePoints = scale.levels.keys.where((p) => p > 0).toList()..sort();

    // If there are no painful levels defined, default to a selected color.
    if (scalePoints.isEmpty) {
      return (fill: Colors.red, stroke: Colors.white);
    }

    // Find the first level of pain to start the gradient.
    final firstPainPoint = scalePoints.first;

    // If the pain is at or above the highest defined level, use that level's style.
    if (painLevel >= scalePoints.last) {
      final style = scale.levels[scalePoints.last]!;
      return (fill: style.color, stroke: style.textColor);
    }

    // Determine the lower and upper bounds for interpolation.
    final lowerBound = scalePoints.lastWhere((p) => p <= painLevel,
        orElse: () => firstPainPoint);
    final upperBound =
        scalePoints.firstWhere((p) => p >= painLevel, orElse: () => lowerBound);

    if (lowerBound == upperBound) {
      final style = scale.levels[lowerBound]!;
      return (fill: style.color, stroke: style.textColor);
    }

    final lowerStyle = scale.levels[lowerBound]!;
    final upperStyle = scale.levels[upperBound]!;

    // Calculate the interpolation factor (t).
    final t = (painLevel - lowerBound) / (upperBound - lowerBound);

    final fillColor = Color.lerp(lowerStyle.color, upperStyle.color, t)!;
    final strokeColor =
        Color.lerp(lowerStyle.textColor, upperStyle.textColor, t)!;

    return (fill: fillColor, stroke: strokeColor);
  }

  void drawBodyParts({
    required TouchyCanvas touchyCanvas,
    required Canvas plainCanvas,
    required Size size,
    required Iterable<Drawable> drawables,
    required Matrix4 fittingMatrix,
  }) {
    for (final element in drawables) {
      final id = element.id;
      if (id == null || element is! DrawableShape) continue;
      final painLevel = getPainLevel(id);
      final colors = _getPainColors(painLevel);
      final bodyPartPath = element.path.transform(fittingMatrix.storage);
      touchyCanvas.drawPath(
        bodyPartPath,
        Paint()
          ..color = colors.fill
          ..style = PaintingStyle.fill,
        onTapDown: (_) => onTap(id),
      );
      plainCanvas.drawPath(
        bodyPartPath,
        Paint()
          ..color = colors.stroke
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = min(
      size.width / root.viewport.viewBoxRect.width,
      size.height / root.viewport.viewBoxRect.height,
    );
    final scaledHalfViewBoxSize = root.viewport.viewBoxRect.size * scale / 2.0;
    final halfDesiredSize = size / 2.0;
    final shift = Offset(
      halfDesiredSize.width - scaledHalfViewBoxSize.width,
      halfDesiredSize.height - scaledHalfViewBoxSize.height,
    );
    final fittingMatrix = Matrix4.identity()
      ..translate(shift.dx, shift.dy)
      ..scale(scale);
    final bodyPartsCanvas = TouchyCanvas(context, canvas);
    final drawables =
        root.children.where((element) => element.hasDrawableContent);
    drawBodyParts(
      touchyCanvas: bodyPartsCanvas,
      plainCanvas: canvas,
      size: size,
      drawables: drawables,
      fittingMatrix: fittingMatrix,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// A dialog widget that allows users to select a pain level using a
/// configurable scale.
class PainLevelDialog extends StatefulWidget {
  const PainLevelDialog({
    required this.initialPain,
    required this.scale,
    super.key,
  });

  final int initialPain;
  final WongBakerScale scale;

  @override
  State<PainLevelDialog> createState() => _PainLevelDialogState();
}

class _PainLevelDialogState extends State<PainLevelDialog> {
  late int _currentPain;

  @override
  void initState() {
    super.initState();
    _currentPain = widget.initialPain;
  }

  @override
  Widget build(BuildContext context) {
    final scalePoints = widget.scale.levels.keys.toList()..sort();
    int painLevelKey;

    if (_currentPain == 0) {
      painLevelKey = scalePoints.contains(0) ? 0 : scalePoints.first;
    } else {
      painLevelKey = scalePoints.firstWhere((p) => p >= _currentPain,
          orElse: () => scalePoints.last);
    }

    final painInfo = widget.scale.levels[painLevelKey]!;

    return AlertDialog(
      title: Text(widget.scale.dialogTitle),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20)
          .copyWith(top: 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: painInfo.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(painInfo.face, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 8),
                Text(
                  painInfo.description,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: painInfo.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${widget.scale.painIndicatorText}: $_currentPain',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: painInfo.textColor.withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Slider(
                value: _currentPain.toDouble(),
                min: 0,
                max: BodyParts.maxPainLevel.toDouble(),
                divisions: BodyParts.maxPainLevel,
                label: _currentPain.toString(),
                onChanged: (value) {
                  setState(() {
                    _currentPain = value.round();
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    11,
                    (index) => Text(
                      index.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.scale.cancelButton),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_currentPain),
          child: Text(widget.scale.okButton),
        ),
      ],
    );
  }
}
