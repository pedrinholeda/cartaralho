// Convite para uma sala: o link que abre o jogo já na tela de entrar, com o
// código preenchido, e o texto pronto para colar no grupo.

/// Nome do parâmetro do link: `https://.../?sala=K7PX2M`.
const parametroDaSala = 'sala';

/// Letras e números que podem aparecer num código de sala.
final _codigoValido = RegExp(r'^[A-Z0-9]{6}$');

/// O código da sala no link, ou null se não houver um válido. Aceita
/// minúsculas e espaços em volta, porque o link pode ter sido digitado.
String? codigoDoConvite(Uri link) {
  final codigo = link.queryParameters[parametroDaSala]?.trim().toUpperCase();
  if (codigo == null || !_codigoValido.hasMatch(codigo)) return null;
  return codigo;
}

/// O link de convite a partir do endereço em que o jogo está aberto, sem
/// manter outros parâmetros nem âncora.
Uri linkDoConvite(Uri endereco, String codigo) => endereco.replace(
      queryParameters: {parametroDaSala: codigo},
      fragment: '',
    ).removeFragment();

/// O texto para colar no grupo.
String textoDoConvite(Uri endereco, String codigo) =>
    'Bora jogar Cartaralho? Entra na sala $codigo: '
    '${linkDoConvite(endereco, codigo)}';
