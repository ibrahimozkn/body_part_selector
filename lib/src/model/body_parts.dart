import 'package:freezed_annotation/freezed_annotation.dart';

part 'body_parts.freezed.dart';
part 'body_parts.g.dart';

/// A class representing the different parts of the body and their associated
/// pain level, with distinctions for front and back.
@freezed
abstract class BodyParts with _$BodyParts {
  /// The maximum pain level that can be assigned to a body part.
  static const maxPainLevel = 10;

  const factory BodyParts({
    // Parts with front and back distinction
    @Default(0) int headFront,
    @Default(0) int headBack,
    @Default(0) int neckFront,
    @Default(0) int neckBack,
    @Default(0) int chest, // Replaces upperBody front
    @Default(0) int upperBack, // Replaces upperBody back
    @Default(0) int abdomen, // Front only
    @Default(0) int lowerBack, // Back only

    // Limbs and other parts (can also be split if needed)
    @Default(0) int leftShoulder,
    @Default(0) int leftUpperArm,
    @Default(0) int leftElbow,
    @Default(0) int leftLowerArm,
    @Default(0) int leftHand,
    @Default(0) int rightShoulder,
    @Default(0) int rightUpperArm,
    @Default(0) int rightElbow,
    @Default(0) int rightLowerArm,
    @Default(0) int rightHand,
    @Default(0) int pelvis, // Front of lowerBody
    @Default(0) int buttocks, // Back of lowerBody
    @Default(0) int leftUpperLeg,
    @Default(0) int leftKnee,
    @Default(0) int leftLowerLeg,
    @Default(0) int leftFoot,
    @Default(0) int rightUpperLeg,
    @Default(0) int rightKnee,
    @Default(0) int rightLowerLeg,
    @Default(0) int rightFoot,
    @Default(0) int vestibular,
  }) = _BodyParts;

  /// Creates a new [BodyParts] object from a JSON object.
  factory BodyParts.fromJson(Map<String, dynamic> json) =>
      _$BodyPartsFromJson(json);
  const BodyParts._();

  /// Returns a new [BodyParts] object with the pain level for the given [id]
  /// updated.
  BodyParts withPainLevel(String id, int painLevel) {
    final map = toMap();
    if (!map.containsKey(id)) return this;
    map[id] = painLevel.clamp(0, maxPainLevel);
    return BodyParts.fromJson(map);
  }

  /// Returns a Map representation of this object.
  Map<String, int> toMap() {
    return toJson().cast();
  }

  /// Returns a list of the names of body parts that have a pain level
  /// greater than 0.
  List<String> get painfulParts {
    return toMap().entries.where((e) => e.value > 0).map((e) => e.key).toList();
  }
}
