// Generate icon.png (256x256) with a soft olive radial-gradient circle + white leaf.
// Pure Node, no dependencies (uses zlib for PNG encoding).
const fs = require('fs');
const zlib = require('zlib');

const SIZE = 256;
const CENTER = SIZE / 2;
const RADIUS = 118;

const LIGHT_SAGE = [0xC5, 0xD8, 0x9D];
const OLIVE = [0x89, 0x98, 0x6D];
const CREAM = [0xF8, 0xF6, 0xEA];
const WHITE = [255, 255, 255];
const VEIN = [0x89, 0x98, 0x6D];

const lerp = (a, b, t) => Math.round(a + (b - a) * t);
const lerpC = (c1, c2, t) => [lerp(c1[0], c2[0], t), lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t)];

// Build RGBA bitmap
const img = Buffer.alloc(SIZE * SIZE * 4); // start transparent (0,0,0,0)
for (let y = 0; y < SIZE; y++) {
  for (let x = 0; x < SIZE; x++) {
    const dx = x - CENTER, dy = y - CENTER;
    const dist = Math.hypot(dx, dy);
    if (dist > RADIUS) continue;
    let t = Math.pow(dist / RADIUS, 0.85);
    let col = lerpC(LIGHT_SAGE, OLIVE, t);
    const hx = (dx + dy) / (RADIUS * 2); // top-left negative
    if (hx < 0) {
      const k = Math.min(0.25, -hx * 0.6 + Math.max(0, 1 - dist / (RADIUS * 0.9)) * 0.18);
      col = lerpC(col, CREAM, k);
    }
    const o = (y * SIZE + x) * 4;
    img[o] = col[0]; img[o + 1] = col[1]; img[o + 2] = col[2]; img[o + 3] = 255;
  }
}

// Leaf polygon (lens along 40-degree axis)
const ANG = 40 * Math.PI / 180;
const cosA = Math.cos(ANG), sinA = Math.sin(ANG);
const px = -sinA, py = cosA;
const LEAF_LEN = 132, HALF_W = 34, N = 120;
const leaf = [];
for (let i = 0; i <= N; i++) {
  const t = i / N;
  const mx = CENTER + (t - 0.5) * LEAF_LEN * cosA;
  const my = CENTER + (t - 0.5) * LEAF_LEN * sinA;
  const hw = HALF_W * Math.sin(Math.PI * t);
  leaf.push([mx + hw * px, my + hw * py]);
}
for (let i = N; i >= 0; i--) {
  const t = i / N;
  const mx = CENTER + (t - 0.5) * LEAF_LEN * cosA;
  const my = CENTER + (t - 0.5) * LEAF_LEN * sinA;
  const hw = HALF_W * Math.sin(Math.PI * t);
  leaf.push([mx - hw * px, my - hw * py]);
}

function inPoly(x, y) {
  let inside = false;
  for (let i = 0, j = leaf.length - 1; i < leaf.length; j = i++) {
    const xi = leaf[i][0], yi = leaf[i][1], xj = leaf[j][0], yj = leaf[j][1];
    if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
}

function putPixel(x, y, rgb, a) {
  x = Math.round(x); y = Math.round(y);
  if (x < 0 || y < 0 || x >= SIZE || y >= SIZE) return;
  const o = (y * SIZE + x) * 4;
  // alpha blend over existing
  const sa = a / 255;
  img[o] = Math.round(rgb[0] * sa + img[o] * (1 - sa));
  img[o + 1] = Math.round(rgb[1] * sa + img[o + 1] * (1 - sa));
  img[o + 2] = Math.round(rgb[2] * sa + img[o + 2] * (1 - sa));
  img[o + 3] = Math.max(img[o + 3], Math.round(a));
}

// fill leaf
for (let y = 0; y < SIZE; y++)
  for (let x = 0; x < SIZE; x++)
    if (inPoly(x + 0.5, y + 0.5)) putPixel(x, y, WHITE, 235);

// vein line
const tip1 = [CENTER - (LEAF_LEN / 2) * cosA, CENTER - (LEAF_LEN / 2) * sinA];
const tip2 = [CENTER + (LEAF_LEN / 2) * cosA, CENTER + (LEAF_LEN / 2) * sinA];
function line(x0, y0, x1, y1, rgb, a, w) {
  const steps = Math.ceil(Math.hypot(x1 - x0, y1 - y0)) * 2;
  for (let i = 0; i <= steps; i++) {
    const t = i / steps;
    const cx = x0 + (x1 - x0) * t, cy = y0 + (y1 - y0) * t;
    for (let oy = -((w - 1) >> 1); oy <= (w - 1) >> 1; oy++)
      for (let ox = -((w - 1) >> 1); ox <= (w - 1) >> 1; ox++)
        putPixel(cx + ox, cy + oy, rgb, a);
  }
}
line(tip1[0], tip1[1], tip2[0], tip2[1], VEIN, 150, 3);
// stem
line(tip1[0], tip1[1], tip1[0] - 6 * cosA, tip1[1] - 6 * sinA, WHITE, 235, 4);

// ---- PNG encode ----
const crcTable = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c >>> 0;
  }
  return t;
})();
function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = crcTable[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length, 0);
  const typeBuf = Buffer.from(type, 'ascii');
  const crcBuf = Buffer.alloc(4); crcBuf.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])), 0);
  return Buffer.concat([len, typeBuf, data, crcBuf]);
}
const sig = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(SIZE, 0); ihdr.writeUInt32BE(SIZE, 4);
ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
// raw scanlines with filter byte 0
const raw = Buffer.alloc(SIZE * (SIZE * 4 + 1));
for (let y = 0; y < SIZE; y++) {
  raw[y * (SIZE * 4 + 1)] = 0;
  img.copy(raw, y * (SIZE * 4 + 1) + 1, y * SIZE * 4, (y + 1) * SIZE * 4);
}
const idat = zlib.deflateSync(raw, { level: 9 });
const png = Buffer.concat([sig, chunk('IHDR', ihdr), chunk('IDAT', idat), chunk('IEND', Buffer.alloc(0))]);
fs.writeFileSync('icon.png', png);
console.log('icon.png written, bytes:', png.length);
