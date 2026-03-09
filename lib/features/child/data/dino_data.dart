import 'package:flutter/material.dart';

/// The 10 starter dinosaurs. More can be unlocked with coins later.
enum DinoType {
  trex('T-Rex', '🦖'),
  bronto('Bronto', '🦕'),
  stego('Stego', '🔶'),
  trice('Triceratops', '🛡️'),
  raptor('Raptor', '⚡'),
  ptero('Pterodactyl', '🪽'),
  ankylo('Ankylo', '🪨'),
  diplo('Diplo', '🌿'),
  spino('Spino', '🌊'),
  parasaur('Parasaur', '🎵');

  final String displayName;
  final String badgeEmoji;
  const DinoType(this.displayName, this.badgeEmoji);
}

/// The 5 base colours for every dino.
enum DinoColor {
  green('Green', Color(0xFF4CAF50), Color(0xFF388E3C)),
  purple('Purple', Color(0xFF9C27B0), Color(0xFF7B1FA2)),
  blue('Blue', Color(0xFF2196F3), Color(0xFF1976D2)),
  red('Red', Color(0xFFF44336), Color(0xFFD32F2F)),
  orange('Orange', Color(0xFFFF9800), Color(0xFFF57C00));

  final String displayName;
  final Color color;
  final Color darkShade;
  const DinoColor(this.displayName, this.color, this.darkShade);
}

/// Widget that renders a dinosaur using simple custom painting.
class DinoAvatar extends StatelessWidget {
  const DinoAvatar({
    super.key,
    required this.type,
    required this.color,
    this.size = 100,
  });

  final DinoType type;
  final DinoColor color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DinoPainter(type: type, dinoColor: color),
      ),
    );
  }
}

class _DinoPainter extends CustomPainter {
  final DinoType type;
  final DinoColor dinoColor;

  _DinoPainter({required this.type, required this.dinoColor});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()..color = dinoColor.color;
    final darkPaint = Paint()..color = dinoColor.darkShade;
    final eyeWhite = Paint()..color = Colors.white;
    final eyePupil = Paint()..color = Colors.black;
    final s = size.width;

