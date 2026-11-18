#!/usr/bin/env node
/**
 * Gera o channels.xml do iptv-org/epg a partir de uma playlist M3U.
 *
 * Le os tvg-id da playlist, consulta o catalogo guides.json da API do iptv-org
 * (que diz qual site de programacao cobre cada canal) e escreve o channels.xml
 * que o grabber consome via --channels.
 *
 * Sem dependencias: usa fetch e fs nativos do Node 18+.
 *
 *   node gerar-channels.mjs <url-ou-arquivo.m3u> -o public/channels.xml
 */
import { readFile, writeFile } from 'node:fs/promises'

const GUIDES_URL = 'https://iptv-org.github.io/api/guides.json'

// Ordem de preferencia quando o mesmo canal aparece em varios sites.
// mi.tv primeiro: a data vai na URL e os horarios vem em UTC, o parser mais
// robusto para o Brasil.
const PRIORIDADE = ['mi.tv', 'pluto.tv', 'i.mjh.nz', 'clarotvmais.com.br',
                    'claro.com.br', 'vivoplay.com.br']

// Sites nunca usados. O parser do meuguia.tv monta a data com o mes sem zero a
// esquerda e o dayjs, em formato estrito, devolve "Invalid time value" -> zero
// programas de janeiro a setembro. Ajuste com --excluir ou --excluir "" .
// sat.tv: devolve 403 e depois 429; cobre 1 canal so.
// tv.mail.ru: o endpoint de agenda devolve 404 em toda pagina (23/09) e o
// scraper nao trata isso como fim de paginacao — fica incrementando a pagina
// pra sempre, travando o grab inteiro por causa de 1 canal sem cobertura em
// outro site.
const EXCLUIDOS_PADRAO = ['meuguia.tv', 'sat.tv', 'tv.mail.ru']

const IP_NU = /^https?:\/\/\d{1,3}(?:\.\d{1,3}){3}(?::\d+)?\//

function parseArgs(argv) {
  const o = { output: 'channels.xml', lang: 'pt', guides: GUIDES_URL, incluirIpNu: false, sites: null, excluir: EXCLUIDOS_PADRAO }
  const rest = []
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i]
    if (a === '-o' || a === '--output') o.output = argv[++i]
    else if (a === '--lang') o.lang = argv[++i]
    else if (a === '--guides') o.guides = argv[++i]
    else if (a === '--sites') o.sites = argv[++i].split(',').map(s => s.trim())
    else if (a === '--excluir') o.excluir = argv[++i].split(',').map(s => s.trim()).filter(Boolean)
    else if (a === '--incluir-ip-nu') o.incluirIpNu = true
    else rest.push(a)
  }
  o.playlist = rest[0]
  return o
}

async function ler(origem) {
  if (/^https?:\/\//.test(origem)) {
    const r = await fetch(origem)
    if (!r.ok) throw new Error(`${origem} respondeu ${r.status}`)
    return await r.text()
  }
  return await readFile(origem, 'utf8')
}

function parseM3u(texto, excluirIpNu) {
  const linhas = texto.split(/\r?\n/)
  const canais = new Map()
  let pulados = 0
  for (let i = 0; i < linhas.length; i++) {
    if (!linhas[i].startsWith('#EXTINF')) continue
    const url = (linhas[i + 1] || '').trim()
    if (excluirIpNu && IP_NU.test(url)) { pulados++; continue }
    const m = linhas[i].match(/tvg-id="([^"]*)"/)
    if (!m || !m[1]) continue
    const virgula = linhas[i].indexOf(',')
    const nome = virgula >= 0 ? linhas[i].slice(virgula + 1).trim() : m[1]
    if (!canais.has(m[1])) canais.set(m[1], nome)
  }
  return { canais, pulados }
}

const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
                          .replace(/>/g, '&gt;').replace(/"/g, '&quot;')

function escolher(entradas, feed, idioma) {
  const rank = g => [
    g.feed === feed ? 0 : 1,
    g.lang === idioma ? 0 : 1,
    PRIORIDADE.indexOf(g.site) === -1 ? PRIORIDADE.length : PRIORIDADE.indexOf(g.site),
    g.site || ''
  ]
  return entradas.slice().sort((a, b) => {
    const ra = rank(a), rb = rank(b)
    for (let i = 0; i < ra.length; i++) if (ra[i] !== rb[i]) return ra[i] < rb[i] ? -1 : 1
    return 0
  })[0]
}

const args = parseArgs(process.argv.slice(2))
if (!args.playlist) {
  console.error('uso: node gerar-channels.mjs <url-ou-arquivo.m3u> [-o saida.xml] [--sites a,b] [--excluir a,b] [--incluir-ip-nu]')
  process.exit(2)
}

const { canais, pulados } = parseM3u(await ler(args.playlist), !args.incluirIpNu)
if (canais.size === 0) { console.error('Nenhum canal com tvg-id encontrado na playlist.'); process.exit(1) }

const idx = new Map()
for (const g of JSON.parse(await ler(args.guides))) {
  if (!g.channel) continue
  if (!idx.has(g.channel)) idx.set(g.channel, [])
  idx.get(g.channel).push(g)
}

const linhas = [], semFonte = [], usados = new Map()
const ordenados = [...canais.entries()].sort((a, b) => a[1].toLowerCase().localeCompare(b[1].toLowerCase()))
for (const [tvg, nome] of ordenados) {
  const at = tvg.indexOf('@')
  const canal = at === -1 ? tvg : tvg.slice(0, at)
  const feed = at === -1 ? null : tvg.slice(at + 1) || null
  let cands = idx.get(canal) || []
  if (args.excluir.length) cands = cands.filter(g => !args.excluir.includes(g.site))
  if (args.sites) cands = cands.filter(g => args.sites.includes(g.site))
  if (cands.length === 0) { semFonte.push(nome); continue }
  const g = escolher(cands, feed, args.lang)
  usados.set(g.site, (usados.get(g.site) || 0) + 1)
  linhas.push(`  <channel site="${esc(g.site)}" site_id="${esc(g.site_id)}" ` +
              `lang="${esc(g.lang || args.lang)}" xmltv_id="${esc(tvg)}">${esc(nome)}</channel>`)
}

await writeFile(args.output,
  `<?xml version="1.0" encoding="UTF-8"?>\n<channels>\n${linhas.join('\n')}\n</channels>\n`, 'utf8')

console.log(`${args.output}: ${linhas.length} canais com fonte de EPG`)
for (const [site, n] of [...usados].sort((a, b) => b[1] - a[1])) console.log(`  ${site.padEnd(24)} ${n}`)
if (pulados) console.log(`\n${pulados} entradas descartadas por serem servidas por IP nu (use --incluir-ip-nu para manter)`)
if (semFonte.length) console.log(`\n${semFonte.length} canais sem nenhuma fonte de guia`)
