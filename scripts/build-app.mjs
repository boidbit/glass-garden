// Builds the app's copy of the game in www/: the same index.html, but with three.js, cannon-es and the
// title font served from the app itself, so the game works offline inside the Android app.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const www = path.join(root, 'www');
const nm = path.join(root, 'node_modules');

fs.rmSync(www, { recursive: true, force: true });
fs.mkdirSync(path.join(www, 'vendor', 'fonts'), { recursive: true });

const copy = (from, to) => {
  fs.mkdirSync(path.dirname(to), { recursive: true });
  fs.cpSync(from, to, { recursive: true });
};

// libraries
copy(path.join(nm, 'three', 'build', 'three.module.js'), path.join(www, 'vendor', 'three', 'three.module.js'));
for (const dir of ['postprocessing', 'shaders', 'environments', 'utils', 'geometries']) {
  copy(path.join(nm, 'three', 'examples', 'jsm', dir), path.join(www, 'vendor', 'three', 'addons', dir));
}
copy(path.join(nm, 'cannon-es', 'dist', 'cannon-es.js'), path.join(www, 'vendor', 'cannon-es.js'));

// the title font
const fontDir = path.join(nm, '@fontsource', 'bricolage-grotesque', 'files');
const faces = [];
for (const w of [600, 800]) {
  const f = `bricolage-grotesque-latin-${w}-normal.woff2`;
  copy(path.join(fontDir, f), path.join(www, 'vendor', 'fonts', f));
  faces.push(`@font-face { font-family: "Bricolage Grotesque"; font-style: normal; font-weight: ${w}; font-display: swap; src: url("./${f}") format("woff2"); }`);
}
fs.writeFileSync(path.join(www, 'vendor', 'fonts', 'fonts.css'), faces.join('\n') + '\n');

// the page
let html = fs.readFileSync(path.join(root, 'index.html'), 'utf8');
const swaps = [
  [/<link rel="preconnect" href="https:\/\/fonts\.googleapis\.com">\n?/, ''],
  [/<link rel="preconnect" href="https:\/\/fonts\.gstatic\.com" crossorigin>\n?/, ''],
  [/<link rel="stylesheet" href="https:\/\/fonts\.googleapis\.com\/css2[^"]*">/, '<link rel="stylesheet" href="./vendor/fonts/fonts.css">'],
  ['https://cdn.jsdelivr.net/npm/three@0.170.0/build/three.module.js', './vendor/three/three.module.js'],
  ['https://cdn.jsdelivr.net/npm/three@0.170.0/examples/jsm/', './vendor/three/addons/'],
  ['https://cdn.jsdelivr.net/npm/cannon-es@0.20.0/dist/cannon-es.js', './vendor/cannon-es.js'],
  // inside the app there is no internet to blame if loading fails
  ['The room could not load. Check your internet connection and refresh the page.', 'The room could not load. Please close and reopen the app.'],
];
for (const [a, b] of swaps) {
  const before = html;
  html = html.replace(a, b);
  if (html === before && b !== '') throw new Error('build-app: could not find ' + a);
}
if (html.includes('cdn.jsdelivr.net') || html.includes('fonts.googleapis.com')) throw new Error('build-app: a web address is still in the page');
// the app sets its own colours for the phone's system bars
html = html.replace('<meta name=viewport', '<meta name="theme-color" content="#0b141c"><meta name=viewport');
fs.writeFileSync(path.join(www, 'index.html'), html);
console.log('www/ ready:', fs.readdirSync(www).join(', '));
