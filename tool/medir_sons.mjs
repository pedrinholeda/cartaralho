// Mede os efeitos sonoros de assets/sons/ (ou outra pasta, como assets/musicas) sem precisar ouvir: duração, pico,
// volume médio da parte que soa (RMS, em dBFS), desvio do zero e as pontas
// (uma ponta longe do zero estala). Rode com
//   node tool/medir_sons.mjs
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const pasta = process.argv[2] ?? 'assets/sons';
const db = (x) => (x > 0 ? 20 * Math.log10(x) : -Infinity);

for (const nome of readdirSync(pasta).filter((n) => n.endsWith('.wav')).sort()) {
  const buf = readFileSync(join(pasta, nome));
  const taxa = buf.readUInt32LE(24);
  const n = (buf.length - 44) / 2;
  const a = Float64Array.from({ length: n }, (_, i) => buf.readInt16LE(44 + i * 2) / 32768);
  const pico = a.reduce((m, v) => Math.max(m, Math.abs(v)), 0);
  // Parte que soa: amostras acima de 1% do pico, em janelas de 10 ms.
  const janela = Math.round(taxa / 100);
  let soma = 0;
  let conta = 0;
  for (let i = 0; i + janela <= n; i += janela) {
    const parte = a.slice(i, i + janela);
    const rms = Math.sqrt(parte.reduce((s, v) => s + v * v, 0) / janela);
    if (rms > pico * 0.05) {
      soma += rms * rms;
      conta++;
    }
  }
  const rms = Math.sqrt(soma / Math.max(conta, 1));
  const media = a.reduce((s, v) => s + v, 0) / n;
  console.log(
    `${nome.padEnd(15)} ${(n / taxa).toFixed(2)} s  pico ${db(pico).toFixed(1)} dBFS  ` +
      `volume ${db(rms).toFixed(1)} dBFS  desvio ${media.toFixed(4)}  ` +
      `começo ${Math.abs(a[0]).toFixed(3)}  fim ${Math.abs(a[n - 1]).toFixed(3)}`,
  );
}
