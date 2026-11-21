import 'package:cartaralho/models/card.dart';
import 'package:cartaralho/models/game_room.dart';
import 'package:cartaralho/models/player.dart';
import 'package:cartaralho/ui/jogadores.dart';
import 'package:cartaralho/ui/tema.dart';
import 'package:cartaralho/widgets/player_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _jogadores = [
  Player(id: 'ana', name: 'Ana', points: 2),
  Player(id: 'bia', name: 'Bia', points: 1),
  Player(id: 'caio', name: 'Caio'),
];

GameRoom _sala(GamePhase fase, {Map<String, List<GameCard>>? enviadas}) =>
    GameRoom(
      roomId: 'K7PX2M',
      players: _jogadores,
      blackCards: const [],
      whiteCards: const [],
      currentJudgeId: 'ana',
      currentBlackCard:
          GameCard(id: 'b1', text: 'Frase ____.', type: CardType.black),
      submittedCards: enviadas ?? const {},
      lastRoundWinnerId: 'bia',
      phase: fase,
    );

final _carta = GameCard(id: 'w1', text: 'meu ex', type: CardType.white);

void main() {
  group('humorNoPlacar', () {
    test('escolhendo: quem falta pensa, quem enviou sorri, o juiz julga', () {
      final s = _sala(GamePhase.playersSubmitting, enviadas: {
        'bia': [_carta]
      });
      expect(humorNoPlacar(s, 'ana'), Humor.julgando);
      expect(humorNoPlacar(s, 'bia'), Humor.enviou);
      expect(humorNoPlacar(s, 'caio'), Humor.pensando);
    });

    test('juiz demorando: os outros ficam impacientes', () {
      final s = _sala(GamePhase.judgeChoosing);
      expect(humorNoPlacar(s, 'bia'), Humor.enviou);
      expect(humorNoPlacar(s, 'bia', juizDemorando: true), Humor.impaciente);
      expect(humorNoPlacar(s, 'ana', juizDemorando: true), Humor.julgando);
    });

    test('resultado: quem ganhou a rodada comemora', () {
      final s = _sala(GamePhase.roundResult);
      expect(humorNoPlacar(s, 'bia'), Humor.comemorando);
      expect(humorNoPlacar(s, 'caio'), Humor.normal);
    });

    test('sem sala, todo mundo normal', () {
      expect(humorNoPlacar(null, 'ana'), Humor.normal);
    });
  });

  group('liderDaSala', () {
    test('quem tem mais pontos, sozinho', () {
      expect(liderDaSala(_jogadores), 'ana');
    });

    test('empate ou ninguém pontuou: sem coroa', () {
      expect(
          liderDaSala([Player(id: 'a', name: 'A'), Player(id: 'b', name: 'B')]),
          isNull);
      expect(
          liderDaSala([
            Player(id: 'a', name: 'A', points: 2),
            Player(id: 'b', name: 'B', points: 2),
          ]),
          isNull);
    });
  });

  testWidgets('depois de 20 s com o juiz, o placar fica impaciente',
      (tester) async {
    Widget placar() => MaterialApp(
          theme: tema,
          home: Scaffold(
            body: PlayerListWidget(
              players: _jogadores,
              judgeId: 'ana',
              sala: _sala(GamePhase.judgeChoosing),
            ),
          ),
        );
    Humor humorDe(String nome) => tester
        .widget<AvatarDeJogador>(find
            .byWidgetPredicate((w) => w is AvatarDeJogador && w.nome == nome))
        .humor;

    await tester.pumpWidget(placar());
    await tester.pump(const Duration(seconds: 1));
    expect(humorDe('Bia'), Humor.enviou);
    await tester.pump(pacienciaComOJuiz);
    expect(humorDe('Bia'), Humor.impaciente);
    expect(humorDe('Ana'), Humor.julgando);
    // A líder usa a coroa.
    expect(
        tester
            .widget<AvatarDeJogador>(find.byWidgetPredicate(
                (w) => w is AvatarDeJogador && w.nome == 'Ana'))
            .lider,
        isTrue);
  });
}
