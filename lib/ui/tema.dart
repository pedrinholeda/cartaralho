import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cores da Noite de jogo: a mesa é escura, como uma sala com a luz baixa; as
/// cartas brilham em cima dela; o vermelho do logo aparece só onde há uma
/// ação a fazer; o amarelo marca o juiz e quem ganhou. Motivos em
/// docs/DESIGN.md.
@immutable
class Cores extends ThemeExtension<Cores> {
  /// Fundo de todas as telas.
  final Color mesa;

  /// Um degrau acima da mesa: barras, painéis, avisos, campos.
  final Color superficie;

  /// Texto e ícones sobre a mesa e a superfície.
  final Color tintaNaMesa;

  /// Texto de apoio sobre a mesa (legendas, dicas).
  final Color tintaSuave;

  /// Carta branca e o texto dela.
  final Color carta;
  final Color tintaNaCarta;

  /// Carta preta e o texto dela.
  final Color cartaPreta;
  final Color tintaNaCartaPreta;

  /// A ação principal da tela (o botão que faz o jogo andar) e a resposta
  /// escolhida.
  final Color acao;
  final Color tintaNaAcao;

  /// Juiz da rodada e vencedor.
  final Color destaque;
  final Color tintaNoDestaque;

  const Cores({
    required this.mesa,
    required this.superficie,
    required this.tintaNaMesa,
    required this.tintaSuave,
    required this.carta,
    required this.tintaNaCarta,
    required this.cartaPreta,
    required this.tintaNaCartaPreta,
    required this.acao,
    required this.tintaNaAcao,
    required this.destaque,
    required this.tintaNoDestaque,
  });

  static const noite = Cores(
    mesa: Color(0xFF1B1522),
    superficie: Color(0xFF2A2233),
    tintaNaMesa: Color(0xFFF3EEF7),
    tintaSuave: Color(0xFFB9AFC4),
    carta: Color(0xFFFFFFFF),
    tintaNaCarta: Color(0xFF16121A),
    cartaPreta: Color(0xFF000000),
    tintaNaCartaPreta: Color(0xFFFFFFFF),
    acao: Color(0xFFD7282F),
    tintaNaAcao: Color(0xFFFFFFFF),
    destaque: Color(0xFFFFC23A),
    tintaNoDestaque: Color(0xFF2B1A00),
  );

  static Cores de(BuildContext context) =>
      Theme.of(context).extension<Cores>() ?? noite;

  @override
  Cores copyWith() => this;

  @override
  Cores lerp(Cores? other, double t) => this;
}

/// Cor fixa de cada jogador no avatar, pela posição na sala. Tons que
/// aparecem bem sobre a mesa escura e não se confundem com o vermelho da
/// ação nem com o amarelo do juiz.
const coresDeJogador = [
  (Color(0xFF8E7CFF), Color(0xFF15102E)),
  (Color(0xFF3DD6B5), Color(0xFF032A21)),
  (Color(0xFFFF8FB8), Color(0xFF3A0B1E)),
  (Color(0xFF6CB6FF), Color(0xFF071F38)),
  (Color(0xFFB8E06A), Color(0xFF1C2A05)),
  (Color(0xFFFFA36B), Color(0xFF3A1A05)),
  (Color(0xFFE0B3FF), Color(0xFF2A0F3D)),
  (Color(0xFF9EE7F5), Color(0xFF06303A)),
];

/// Espaçamentos e raios. Tudo arredondado e macio; a carta tem cantos um pouco
/// menores que os painéis, para continuar parecendo carta.
abstract final class Medidas {
  static const espaco = 8.0;
  static const margem = 20.0;
  static const raioCarta = 16.0;
  static const raioPainel = 22.0;
  static const raioBotao = 18.0;

  /// Largura sobre altura de uma carta de baralho (63 x 88 mm).
  static const proporcaoCarta = 63 / 88;

  /// Largura máxima do conteúdo em tela larga.
  static const larguraMaxima = 560.0;

