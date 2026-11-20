// Gera os efeitos sonoros do jogo em assets/sons/, sintetizados aqui mesmo:
// sem arquivo de terceiros, sem licença a conferir. Rode com
//   node tool/gerar_sons.mjs
// e confira o resultado ouvindo os .wav. Mono, 22 050 Hz, 16 bits.
import { writeFileSync } from 'node:fs';

const TAXA = 22050;

/** Ruído com semente fixa, para o arquivo sair igual a cada execução. */
function ruido(semente) {
  let s = semente;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return (s / 0xffffffff) * 2 - 1;
  };
}

/** Envelope de ataque e queda exponencial. */
const envelope = (t, ataque, queda) =>
  t < ataque ? t / ataque : Math.exp(-(t - ataque) / queda);

/** Estalo de carta: ruído filtrado, bem curto. */
function estalo(amostras, inicio, semente, brilho = 0.55, duracao = 0.07) {
  const r = ruido(semente);
  let anterior = 0;
  for (let i = 0; i < duracao * TAXA; i++) {
    const t = i / TAXA;
    // passa-baixa simples: quanto menor o brilho, mais abafado
    anterior = anterior + brilho * (r() - anterior);
    const j = Math.round(inicio * TAXA) + i;
    if (j < amostras.length) amostras[j] += anterior * envelope(t, 0.002, 0.018) * 0.9;
  }
}

/** Nota com timbre de triângulo e um pouco de harmônico. */
function nota(amostras, inicio, freq, duracao, volume = 0.35) {
  for (let i = 0; i < duracao * TAXA; i++) {
    const t = i / TAXA;
    const fase = (t * freq) % 1;
    const triangulo = 4 * Math.abs(fase - 0.5) - 1;
    const valor =
      (triangulo * 0.8 + Math.sin(2 * Math.PI * freq * 2 * t) * 0.2) *
      envelope(t, 0.008, duracao / 3) *
      volume;
    const j = Math.round(inicio * TAXA) + i;
    if (j < amostras.length) amostras[j] += valor;
  }
}

/** Sopro: ruído que sobe e desce, mais aberto no meio. */
function sopro(amostras, duracao, semente) {
  const r = ruido(semente);
  let anterior = 0;
  for (let i = 0; i < duracao * TAXA; i++) {
    const t = i / TAXA;
    const meio = Math.sin((Math.PI * t) / duracao);
    anterior = anterior + (0.08 + 0.35 * meio) * (r() - anterior);
    amostras[i] += anterior * meio * 0.8;
  }
}

function wav(nome, segundos, desenhar) {
  const amostras = new Float32Array(Math.round(segundos * TAXA));
  desenhar(amostras);
  const pico = Math.max(...amostras.map(Math.abs)) || 1;
  const dados = Buffer.alloc(amostras.length * 2);
  amostras.forEach((v, i) =>
    dados.writeInt16LE(Math.round((v / pico) * 0.85 * 32767), i * 2),
  );
  const cab = Buffer.alloc(44);
  cab.write('RIFF', 0);
  cab.writeUInt32LE(36 + dados.length, 4);
  cab.write('WAVEfmt ', 8);
  cab.writeUInt32LE(16, 16);
  cab.writeUInt16LE(1, 20); // PCM
  cab.writeUInt16LE(1, 22); // mono
  cab.writeUInt32LE(TAXA, 24);
  cab.writeUInt32LE(TAXA * 2, 28);
  cab.writeUInt16LE(2, 32);
  cab.writeUInt16LE(16, 34);
  cab.write('data', 36);
  cab.writeUInt32LE(dados.length, 40);
  writeFileSync(new URL(`../assets/sons/${nome}.wav`, import.meta.url), Buffer.concat([cab, dados]));
  console.log(`assets/sons/${nome}.wav`, `${(44 + dados.length) / 1000} kB`);
}

// Notas (Hz): dó, mi, sol, dó agudo, mi agudo.
const [DO, MI, SOL, DO2, MI2] = [523.25, 659.25, 783.99, 1046.5, 1318.5];

wav('distribuir', 0.32, (a) => {
  for (let k = 0; k < 4; k++) estalo(a, k * 0.06, 11 + k, 0.5 + k * 0.05);
});
wav('enviar', 0.26, (a) => {
  sopro(a, 0.2, 7);
  estalo(a, 0.18, 3, 0.4);
});
wav('virar', 0.2, (a) => {
  estalo(a, 0, 21, 0.65, 0.05);
  estalo(a, 0.08, 22, 0.45, 0.06);
});
wav('rodada', 0.6, (a) => {
  nota(a, 0, DO, 0.25);
  nota(a, 0.11, MI, 0.25);
  nota(a, 0.22, SOL, 0.38);
});
wav('vitoria', 1.2, (a) => {
  nota(a, 0, SOL, 0.18);
  nota(a, 0.14, SOL, 0.18);
  nota(a, 0.28, DO2, 0.3);
  nota(a, 0.5, MI2, 0.25);
  nota(a, 0.62, DO2, 0.55, 0.4);
  nota(a, 0.62, SOL, 0.55, 0.25);
  nota(a, 0.62, MI, 0.55, 0.2);
});
