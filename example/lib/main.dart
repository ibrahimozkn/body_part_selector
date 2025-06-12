import 'package:body_part_selector/body_part_selector.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// A custom German configuration for the pain scale.
const WongBakerScale germanPainScale = WongBakerScale(
  painIndicatorText: "Schmerzlevel",
  dialogTitle: 'Schmerzlevel auswählen',
  okButton: 'OK',
  cancelButton: 'Abbrechen',
  levels: {
    0: PainLevelStyle(
        face: '😄', description: 'Kein Schmerz', color: Color(0xFF4CAF50)),
    1: PainLevelStyle(
        face: '🙂',
        description: 'Tut nicht weh',
        color: Color(0xFFCDDC39),
        textColor: Colors.black87),
    2: PainLevelStyle(
        face: '😊',
        description: 'Tut ein bisschen weh',
        color: Color(0xFF8BC34A)),
    4: PainLevelStyle(
        face: '😐',
        description: 'Tut etwas mehr weh',
        color: Color(0xFFFFEB3B),
        textColor: Colors.black87),
    6: PainLevelStyle(
        face: '😕', description: 'Tut noch mehr weh', color: Color(0xFFFF9800)),
    8: PainLevelStyle(
        face: '😢', description: 'Tut sehr weh', color: Color(0xFFF44336)),
    10: PainLevelStyle(
        face: '😭', description: 'Stärkster Schmerz', color: Color(0xFFB71C1C)),
  },
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Body Part Selector Example',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const MyHomePage(title: 'Pain Selector Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({required this.title, super.key});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BodyParts _bodyParts = const BodyParts();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Container(
          width: 400,
          child: BodyPartSelectorTurnable(
            frontButtonIcon: const Icon(Icons.face),
            backButtonIcon: const Icon(Icons.face_retouching_natural),
            bodyParts: _bodyParts,
            // Pass the custom German scale to the widget.
            onPainChanged: (partId, painLevel) {
              setState(() {
                _bodyParts = _bodyParts.withPainLevel(partId, painLevel);
              });
            },
          ),
        ),
      ),
    );
  }
}
