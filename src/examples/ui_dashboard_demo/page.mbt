///|
/// The demo page, embedded so the binary is self-contained.
/// Raw-string lines: no MoonBit escapes, so JS `${}` is safe to use.
let page_html : String =
  #|<!DOCTYPE html>
  #|<html lang="ja">
  #|<head>
  #|<meta charset="utf-8">
  #|<meta name="viewport" content="width=device-width, initial-scale=1">
  #|<title>On-device Generative UI</title>
  #|<style>
  #|  :root {
  #|    --bg: #f4f5f7; --card: #ffffff; --ink: #1d2330; --muted: #8a93a5;
  #|    --accent: #4f7cff; --bar: #6f96ff; --ghost: #e3e6ec;
  #|  }
  #|  * { box-sizing: border-box; }
  #|  body {
  #|    margin: 0; background: var(--bg); color: var(--ink);
  #|    font-family: -apple-system, "Hiragino Sans", sans-serif;
  #|  }
  #|  header {
  #|    display: flex; gap: 8px; padding: 16px 20px; background: var(--card);
  #|    border-bottom: 1px solid var(--ghost); position: sticky; top: 0;
  #|  }
  #|  #q {
  #|    flex: 1; font-size: 16px; padding: 10px 14px; border: 1px solid var(--ghost);
  #|    border-radius: 10px; outline: none;
  #|  }
  #|  #q:focus { border-color: var(--accent); }
  #|  button {
  #|    font-size: 15px; padding: 10px 18px; border: none; border-radius: 10px;
  #|    background: var(--accent); color: #fff; cursor: pointer;
  #|  }
  #|  button:disabled { opacity: .5; cursor: default; }
  #|  main { max-width: 920px; margin: 0 auto; padding: 24px 20px; }
  #|  #title { font-size: 24px; font-weight: 700; margin: 4px 2px 18px; min-height: 30px; }
  #|  #board { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 14px; }
  #|  .card {
  #|    background: var(--card); border-radius: 14px; padding: 16px 18px;
  #|    box-shadow: 0 1px 3px rgba(20,30,60,.08); min-height: 90px;
  #|    animation: pop .25s ease;
  #|  }
  #|  .card.wide { grid-column: 1 / -1; }
  #|  .card h3 { margin: 0 0 10px; font-size: 14px; color: var(--muted); font-weight: 600; }
  #|  .card p { margin: 0; line-height: 1.6; font-size: 14px; }
  #|  .metric { font-size: 36px; font-weight: 700; }
  #|  .metric .unit { font-size: 16px; color: var(--muted); margin-left: 4px; }
  #|  ul { margin: 0; padding-left: 20px; }
  #|  li { font-size: 14px; line-height: 1.7; }
  #|  .bars { width: 100%; height: 150px; }
  #|  .bars rect { fill: var(--bar); transition: height .3s ease, y .3s ease; }
  #|  .bars text { font-size: 9px; fill: var(--muted); text-anchor: middle; }
  #|  @keyframes pop { from { transform: scale(.97); opacity: 0; } }
  #|  @keyframes pulse { 50% { opacity: .45; } }
  #|  .skeleton {
  #|    background: var(--ghost); border-radius: 6px; height: 14px;
  #|    animation: pulse 1.2s ease-in-out infinite;
  #|  }
  #|  .skeleton.big { height: 34px; width: 50%; }
  #|  .skeleton.title-line { width: 40%; height: 24px; margin: 4px 2px 18px; }
  #|  .ghost-card { opacity: .6; }
  #|  #status { color: var(--muted); font-size: 13px; margin-top: 16px; min-height: 18px; }
  #|  #status.error { color: #d33; }
  #|</style>
  #|</head>
  #|<body>
  #|<header>
  #|  <input id="q" placeholder="例: 今月の進捗まとめて" autofocus>
  #|  <button id="go">生成</button>
  #|</header>
  #|<main>
  #|  <div id="title"></div>
  #|  <div id="board"></div>
  #|  <div id="status"></div>
  #|</main>
  #|<script>
  #|const $ = (id) => document.getElementById(id);
  #|let es = null, prevSections = [], streaming = false;
  #|
  #|function esc(s) {
  #|  return String(s).replace(/[&<>"]/g, c =>
  #|    ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
  #|}
  #|
  #|function barChart(labels, values) {
  #|  const W = 400, H = 150, PAD = 6, LBL = 16;
  #|  const n = Math.max(values.length, 1);
  #|  const max = Math.max(...values, 1);
  #|  const bw = Math.min(48, (W - PAD * 2) / n - 8);
  #|  let rects = '';
  #|  values.forEach((v, i) => {
  #|    const x = PAD + (W - PAD * 2) * (i + 0.5) / n - bw / 2;
  #|    const h = Math.max(2, (H - LBL - 10) * v / max);
  #|    rects += `<rect x="${x}" y="${H - LBL - h}" width="${bw}" height="${h}" rx="4"></rect>`;
  #|    const lbl = labels[i] !== undefined ? esc(labels[i]) : '';
  #|    rects += `<text x="${x + bw / 2}" y="${H - 4}">${lbl}</text>`;
  #|  });
  #|  return `<svg class="bars" viewBox="0 0 ${W} ${H}" preserveAspectRatio="none">${rects}</svg>`;
  #|}
  #|
  #|function sectionHTML(s) {
  #|  const title = s.title !== undefined
  #|    ? `<h3>${esc(s.title)}</h3>`
  #|    : '<div class="skeleton" style="width:35%"></div><div style="height:10px"></div>';
  #|  let body = '<div class="skeleton big"></div>';
  #|  switch (s.kind) {
  #|    case 'text':
  #|      body = s.text !== undefined ? `<p>${esc(s.text)}</p>`
  #|        : '<div class="skeleton"></div>';
  #|      break;
  #|    case 'metric':
  #|      body = s.value !== undefined
  #|        ? `<div class="metric">${esc(s.value)}<span class="unit">${esc(s.unit ?? '')}</span></div>`
  #|        : '<div class="skeleton big"></div>';
  #|      break;
  #|    case 'list':
  #|      body = (s.items && s.items.length)
  #|        ? `<ul>${s.items.map(i => `<li>${esc(i)}</li>`).join('')}</ul>`
  #|        : '<div class="skeleton"></div>';
  #|      break;
  #|    case 'bar_chart':
  #|      body = (s.values && s.values.length)
  #|        ? barChart(s.labels ?? [], s.values)
  #|        : '<div class="skeleton big" style="width:100%"></div>';
  #|      break;
  #|  }
  #|  return title + body;
  #|}
  #|
  #|function render(state) {
  #|  const titleEl = $('title');
  #|  if (state.title !== undefined) titleEl.textContent = state.title;
  #|  else titleEl.innerHTML = '<div class="skeleton title-line"></div>';
  #|
  #|  const board = $('board');
  #|  const sections = state.sections ?? [];
  #|  sections.forEach((s, i) => {
  #|    let card = board.children[i];
  #|    if (!card || !card.classList.contains('card') || card.classList.contains('ghost-card')) {
  #|      card = document.createElement('div');
  #|      card.className = 'card';
  #|      board.insertBefore(card, board.children[i] ?? null);
  #|    }
  #|    const json = JSON.stringify(s);
  #|    if (prevSections[i] === json) return;   // unchanged: skip DOM work
  #|    prevSections[i] = json;
  #|    card.classList.toggle('wide', s.kind === 'bar_chart' || s.kind === 'text');
  #|    card.innerHTML = sectionHTML(s);
  #|  });
  #|  // drop extra cards (incl. previous ghost), then re-add ghost while streaming
  #|  while (board.children.length > sections.length) board.lastChild.remove();
  #|  if (streaming) {
  #|    const ghost = document.createElement('div');
  #|    ghost.className = 'card ghost-card';
  #|    ghost.innerHTML = '<div class="skeleton" style="width:35%"></div>' +
  #|      '<div style="height:10px"></div><div class="skeleton big"></div>';
  #|    board.appendChild(ghost);
  #|  }
  #|}
  #|
  #|function stop(err, msg) {
  #|  streaming = false;
  #|  if (es) { es.close(); es = null; }
  #|  document.querySelectorAll('.ghost-card').forEach(g => g.remove());
  #|  $('go').disabled = false;
  #|  const st = $('status');
  #|  st.className = err ? 'error' : '';
  #|  st.textContent = err ? ('エラー: ' + (msg || '接続が中断されました')) : '完了';
  #|}
  #|
  #|function start() {
  #|  const q = $('q').value.trim();
  #|  if (!q || streaming) return;
  #|  if (es) es.close();
  #|  prevSections = [];
  #|  streaming = true;
  #|  $('board').innerHTML = '';
  #|  $('status').textContent = '生成中…';
  #|  $('status').className = '';
  #|  $('go').disabled = true;
  #|  render({});
  #|  es = new EventSource('/generate?q=' + encodeURIComponent(q));
  #|  es.onmessage = (e) => {
  #|    let state;
  #|    try { state = JSON.parse(e.data); } catch { return; }
  #|    render(state);
  #|  };
  #|  es.addEventListener('done', () => stop(false));
  #|  es.addEventListener('error', (e) => stop(true, e.data));
  #|  es.onerror = () => { if (streaming) stop(true); };
  #|}
  #|
  #|$('go').onclick = start;
  #|$('q').addEventListener('keydown', (e) => { if (e.key === 'Enter') start(); });
  #|</script>
  #|</body>
  #|</html>
