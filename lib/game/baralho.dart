import 'dart:convert';

import '../models/card.dart';

/// Os pacotes de cartas, na ordem em que aparecem ao criar a sala. Cada um é
/// o arquivo `assets/baralhos/<id>.json`; `test/game/baralho_test.dart` confere
/// as regras de todos.
const pacotes = [
  'basico',
  'brasilidades',
  'familia',
  'firma',
  'role',
  'internet',
  'amor',
  'leve',
  'em-alta',
  'sem-filtro',
];

/// Os pacotes que já vêm marcados ao criar a sala: todos menos o +18, que só
/// entra se o anfitrião marcar e confirmar.
const pacotesPadrao = [
  'basico',
  'brasilidades',
  'familia',
  'firma',
  'role',
  'internet',
  'amor',
  'leve',
  'em-alta',
];

String arquivoDoPacote(String id) => 'assets/baralhos/$id.json';

/// Um baralho: cartas pretas (as frases com lacuna) e brancas (as respostas).
/// Pode ser um pacote só ou vários juntos ([Baralho.juntar]).
class Baralho {
  final String id;
  final String nome;
  final String descricao;

  /// Pacote para maiores de 18: pede confirmação e fica fora do modo solo.
  final bool adulto;
  final List<GameCard> pretas;
  final List<GameCard> brancas;

  const Baralho({
    required this.id,
    required this.nome,
    this.descricao = '',
    this.adulto = false,
    required this.pretas,
    required this.brancas,
  });

  /// Lê o JSON de um pacote (`nome`, `descricao`, `pretas` e `brancas`). Os
  /// ids levam o pacote e a posição, `familia-b1` e `familia-w1`, para não se
  /// repetirem quando a sala junta vários pacotes. A carta guarda de que
  /// pacote veio pelo prefixo do id.
  factory Baralho.fromJsonString(String conteudo, {required String id}) {
    final json = jsonDecode(conteudo) as Map<String, dynamic>;
    List<String> textos(String chave) =>
        (json[chave] as List<dynamic>).cast<String>();
    final pretas = textos('pretas');
    final brancas = textos('brancas');
    return Baralho(
      id: id,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String? ?? '',
      adulto: json['adulto'] as bool? ?? false,
      pretas: [
        for (var i = 0; i < pretas.length; i++)
          GameCard(id: '$id-b${i + 1}', text: pretas[i], type: CardType.black),
      ],
      brancas: [
        for (var i = 0; i < brancas.length; i++)
          GameCard(id: '$id-w${i + 1}', text: brancas[i], type: CardType.white),
      ],
    );
  }

  /// Os pacotes escolhidos num baralho só, com as cartas de todos.
  factory Baralho.juntar(List<Baralho> escolhidos) {
    if (escolhidos.isEmpty) {
      throw ArgumentError('Escolha ao menos um baralho');
    }
    if (escolhidos.length == 1) return escolhidos.single;
    return Baralho(
      id: escolhidos.map((b) => b.id).join('+'),
      nome: escolhidos.map((b) => b.nome).join(', '),
      adulto: escolhidos.any((b) => b.adulto),
      pretas: [for (final b in escolhidos) ...b.pretas],
      brancas: [for (final b in escolhidos) ...b.brancas],
    );
  }
}

/// Os pacotes de [todos] cujo id está em [ids], juntos num baralho só, na
/// ordem do catálogo.
Baralho juntarEscolhidos(List<Baralho> todos, Set<String> ids) =>
    Baralho.juntar([
      for (final b in todos)
        if (ids.contains(b.id)) b
    ]);

/// De que pacote veio a carta, pelo prefixo do id (`familia-w3` → `familia`).
/// Cartas de salas criadas antes dos pacotes (`w3`) vêm do básico.
String pacoteDaCarta(GameCard carta) {
  final traco = carta.id.lastIndexOf('-');
  return traco < 0 ? 'basico' : carta.id.substring(0, traco);
}
