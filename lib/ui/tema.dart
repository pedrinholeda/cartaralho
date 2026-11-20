import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cores do Cartaralho. A mesa é o vermelho dos logos em docs/marca/; tudo que
/// se lê fica em cartas, pretas ou brancas. O amarelo do confete só marca o
/// juiz e quem venceu. Detalhes e motivos em docs/DESIGN.md.
@immutable
class Cores extends ThemeExtension<Cores> {
  /// Fundo de todas as telas.
  final Color mesa;

  /// Texto e ícones direto sobre a mesa.
  final Color tintaNaMesa;

  /// Carta branca e o texto dela.
  final Color carta;
  final Color tintaNaCarta;

  /// Carta preta e o texto dela.
  final Color cartaPreta;
  final Color tintaNaCartaPreta;

  /// Juiz da rodada e vencedor.
  final Color destaque;
  final Color tintaNoDestaque;

  const Cores({
    required this.mesa,
    required this.tintaNaMesa,
    required this.carta,
    required this.tintaNaCarta,
    required this.cartaPreta,
    required this.tintaNaCartaPreta,
    required this.destaque,
    required this.tintaNoDestaque,
  });

  static const claro = Cores(
    mesa: Color(0xFFD7282F),
    tintaNaMesa: Color(0xFFFFFFFF),
    carta: Color(0xFFFFFFFF),
    tintaNaCarta: Color(0xFF000000),
    cartaPreta: Color(0xFF000000),
    tintaNaCartaPreta: Color(0xFFFFFFFF),
    destaque: Color(0xFFFFC23A),
    tintaNoDestaque: Color(0xFF000000),
  );

  static const escuro = Cores(
    mesa: Color(0xFF2B0B0E),
    tintaNaMesa: Color(0xFFF4DADB),
    carta: Color(0xFFECECEC),
    tintaNaCarta: Color(0xFF000000),
    cartaPreta: Color(0xFF000000),
    tintaNaCartaPreta: Color(0xFFFFFFFF),
    destaque: Color(0xFFFFC23A),
    tintaNoDestaque: Color(0xFF000000),
  );

  static Cores de(BuildContext context) =>
      Theme.of(context).extension<Cores>() ?? claro;

  @override
  Cores copyWith({
    Color? mesa,
    Color? tintaNaMesa,
    Color? carta,
    Color? tintaNaCarta,
    Color? cartaPreta,
    Color? tintaNaCartaPreta,
    Color? destaque,
    Color? tintaNoDestaque,
  }) {
    return Cores(
      mesa: mesa ?? this.mesa,
      tintaNaMesa: tintaNaMesa ?? this.tintaNaMesa,
      carta: carta ?? this.carta,
      tintaNaCarta: tintaNaCarta ?? this.tintaNaCarta,
      cartaPreta: cartaPreta ?? this.cartaPreta,
      tintaNaCartaPreta: tintaNaCartaPreta ?? this.tintaNaCartaPreta,
      destaque: destaque ?? this.destaque,
      tintaNoDestaque: tintaNoDestaque ?? this.tintaNoDestaque,
    );
  }

  @override
  Cores lerp(Cores? other, double t) {
    if (other == null) return this;
    return Cores(
      mesa: Color.lerp(mesa, other.mesa, t)!,
      tintaNaMesa: Color.lerp(tintaNaMesa, other.tintaNaMesa, t)!,
      carta: Color.lerp(carta, other.carta, t)!,
      tintaNaCarta: Color.lerp(tintaNaCarta, other.tintaNaCarta, t)!,
      cartaPreta: Color.lerp(cartaPreta, other.cartaPreta, t)!,
      tintaNaCartaPreta:
          Color.lerp(tintaNaCartaPreta, other.tintaNaCartaPreta, t)!,
      destaque: Color.lerp(destaque, other.destaque, t)!,
      tintaNoDestaque: Color.lerp(tintaNoDestaque, other.tintaNoDestaque, t)!,
    );
  }
}

/// Espaçamentos e raios. Uma carta tem cantos de carta de baralho; botão e
/// campo são mais redondos, para não se confundirem com carta.
abstract final class Medidas {
  static const espaco = 8.0;
  static const margem = 20.0;
  static const raioCarta = 14.0;
  static const raioBotao = 28.0;