    switch (type) {
      case DinoType.trex:
        _drawTRex(canvas, s, bodyPaint, darkPaint, eyeWhite, eyePupil);
      case DinoType.bronto:
        _drawBronto(canvas, s, bodyPaint, darkPaint, eyeWhite, eyePupil);
      case DinoType.stego:
        _drawStego(canvas, s, bodyPaint, darkPaint, eyeWhite, eyePupil);
      case DinoType.trice:
        _drawTrice(canvas, s, bodyPaint, darkPaint, eyeWhite, eyePupil);
      case DinoType.raptor:
        _drawRaptor(canvas, s, bodyPaint, darkPaint, eyeWhite, eyePupil);
      case DinoType.ptero:
        _drawPtero(canvas, s, bodyPaint, darkPaint, eyeWhite, eyePupil);
      case DinoType.ankylo:
        _drawAnkylo(canvas, s, bodyPaint, darkPaint, eyeWhite, eyePupil);
      case DinoType.diplo:
        _drawDiplo(canvas, s, bodyPaint, darkPaint, eyeWhite, eyePupil);
      case DinoType.spino:
        _drawSpino(canvas, s, bodyPaint, darkPaint, eyeWhite, eyePupil);
      case DinoType.parasaur:
        _drawParasaur(canvas, s, bodyPaint, darkPaint, eyeWhite, eyePupil);
    }
  }

  // ── T-Rex: big head, tiny arms, stocky body ──────────────────────────
  void _drawTRex(Canvas c, double s, Paint body, Paint dark, Paint ew, Paint ep) {
    // Body
    c.drawOval(Rect.fromLTWH(s * 0.15, s * 0.35, s * 0.5, s * 0.4), body);
    // Head
    c.drawOval(Rect.fromLTWH(s * 0.45, s * 0.1, s * 0.4, s * 0.35), body);
    // Jaw
    c.drawOval(Rect.fromLTWH(s * 0.55, s * 0.3, s * 0.35, s * 0.15), dark);
    // Eye
    c.drawCircle(Offset(s * 0.7, s * 0.22), s * 0.06, ew);
    c.drawCircle(Offset(s * 0.72, s * 0.22), s * 0.03, ep);
    // Tiny arms
    c.drawRect(Rect.fromLTWH(s * 0.48, s * 0.42, s * 0.08, s * 0.12), dark);
    // Legs
    c.drawRect(Rect.fromLTWH(s * 0.22, s * 0.68, s * 0.12, s * 0.2), body);
    c.drawRect(Rect.fromLTWH(s * 0.42, s * 0.68, s * 0.12, s * 0.2), body);
    // Feet
    c.drawOval(Rect.fromLTWH(s * 0.18, s * 0.84, s * 0.18, s * 0.08), dark);
    c.drawOval(Rect.fromLTWH(s * 0.38, s * 0.84, s * 0.18, s * 0.08), dark);
    // Tail
    final tail = Path()
      ..moveTo(s * 0.15, s * 0.45)
      ..quadraticBezierTo(s * 0.0, s * 0.35, s * 0.02, s * 0.55)
      ..lineTo(s * 0.15, s * 0.55);
    c.drawPath(tail, body);
  }

  // ── Bronto: long neck, small head, round body ────────────────────────
  void _drawBronto(Canvas c, double s, Paint body, Paint dark, Paint ew, Paint ep) {
    // Body
    c.drawOval(Rect.fromLTWH(s * 0.2, s * 0.45, s * 0.55, s * 0.35), body);
    // Neck
    c.drawRect(Rect.fromLTWH(s * 0.55, s * 0.1, s * 0.12, s * 0.4), body);
    // Head
    c.drawOval(Rect.fromLTWH(s * 0.48, s * 0.05, s * 0.28, s * 0.16), body);
    // Eye
    c.drawCircle(Offset(s * 0.68, s * 0.11), s * 0.04, ew);
    c.drawCircle(Offset(s * 0.69, s * 0.11), s * 0.02, ep);
    // Legs
    c.drawRect(Rect.fromLTWH(s * 0.25, s * 0.72, s * 0.1, s * 0.18), body);
    c.drawRect(Rect.fromLTWH(s * 0.55, s * 0.72, s * 0.1, s * 0.18), body);
    c.drawOval(Rect.fromLTWH(s * 0.22, s * 0.87, s * 0.14, s * 0.06), dark);
    c.drawOval(Rect.fromLTWH(s * 0.52, s * 0.87, s * 0.14, s * 0.06), dark);
    // Tail
    final tail = Path()
      ..moveTo(s * 0.2, s * 0.55)
      ..quadraticBezierTo(s * 0.02, s * 0.5, s * 0.05, s * 0.65)
      ..lineTo(s * 0.2, s * 0.6);
    c.drawPath(tail, body);
  }

  // ── Stego: plates on back ────────────────────────────────────────────
  void _drawStego(Canvas c, double s, Paint body, Paint dark, Paint ew, Paint ep) {
    // Body
    c.drawOval(Rect.fromLTWH(s * 0.15, s * 0.4, s * 0.55, s * 0.35), body);
    // Head
    c.drawOval(Rect.fromLTWH(s * 0.6, s * 0.32, s * 0.28, s * 0.2), body);
    c.drawCircle(Offset(s * 0.78, s * 0.38), s * 0.04, ew);
    c.drawCircle(Offset(s * 0.79, s * 0.38), s * 0.02, ep);
    // Plates
    for (var i = 0; i < 5; i++) {
      final x = s * (0.25 + i * 0.1);
      final plateH = s * (0.08 + (i == 2 ? 0.06 : 0.0));
      final plate = Path()
        ..moveTo(x, s * 0.4)
        ..lineTo(x + s * 0.04, s * 0.4 - plateH)
        ..lineTo(x + s * 0.08, s * 0.4);
      c.drawPath(plate, dark);
    }
    // Legs
    c.drawRect(Rect.fromLTWH(s * 0.22, s * 0.68, s * 0.1, s * 0.18), body);
    c.drawRect(Rect.fromLTWH(s * 0.52, s * 0.68, s * 0.1, s * 0.18), body);
    c.drawOval(Rect.fromLTWH(s * 0.19, s * 0.83, s * 0.14, s * 0.06), dark);
    c.drawOval(Rect.fromLTWH(s * 0.49, s * 0.83, s * 0.14, s * 0.06), dark);
    // Tail spikes
    final tail = Path()
      ..moveTo(s * 0.15, s * 0.5)
      ..lineTo(s * 0.02, s * 0.4)
      ..lineTo(s * 0.08, s * 0.48)
      ..lineTo(s * 0.0, s * 0.52)
      ..lineTo(s * 0.15, s * 0.55);
    c.drawPath(tail, dark);
  }

  // ── Triceratops: frill + horns ───────────────────────────────────────
  void _drawTrice(Canvas c, double s, Paint body, Paint dark, Paint ew, Paint ep) {
    // Body
    c.drawOval(Rect.fromLTWH(s * 0.1, s * 0.4, s * 0.5, s * 0.35), body);
    // Frill
    c.drawOval(Rect.fromLTWH(s * 0.5, s * 0.12, s * 0.35, s * 0.3), dark);
    // Head
    c.drawOval(Rect.fromLTWH(s * 0.55, s * 0.2, s * 0.32, s * 0.28), body);
    // Horns
    c.drawRect(Rect.fromLTWH(s * 0.68, s * 0.12, s * 0.03, s * 0.12), dark);
    c.drawRect(Rect.fromLTWH(s * 0.78, s * 0.14, s * 0.03, s * 0.1), dark);
    // Nose horn
    c.drawRect(Rect.fromLTWH(s * 0.85, s * 0.32, s * 0.08, s * 0.03), dark);
    // Eye
    c.drawCircle(Offset(s * 0.74, s * 0.3), s * 0.04, ew);
    c.drawCircle(Offset(s * 0.75, s * 0.3), s * 0.02, ep);
    // Legs
    c.drawRect(Rect.fromLTWH(s * 0.16, s * 0.68, s * 0.1, s * 0.18), body);
    c.drawRect(Rect.fromLTWH(s * 0.42, s * 0.68, s * 0.1, s * 0.18), body);
    c.drawOval(Rect.fromLTWH(s * 0.13, s * 0.83, s * 0.14, s * 0.06), dark);
    c.drawOval(Rect.fromLTWH(s * 0.39, s * 0.83, s * 0.14, s * 0.06), dark);
    // Tail
    final tail = Path()
      ..moveTo(s * 0.1, s * 0.5)
      ..quadraticBezierTo(s * 0.0, s * 0.42, s * 0.02, s * 0.58)
      ..lineTo(s * 0.1, s * 0.55);
    c.drawPath(tail, body);
  }

  // ── Raptor: sleek, leaning forward ────────────────────────────────────
  void _drawRaptor(Canvas c, double s, Paint body, Paint dark, Paint ew, Paint ep) {
    c.drawOval(Rect.fromLTWH(s * 0.2, s * 0.35, s * 0.4, s * 0.3), body);
    c.drawOval(Rect.fromLTWH(s * 0.5, s * 0.12, s * 0.3, s * 0.22), body);
    c.drawCircle(Offset(s * 0.7, s * 0.2), s * 0.04, ew);
    c.drawCircle(Offset(s * 0.71, s * 0.2), s * 0.02, ep);
    // Claws
    c.drawRect(Rect.fromLTWH(s * 0.52, s * 0.32, s * 0.06, s * 0.1), dark);
    // Legs
    c.drawRect(Rect.fromLTWH(s * 0.28, s * 0.6, s * 0.08, s * 0.24), body);
    c.drawRect(Rect.fromLTWH(s * 0.44, s * 0.6, s * 0.08, s * 0.24), body);
    c.drawOval(Rect.fromLTWH(s * 0.25, s * 0.82, s * 0.14, s * 0.06), dark);
    c.drawOval(Rect.fromLTWH(s * 0.41, s * 0.82, s * 0.14, s * 0.06), dark);
    // Tail
    final tail = Path()
      ..moveTo(s * 0.2, s * 0.42)
      ..quadraticBezierTo(s * 0.0, s * 0.28, s * 0.04, s * 0.5)
      ..lineTo(s * 0.2, s * 0.5);
    c.drawPath(tail, body);
  }

  // ── Pterodactyl: wings ────────────────────────────────────────────────
  void _drawPtero(Canvas c, double s, Paint body, Paint dark, Paint ew, Paint ep) {
    c.drawOval(Rect.fromLTWH(s * 0.3, s * 0.35, s * 0.3, s * 0.2), body);
    // Head with crest
    c.drawOval(Rect.fromLTWH(s * 0.5, s * 0.22, s * 0.25, s * 0.16), body);
    final crest = Path()
      ..moveTo(s * 0.55, s * 0.24)
      ..lineTo(s * 0.45, s * 0.12)
      ..lineTo(s * 0.6, s * 0.22);
    c.drawPath(crest, dark);
    // Beak
    c.drawRect(Rect.fromLTWH(s * 0.72, s * 0.3, s * 0.15, s * 0.04), dark);
    c.drawCircle(Offset(s * 0.68, s * 0.28), s * 0.03, ew);
    c.drawCircle(Offset(s * 0.69, s * 0.28), s * 0.015, ep);
    // Wings
    final wingL = Path()
      ..moveTo(s * 0.3, s * 0.4)
      ..quadraticBezierTo(s * 0.0, s * 0.25, s * 0.05, s * 0.5)
      ..lineTo(s * 0.3, s * 0.45);
    c.drawPath(wingL, body);
    final wingR = Path()
      ..moveTo(s * 0.55, s * 0.38)
      ..quadraticBezierTo(s * 0.85, s * 0.2, s * 0.9, s * 0.45)
      ..lineTo(s * 0.55, s * 0.42);
    c.drawPath(wingR, body);
    // Feet
    c.drawRect(Rect.fromLTWH(s * 0.38, s * 0.52, s * 0.04, s * 0.12), body);
    c.drawRect(Rect.fromLTWH(s * 0.48, s * 0.52, s * 0.04, s * 0.12), body);
  }

  // ── Ankylosaurus: armoured, club tail ────────────────────────────────
  void _drawAnkylo(Canvas c, double s, Paint body, Paint dark, Paint ew, Paint ep) {
    c.drawOval(Rect.fromLTWH(s * 0.15, s * 0.35, s * 0.55, s * 0.35), body);
    // Armour bumps
    for (var i = 0; i < 4; i++) {
      c.drawCircle(Offset(s * (0.28 + i * 0.12), s * 0.38), s * 0.04, dark);
    }
    // Head
    c.drawOval(Rect.fromLTWH(s * 0.6, s * 0.3, s * 0.25, s * 0.2), body);
    c.drawCircle(Offset(s * 0.76, s * 0.37), s * 0.04, ew);
    c.drawCircle(Offset(s * 0.77, s * 0.37), s * 0.02, ep);
    // Legs (short & stubby)
    c.drawRect(Rect.fromLTWH(s * 0.22, s * 0.65, s * 0.12, s * 0.14), body);
    c.drawRect(Rect.fromLTWH(s * 0.52, s * 0.65, s * 0.12, s * 0.14), body);
    c.drawOval(Rect.fromLTWH(s * 0.19, s * 0.77, s * 0.16, s * 0.06), dark);
    c.drawOval(Rect.fromLTWH(s * 0.49, s * 0.77, s * 0.16, s * 0.06), dark);
    // Tail with club
    final tail = Path()
      ..moveTo(s * 0.15, s * 0.48)
      ..quadraticBezierTo(s * 0.0, s * 0.42, s * 0.03, s * 0.5)
      ..lineTo(s * 0.15, s * 0.52);
    c.drawPath(tail, body);
    c.drawCircle(Offset(s * 0.03, s * 0.48), s * 0.05, dark);
  }

  // ── Diplodocus: very long neck + tail ─────────────────────────────────
  void _drawDiplo(Canvas c, double s, Paint body, Paint dark, Paint ew, Paint ep) {
    c.drawOval(Rect.fromLTWH(s * 0.25, s * 0.45, s * 0.4, s * 0.28), body);
    // Long neck
    final neck = Path()
      ..moveTo(s * 0.55, s * 0.48)
      ..quadraticBezierTo(s * 0.7, s * 0.15, s * 0.82, s * 0.08)
      ..lineTo(s * 0.88, s * 0.12)
      ..quadraticBezierTo(s * 0.75, s * 0.22, s * 0.62, s * 0.5);
    c.drawPath(neck, body);
    // Head
    c.drawOval(Rect.fromLTWH(s * 0.76, s * 0.04, s * 0.16, s * 0.12), body);
    c.drawCircle(Offset(s * 0.88, s * 0.08), s * 0.03, ew);
    c.drawCircle(Offset(s * 0.89, s * 0.08), s * 0.015, ep);
    // Legs
    c.drawRect(Rect.fromLTWH(s * 0.3, s * 0.68, s * 0.08, s * 0.18), body);
    c.drawRect(Rect.fromLTWH(s * 0.5, s * 0.68, s * 0.08, s * 0.18), body);
    c.drawOval(Rect.fromLTWH(s * 0.27, s * 0.84, s * 0.12, s * 0.05), dark);
    c.drawOval(Rect.fromLTWH(s * 0.47, s * 0.84, s * 0.12, s * 0.05), dark);
    // Tail
    final tail = Path()
      ..moveTo(s * 0.25, s * 0.52)
      ..quadraticBezierTo(s * 0.05, s * 0.4, s * 0.02, s * 0.56)
      ..lineTo(s * 0.25, s * 0.58);
    c.drawPath(tail, body);
  }

  // ── Spinosaurus: sail on back ─────────────────────────────────────────
  void _drawSpino(Canvas c, double s, Paint body, Paint dark, Paint ew, Paint ep) {
    c.drawOval(Rect.fromLTWH(s * 0.15, s * 0.4, s * 0.5, s * 0.35), body);
    // Sail
    final sail = Path()
      ..moveTo(s * 0.2, s * 0.42)
      ..lineTo(s * 0.3, s * 0.1)
      ..lineTo(s * 0.5, s * 0.08)
      ..lineTo(s * 0.58, s * 0.4);
    c.drawPath(sail, dark);
    // Head (crocodile-like snout)
    c.drawOval(Rect.fromLTWH(s * 0.55, s * 0.25, s * 0.35, s * 0.2), body);
    c.drawRect(Rect.fromLTWH(s * 0.78, s * 0.35, s * 0.15, s * 0.06), dark);
    c.drawCircle(Offset(s * 0.72, s * 0.3), s * 0.04, ew);
    c.drawCircle(Offset(s * 0.73, s * 0.3), s * 0.02, ep);
    // Legs
    c.drawRect(Rect.fromLTWH(s * 0.22, s * 0.7, s * 0.1, s * 0.18), body);
    c.drawRect(Rect.fromLTWH(s * 0.48, s * 0.7, s * 0.1, s * 0.18), body);
    c.drawOval(Rect.fromLTWH(s * 0.19, s * 0.85, s * 0.14, s * 0.06), dark);
    c.drawOval(Rect.fromLTWH(s * 0.45, s * 0.85, s * 0.14, s * 0.06), dark);
    // Tail
    final tail = Path()
      ..moveTo(s * 0.15, s * 0.5)
      ..quadraticBezierTo(s * 0.0, s * 0.42, s * 0.03, s * 0.58)
      ..lineTo(s * 0.15, s * 0.56);
    c.drawPath(tail, body);
  }

  // ── Parasaurolophus: head crest ───────────────────────────────────────
  void _drawParasaur(Canvas c, double s, Paint body, Paint dark, Paint ew, Paint ep) {
    c.drawOval(Rect.fromLTWH(s * 0.15, s * 0.4, s * 0.5, s * 0.32), body);
    // Neck
    c.drawRect(Rect.fromLTWH(s * 0.55, s * 0.2, s * 0.1, s * 0.25), body);
    // Head
    c.drawOval(Rect.fromLTWH(s * 0.5, s * 0.12, s * 0.28, s * 0.18), body);
    // Crest
    final crest = Path()
      ..moveTo(s * 0.58, s * 0.14)
      ..lineTo(s * 0.4, s * 0.02)
      ..lineTo(s * 0.48, s * 0.12);
    c.drawPath(crest, dark);
    c.drawCircle(Offset(s * 0.7, s * 0.18), s * 0.04, ew);
    c.drawCircle(Offset(s * 0.71, s * 0.18), s * 0.02, ep);
    // Legs
    c.drawRect(Rect.fromLTWH(s * 0.22, s * 0.66, s * 0.1, s * 0.2), body);
    c.drawRect(Rect.fromLTWH(s * 0.48, s * 0.66, s * 0.1, s * 0.2), body);
    c.drawOval(Rect.fromLTWH(s * 0.19, s * 0.84, s * 0.14, s * 0.06), dark);
    c.drawOval(Rect.fromLTWH(s * 0.45, s * 0.84, s * 0.14, s * 0.06), dark);
    // Tail
    final tail = Path()
      ..moveTo(s * 0.15, s * 0.5)
      ..quadraticBezierTo(s * 0.0, s * 0.4, s * 0.03, s * 0.56)
      ..lineTo(s * 0.15, s * 0.55);
    c.drawPath(tail, body);
  }

  @override
  bool shouldRepaint(covariant _DinoPainter old) =>
      old.type != type || old.dinoColor != dinoColor;
}