  /// A partir desta largura a tela de jogo se divide em duas colunas.
  static const larguraDuasColunas = 900.0;

  /// Sombras: a carta flutua um pouco acima da mesa.
  static const sombra = Color(0x66000000);
  static const sombraLeve = Color(0x40000000);
}

/// Figtree em tudo: arredondada e amigável, pesada nos títulos.
TextTheme _tipografia(TextTheme base, Color tinta) {
  final texto = GoogleFonts.figtreeTextTheme(base);
  TextStyle? titulo(TextStyle? s, double tamanho) => s?.copyWith(
        fontSize: tamanho,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.4,
      );
  return texto
      .copyWith(
        displaySmall: titulo(texto.displaySmall, 40),
        headlineMedium: titulo(texto.headlineMedium, 30),
        headlineSmall: titulo(texto.headlineSmall, 24),
        titleLarge: titulo(texto.titleLarge, 20),
        titleMedium: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      )
      .apply(bodyColor: tinta, displayColor: tinta);
}

ThemeData _tema(Cores cores) {
  final esquema = ColorScheme.fromSeed(
    seedColor: cores.acao,
    brightness: Brightness.dark,
  ).copyWith(
    surface: cores.mesa,
    onSurface: cores.tintaNaMesa,
    primary: cores.acao,
    onPrimary: cores.tintaNaAcao,
    secondary: cores.destaque,
    onSecondary: cores.tintaNoDestaque,
  );
  final base = ThemeData(colorScheme: esquema, useMaterial3: true);
  final forma = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Medidas.raioBotao),
  );
  const altura = Size.fromHeight(56);
  final rotulo = GoogleFonts.figtree(fontSize: 17, fontWeight: FontWeight.w700);
  // Apertar o botão encolhe um pouco: o toque tem resposta.
  final apertar = WidgetStateProperty.resolveWith<OutlinedBorder>(
    (estados) => estados.contains(WidgetState.pressed)
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Medidas.raioBotao + 6),
          )
        : forma,
  );

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
      titleTextStyle: GoogleFonts.figtree(
        color: cores.tintaNaMesa,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cores.acao,
        foregroundColor: cores.tintaNaAcao,
        disabledBackgroundColor: cores.superficie,
        disabledForegroundColor: cores.tintaSuave,
        minimumSize: altura,
        elevation: 0,
        textStyle: rotulo,
      ).copyWith(shape: apertar),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cores.tintaNaMesa,
        backgroundColor: cores.superficie,
        side: BorderSide.none,
        minimumSize: altura,
        textStyle: rotulo,
      ).copyWith(shape: apertar),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: cores.tintaSuave,
        textStyle: GoogleFonts.figtree(fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: cores.tintaNaMesa),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cores.superficie,
      labelStyle: TextStyle(color: cores.tintaSuave),
      floatingLabelStyle: TextStyle(color: cores.tintaNaMesa),
      hintStyle: TextStyle(color: cores.tintaSuave.withValues(alpha: 0.7)),
      prefixIconColor: cores.tintaSuave,
      counterStyle: TextStyle(color: cores.tintaSuave),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Medidas.raioBotao),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Medidas.raioBotao),
        borderSide: BorderSide(color: cores.acao, width: 2),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: cores.acao),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: cores.superficie,
      selectedColor: cores.acao,
      labelStyle: GoogleFonts.figtree(
        color: cores.tintaNaMesa,
        fontWeight: FontWeight.w700,
      ),
      secondaryLabelStyle: GoogleFonts.figtree(
        color: cores.tintaNaAcao,
        fontWeight: FontWeight.w700,
      ),
      checkmarkColor: cores.tintaNaAcao,
      showCheckmark: false,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cores.superficie,
      contentTextStyle: GoogleFonts.figtree(
        color: cores.tintaNaMesa,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medidas.raioBotao),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: cores.superficie,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: TextStyle(color: cores.tintaNaMesa),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: cores.acao),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}

/// O tema do jogo. É um só, escuro: a noite é a identidade, não uma
/// preferência do sistema.
final tema = _tema(Cores.noite);
