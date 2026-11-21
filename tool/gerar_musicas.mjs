// Gera as músicas de fundo em assets/musicas/, sintetizadas aqui mesmo (sem
// arquivo de terceiros, sem licença a conferir). Rode com
//   node tool/gerar_musicas.mjs
// Cada faixa é um loop: o que passa do fim volta no começo, então emenda sem
// corte. Mono, 16 000 Hz, 16 bits, num volume baixo (fundo, não protagonista).
//
// - escolha: lo-fi fofinho, para quando todo mundo escolhe a carta
// - juiz: menor, com um tique-taque leve, para quando o juiz decide
// - madrugada: a escolha mais lenta, meio tom abaixo e desafinada (das 3h às 5h)
import { writeFileSync, mkdirSync } from 'node:fs';

const TAXA = 16000;
const deDb = (db) => 10 ** (db / 20);
const nota = (n) => 440 * 2 ** ((n - 69) / 12); // número MIDI → Hz

function ruido(semente) {
  let s = semente;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return (s / 0xffffffff) * 2 - 1;
  };
}

/** Escreve um som no loop, dando a volta no fim. */
function somar(a, inicio, duracao, gerar) {
  const i0 = Math.round(inicio * TAXA);
  const n = Math.round(duracao * TAXA);
  for (let i = 0; i < n; i++) a[(i0 + i) % a.length] += gerar(i / TAXA);
}

/** Piano elétrico macio: seno com um pouco de segundo harmônico e tremolo. */
function tecla(a, inicio, freq, duracao, volume, desafino = 0) {
  somar(a, inicio, duracao + 0.6, (t) => {
    const f = freq * (1 + desafino * Math.sin(2 * Math.PI * 0.7 * t));
    const env = Math.min(1, t / 0.02) * Math.exp(-t / (duracao * 0.9));
    const trem = 1 + 0.12 * Math.sin(2 * Math.PI * 4.5 * t);
    return (Math.sin(2 * Math.PI * f * t) + 0.25 * Math.sin(4 * Math.PI * f * t)) * env * trem * volume;
  });
}

/** Caixinha de música: triângulo agudo, curto. */
function caixinha(a, inicio, freq, volume) {
  somar(a, inicio, 0.7, (t) => {
    const fase = (t * freq) % 1;
    return (4 * Math.abs(fase - 0.5) - 1) * Math.min(1, t / 0.004) * Math.exp(-t / 0.18) * volume;
  });
}

/** Baixo redondo. */
function baixo(a, inicio, freq, duracao, volume) {
  somar(a, inicio, duracao, (t) =>
    Math.sin(2 * Math.PI * freq * t) * Math.min(1, t / 0.015) * Math.exp(-t / (duracao * 0.8)) * volume,
  );
}

/** Bumbo fofo: seno que cai de tom. */
function bumbo(a, inicio, volume) {
  let fase = 0;
  somar(a, inicio, 0.25, (t) => {
    fase += (2 * Math.PI * (55 + 90 * Math.exp(-t / 0.03))) / TAXA;
    return Math.sin(fase) * Math.exp(-t / 0.08) * volume;
  });
}

/** Chocalho: ruído curtinho. */
function chocalho(a, inicio, semente, volume) {
  const r = ruido(semente);
  let ant = 0;
  somar(a, inicio, 0.06, (t) => {
    const x = r();
    const agudo = x - ant; // só o chiado de cima
    ant = x;
    return agudo * Math.exp(-t / 0.015) * volume;
  });
}

/** Tique-taque de relógio. */
function tique(a, inicio, freq, volume) {
  somar(a, inicio, 0.03, (t) => Math.sin(2 * Math.PI * freq * t) * Math.exp(-t / 0.006) * volume);
}

/** Volume médio da parte que soa (janelas de 10 ms acima de 5% do pico). */
function volumeMedio(a) {
  const pico = a.reduce((m, v) => Math.max(m, Math.abs(v)), 0) || 1;
  const j = Math.round(TAXA / 100);
  let soma = 0;
  let conta = 0;
  for (let i = 0; i + j <= a.length; i += j) {
    let q = 0;
    for (let k = i; k < i + j; k++) q += a[k] * a[k];
    const rms = Math.sqrt(q / j);
    if (rms > pico * 0.05) {
      soma += rms * rms;
      conta++;
    }
  }
  return Math.sqrt(soma / Math.max(conta, 1));
}

