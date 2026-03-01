import 'package:flutter/material.dart';

/// Constantes de thème pour le design Spark
class SparkTheme {
  // Couleurs principales
  static const Color backgroundColor = Color(0xFF120024);
  static const Color backgroundGradientStart = Color(0xFF120024);
  static const Color backgroundGradientEnd = Color(0xFF2D1B4E);

  // Couleurs d'accent
  static const Color primaryOrange = Color(0xFFFF6B4A);
  static const Color secondaryOrange = Color(0xFFFFB347);
  static const Color warmGlow = Color(0xFFFF8C42);

  // Couleurs du bouton gradient
  static const Color buttonGradientStart = Color(0xFFFF8C42);
  static const Color buttonGradientEnd = Color(0xFFE85A4F);

  // Couleurs des cartes
  static const Color cardBackground = Color(0xFF2A1B3D);
  static const Color cardBackgroundLight = Color(0xFF3D2B52);

  // Couleurs de texte
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB8B8B8);
  static const Color textMuted = Color(0xFF8A8A8A);

  // Gradient de fond principal
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundGradientStart, backgroundGradientEnd],
  );

  // Gradient avec glow orange en bas
  static LinearGradient backgroundWithGlow({double glowIntensity = 0.3}) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        backgroundGradientStart,
        backgroundGradientEnd,
        Color.lerp(backgroundGradientEnd, warmGlow, glowIntensity)!,
      ],
      stops: const [0.0, 0.6, 1.0],
    );
  }

  // Gradient du bouton principal
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [buttonGradientStart, buttonGradientEnd],
  );

  // Style de texte pour les titres
  static const TextStyle titleStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );

  // Style de texte pour les sous-titres
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );

  // Style de texte pour le corps
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  // Style de texte pour les boutons
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  // Décoration de carte
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
  );

  // Décoration de bouton principal
  static BoxDecoration primaryButtonDecoration = BoxDecoration(
    gradient: buttonGradient,
    borderRadius: BorderRadius.circular(30),
    boxShadow: [
      BoxShadow(
        color: primaryOrange.withOpacity(0.4),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

/// Widget de bouton avec gradient
class SparkGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double? width;
  final double height;
  final bool isLoading;

  const SparkGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.height = 56,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: SparkTheme.primaryButtonDecoration,
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(text, style: SparkTheme.buttonTextStyle),
        ),
      ),
    );
  }
}

/// Widget de carte avec style Spark
class SparkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? backgroundColor;

  const SparkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? SparkTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: child,
    );
  }
}

/// Widget de fond avec gradient et effet de glow
class SparkBackground extends StatelessWidget {
  final Widget child;
  final bool showGlow;
  final double glowIntensity;

  const SparkBackground({
    super.key,
    required this.child,
    this.showGlow = false,
    this.glowIntensity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: showGlow
            ? SparkTheme.backgroundWithGlow(glowIntensity: glowIntensity)
            : SparkTheme.backgroundGradient,
      ),
      child: SizedBox.expand(child: child),
    );
  }
}

/// Widget du logo de l'app pour les écrans Spark
class SparkLogo extends StatelessWidget {
  final double size;

  const SparkLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo-no-bg.png',
      width: size,
      height: size,
    );
  }
}