  /// Largura sobre altura de uma carta de baralho (63 x 88 mm).
  static const proporcaoCarta = 63 / 88;

  /// Largura máxima do conteúdo em tela larga.
  static const larguraMaxima = 560.0;

  /// A partir desta largura a tela de jogo se divide em duas colunas.
  static const larguraDuasColunas = 900.0;

  /// Sombra seca embaixo da carta, como papel em cima da mesa.
  static const sombra = Color(0x40000000);
  static const sombraLeve = Color(0x33000000);
}

/// Tipografia: Archivo no texto, Archivo Narrow pesada nos títulos, estreita
/// como as letras dos logos.
TextTheme _tipografia(TextTheme base, Color tinta) {
  final texto = GoogleFonts.archivoTextTheme(base);
  TextStyle? titulo(TextStyle? s, double tamanho) =>
      GoogleFonts.archivoNarrow(textStyle: s).copyWith(
        fontSize: tamanho,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: -0.5,
      );
  return texto
      .copyWith(
        displaySmall: titulo(texto.displaySmall, 44),
        headlineMedium: titulo(texto.headlineMedium, 32),
        headlineSmall: titulo(texto.headlineSmall, 26),
        titleLarge: titulo(texto.titleLarge, 22),
      )
      .apply(bodyColor: tinta, displayColor: tinta);
}

ThemeData _tema(Brightness brilho, Cores cores) {
  final esquema = ColorScheme.fromSeed(
    seedColor: cores.mesa,
    brightness: brilho,
  ).copyWith(
    surface: cores.mesa,
    onSurface: cores.tintaNaMesa,
    primary: cores.cartaPreta,
    onPrimary: cores.tintaNaCartaPreta,
    secondary: cores.destaque,
    onSecondary: cores.tintaNoDestaque,
  );
  final base = ThemeData(colorScheme: esquema, useMaterial3: true);
  final botao = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Medidas.raioBotao),
  );
  const altura = Size.fromHeight(56);

  return base.copyWith(
    scaffoldBackgroundColor: cores.mesa,
    textTheme: _tipografia(base.textTheme, cores.tintaNaMesa),
    extensions: [cores],
    appBarTheme: AppBarTheme(
      backgroundColor: cores.mesa,
      foregroundColor: cores.tintaNaMesa,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cores.cartaPreta,
        foregroundColor: cores.tintaNaCartaPreta,
        disabledBackgroundColor: cores.cartaPreta.withValues(alpha: 0.35),
        disabledForegroundColor: cores.tintaNaCartaPreta.withValues(alpha: 0.6),
        minimumSize: altura,
        shape: botao,
        elevation: 0,
        textStyle: GoogleFonts.archivo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cores.tintaNaMesa,
        side: BorderSide(color: cores.tintaNaMesa, width: 2),
        minimumSize: altura,
        shape: botao,
        textStyle: GoogleFonts.archivo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: cores.tintaNaMesa),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cores.carta,
      labelStyle: TextStyle(color: cores.tintaNaCarta.withValues(alpha: 0.7)),
      floatingLabelStyle: TextStyle(color: cores.tintaNaCarta),
      prefixIconColor: cores.tintaNaCarta,
      counterStyle: TextStyle(color: cores.tintaNaMesa),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Medidas.raioCarta),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Medidas.raioCarta),
        borderSide: BorderSide(color: cores.cartaPreta, width: 2),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: cores.cartaPreta),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: cores.mesa,
      selectedColor: cores.carta,
      labelStyle: TextStyle(color: cores.tintaNaMesa),
      secondaryLabelStyle: TextStyle(color: cores.tintaNaCarta),
      checkmarkColor: cores.tintaNaCarta,
      side: BorderSide(color: cores.tintaNaMesa, width: 1.5),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cores.cartaPreta,
      contentTextStyle: TextStyle(color: cores.tintaNaCartaPreta),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme:
        ProgressIndicatorThemeData(color: cores.tintaNaMesa),
  );
}

final temaClaro = _tema(Brightness.light, Cores.claro);
final temaEscuro = _tema(Brightness.dark, Cores.escuro);