function gravar(nome, a, alvoDb = -24) {
  const pico = a.reduce((m, v) => Math.max(m, Math.abs(v)), 0) || 1;
  const ganho = Math.min(deDb(alvoDb) / volumeMedio(a), deDb(-3) / pico);
  const dados = Buffer.alloc(a.length * 2);
  a.forEach((v, i) => dados.writeInt16LE(Math.round(Math.max(-1, Math.min(1, v * ganho)) * 32767), i * 2));
  const cab = Buffer.alloc(44);
  cab.write('RIFF', 0);
  cab.writeUInt32LE(36 + dados.length, 4);
  cab.write('WAVEfmt ', 8);
  cab.writeUInt32LE(16, 16);
  cab.writeUInt16LE(1, 20);
  cab.writeUInt16LE(1, 22);
  cab.writeUInt32LE(TAXA, 24);
  cab.writeUInt32LE(TAXA * 2, 28);
  cab.writeUInt16LE(2, 32);
  cab.writeUInt16LE(16, 34);
  cab.write('data', 36);
  cab.writeUInt32LE(dados.length, 40);
  mkdirSync(new URL('../assets/musicas/', import.meta.url), { recursive: true });
  writeFileSync(new URL(`../assets/musicas/${nome}.wav`, import.meta.url), Buffer.concat([cab, dados]));
  console.log(`assets/musicas/${nome}.wav`, `${(a.length / TAXA).toFixed(1)} s`, `${((44 + dados.length) / 1000).toFixed(0)} kB`);
}

/** Uma faixa de 4 compassos de 4 tempos com os [acordes] (notas MIDI). */
function faixa({ bpm, acordes, melodia, transpor = 0, desafino = 0, relogio = false, semente = 1 }) {
  const tempo = 60 / bpm;
  const compasso = tempo * 4;
  const a = new Float32Array(Math.round(compasso * 4 * TAXA));
  acordes.forEach((acorde, c) => {
    const t0 = c * compasso;
    // Acorde no 1 e um toque mais fraco no 3 e meio.
    for (const n of acorde) {
      tecla(a, t0, nota(n + transpor), compasso * 0.6, 0.18, desafino);
      tecla(a, t0 + tempo * 2.5, nota(n + transpor), compasso * 0.3, 0.1, desafino);
    }
    baixo(a, t0, nota(acorde[0] - 12 + transpor), tempo * 1.8, 0.35);
    baixo(a, t0 + tempo * 2, nota(acorde[0] - 12 + transpor), tempo * 1.5, 0.25);
    bumbo(a, t0, 0.35);
    bumbo(a, t0 + tempo * 2, 0.28);
    for (let k = 0; k < 8; k++) chocalho(a, t0 + (k * tempo) / 2, semente * 100 + c * 8 + k, k % 2 ? 0.05 : 0.08);
    if (relogio) for (let k = 0; k < 4; k++) tique(a, t0 + k * tempo, k % 2 ? 1500 : 1900, 0.12);
    // A melodia de caixinha: notas por meio tempo, null é pausa.
    (melodia[c] ?? []).forEach((n, k) => {
      if (n != null) caixinha(a, t0 + (k * tempo) / 2, nota(n + transpor) * (1 + desafino * 0.5), 0.12);
    });
  });
  return a;
}

// Dó maior: Cmaj7, Am7, Fmaj7, G6.
const acordesEscolha = [
  [60, 64, 67, 71],
  [57, 60, 64, 67],
  [53, 57, 60, 64],
  [55, 59, 62, 64],
];
const melodiaEscolha = [
  [76, null, 79, null, 83, null, 79, null],
  [76, null, 72, null, 76, null, null, null],
  [77, null, 76, null, 72, null, 69, null],
  [71, null, 74, null, 79, null, null, null],
];

gravar('escolha', faixa({ bpm: 84, acordes: acordesEscolha, melodia: melodiaEscolha, semente: 1 }));

// Lá menor: Am, F, Dm, E — com o tique-taque do relógio.
gravar(
  'juiz',
  faixa({
    bpm: 96,
    acordes: [
      [57, 60, 64],
      [53, 57, 60],
      [50, 53, 57],
      [52, 56, 59],
    ],
    melodia: [[], [72, null, null, null, 71, null, null, null], [], [68, null, null, null, 71, null, null, null]],
    relogio: true,
    semente: 2,
  }),
  -25,
);

// A escolha, lenta, meio tom abaixo e desafinando devagar.
gravar(
  'madrugada',
  faixa({ bpm: 66, acordes: acordesEscolha, melodia: melodiaEscolha, transpor: -1, desafino: 0.012, semente: 3 }),
  -26,
);
