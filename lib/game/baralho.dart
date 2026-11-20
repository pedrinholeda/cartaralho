import '../models/card.dart';

/// Baralho com que toda sala nova começa.
///
/// Dá para até [maximoDeJogadores] jogadores: cada mão tem 5 cartas e sobram
/// algumas no monte. Baralhos num arquivo próprio e baralhos customizados estão
/// no docs/ROADMAP.md.

const maximoDeJogadores = 8;

const _pretas = [
  '____ é a melhor coisa do mundo.',
  'Não consigo viver sem ____.',
  'Ontem eu vi ____ no mercado.',
  'A razão pela qual eu acordei hoje foi ____.',
  '____ é a resposta para todos os problemas.',
  'O que a minha avó esconde no guarda-roupa? ____.',
  'No próximo BBB, a prova do líder vai ser ____.',
  'O segredo de um casamento feliz é ____.',
  'Fui demitido por causa de ____.',
  'O grupo da família só fala de ____.',
  'Meu terapeuta disse que o meu problema é ____.',
  'A nova lei proíbe ____ depois das dez da noite.',
  'O que estraga qualquer churrasco? ____.',
  'Minha próxima tatuagem vai ser ____.',
  'Nada como ____ numa segunda-feira de manhã.',
];

const _brancas = [
  'Cachorros',
  'Pizza',
  'Meu ex',
  'Café',
  'TikTok',
  'Inteligência Artificial',
  'Netflix',
  'Chocolate',
  'Viagem',
  'Música',
  'Futebol',
  'Tecnologia',
  'Família',
  'Dinheiro',
  'Amor',
  'Um áudio de 7 minutos',
  'O tio do pavê',
  'Pagar boleto',
  'Sertanejo universitário',
  'Um pombo com fome',
  'Pão de queijo frio',
  'O coach quântico',
  'Ficar sem bateria',
  'Uma planilha de Excel',
  'Dormir de tênis',
  'Mandar mensagem para o grupo errado',
  'A sogra',
  'A vizinha fofoqueira',
  'Horário de verão',
  'O Wi-Fi do vizinho',
  'Feijoada às três da manhã',
  'Um carrinho de supermercado com rodinha torta',
  'Reunião que podia ser um e-mail',
  'Desodorante vencido',
  'A Copa do Mundo',
  'Ônibus lotado',
  'Pastel de feira',
  'O cunhado',
  'Segunda-feira',
  'Um gato julgando você',
  'Esquecer o nome de alguém',
  'Fila do banco',
  'O chinelo da mãe',
  'Fazer dieta na segunda',
  'Um karaokê desafinado',
  'Spoiler do final',
  'Pix errado',
  'Calcinha bege',
];

List<GameCard> cartasPretas() => [
      for (var i = 0; i < _pretas.length; i++)
        GameCard(id: 'b${i + 1}', text: _pretas[i], type: CardType.black),
    ];

List<GameCard> cartasBrancas() => [
      for (var i = 0; i < _brancas.length; i++)
        GameCard(id: 'w${i + 1}', text: _brancas[i], type: CardType.white),
    ];
