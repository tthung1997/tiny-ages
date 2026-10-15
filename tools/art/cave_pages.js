// @open art/reference/cave_west.png
// @canvas 384x80
// Cave Age world, the two side pages (docs: engine-and-art A8, ages V5). The camp page is
// cave_strip.js; this draws the page to its west (a pine forest rising to a snowy ridge: the
// hunting grounds) and the page to its east (the camp's river, a spit that runs from grass into
// a wide sandy beach with palms, and the open sea off the right edge; issue #17).
//
// Seams: every curve is a function of the WORLD x (camp page is 0..384, west is -384..0, east is
// 384..768), so the hills, sky bands and tree line meet the camp's edges without a jump.
//
// Previews: art/reference/cave_west.png, cave_east.png. Game assets (game/assets/world/cave/),
// each a full 384x80 transparent PNG:
//   west_<layer>, east_<layer>   sky, far_hills, near_hills, trees, ground
//   west_static_back/_mid, east_static_mid   always-present props (back is behind villagers)
//   east_sea_0.._2   the sea alone (transparent elsewhere) in three surf and swell phases; the
//                    game swaps them over east_ground, which carries phase 0 itself
// Layout notes are mirrored in game/scripts/view/world_layout.gd.
seed = 31;
var W = 384, H = 80, G = 56;
var GAME = DIR + 'game/assets/world/cave/';
var IMG = SPR.layer(0).cel(0).image;

function smooth(a, b, v) { var t = (v - a) / (b - a); t = t < 0 ? 0 : (t > 1 ? 1 : t); return t * t * (3 - 2 * t); }
function obj(w, h, cx, foot, fn, o) { o = o || {}; return { w: w, h: h, x: cx - Math.floor(w / 2), y: foot - h, fn: fn, flip: o.flip, sh: o.sh, shc: o.shc, fy: o.z || foot, foot: foot, cx: cx }; }
function drawObj(buf, ob) { // shadow, then the outlined sprite
  if (ob.sh) buf.ell(ob.cx, ob.foot, ob.sh, 1.5, ob.shc || '#5f8236');
  var tb = new Buf(ob.w, ob.h); ob.fn(tb); if (ob.flip) tb = mirror(tb);
  blit(buf, outlined(tb, OUT), ob.x - 1, ob.y - 1);
}
function layerOf(list) { var b = new Buf(W, H); list.sort(function (p, q) { return p.fy - q.fy; }); for (var k = 0; k < list.length; k++) drawObj(b, list[k]); return b; }

// ---- shared pieces, in the camp's palette -----------------------------------------------
var skyCols = ['#86b4d6', '#9cc4de', '#b4d4e6', '#cde2ee', '#e4eef3'];
function drawSky(S) {
  for (var y = 0; y < G; y++) {
    var bi = Math.min(4, Math.floor(y / 11)), t = y % 11;
    for (var x = 0; x < W; x++) { var c = skyCols[bi]; if (t >= 9 && bi < 4 && ((x + y) & 1) == 0) c = skyCols[bi + 1]; S.px(x, y, c); }
  }
}
function drawFar(F, off, bump) { // snow-capped far range; `bump(wx)` raises (negative) or sinks it
  for (var x = 0; x < W; x++) {
    var wx = x + off, r1 = Math.round(33 + 6 * Math.sin(wx / 41) + 3 * Math.sin(wx / 15 + 1) + bump(wx));
    for (var y = Math.max(r1, 0); y < G; y++) {
      var snow = r1 < 34 && y < r1 + 3;
      F.px(x, y, snow ? (y < r1 + 1 ? '#f4f8fb' : '#dbe6ee') : (y < r1 + 1 ? '#b3c4d1' : '#9fb2c2'));
    }
  }
}
function drawNear(N, off, bump) {
  for (var x = 0; x < W; x++) {
    var wx = x + off, r2 = Math.round(46 + 4 * Math.sin(wx / 29 + 2) + 1.5 * Math.sin(wx / 11) + bump(wx));
    for (var y = r2; y < G; y++) N.px(x, y, y < r2 + 1 ? '#a9c49c' : '#8eab85');
  }
}
function clearBelowGround(T) { for (var y = G; y < H; y++) for (var x = 0; x < W; x++) T.d[(y * W + x) * 4 + 3] = 0; }
function landBands(Gd, from, to, x0, x1) {
  for (var y = G; y < H; y++) { var gc = y < G + 2 ? '#a4c35c' : (y < G + 13 ? '#86a94c' : '#789a43'); for (var x = x0; x < x1; x++) Gd.px(x, y, gc); }
}

// ---- the west page: forest and ridge -------------------------------------------------------
function westPage() {
  var L = { sky: new Buf(W, H), far_hills: new Buf(W, H), near_hills: new Buf(W, H), trees: new Buf(W, H), ground: new Buf(W, H) };
  var x, y, i, off = -384;
  drawSky(L.sky);
  cloud(L.sky, 90, 14, 1.1); cloud(L.sky, 235, 9, 0.8); cloud(L.sky, 320, 21, 1.3);
  drawFar(L.far_hills, off, function (wx) { return -16 * smooth(-150, -340, wx); }); // a taller snowy ridge in the far west
  drawNear(L.near_hills, off, function (wx) { return 0; });
  // trees: a dark back row, then a front row that is dense in the west and thins towards the camp
  for (x = -4; x < W + 4; x += 5) {
    var tb = x / W, hb = Math.round(21 - 8 * tb) + Math.floor(rnd() * 4);
    if (tb > 0.8 && rnd() < (tb - 0.8) * 4) continue;
    L.trees.tri(x + 2, G - hb, hb, 3, '#2f6244', '#265238');
  }
  for (x = -2; x < W + 4; x += 3) {
    var t = (x + 2) / W, th = Math.round(15 - 7 * t) + Math.floor(rnd() * 5), dense = t < 0.75;
    if (!dense && rnd() < (t - 0.75) * 2.4) continue;
    L.trees.tri(x + 2, G - th, th, 3 + (t < 0.5 ? 1 : 0), dense ? '#37704a' : '#3f7a52', dense ? '#2c5c3d' : '#336544');
  }
  clearBelowGround(L.trees);
  // forest floor: the camp's grass, shaded under the trees, with needles and leaf litter
  landBands(L.ground, 0, 0, 0, W);
  for (i = 0; i < 220; i++) { x = Math.floor(rnd() * W); y = G + 2 + Math.floor(rnd() * (H - G - 2)); var lt = rnd() < 0.5; L.ground.px(x, y, lt ? '#9bbb55' : '#5f8236'); if (rnd() < 0.5) L.ground.px(x, y - 1, lt ? '#9bbb55' : '#5f8236'); }
  for (i = 0; i < 70; i++) {
    x = Math.floor(rnd() * 330); y = G + 3 + Math.floor(rnd() * (H - G - 5));
    if (rnd() < (x / 330) * 0.7) continue; // fewer patches near the camp
    L.ground.ell(x, y, 3 + Math.floor(rnd() * 5), 1.2, '#6d8f3b');
    for (var n = 0; n < 4; n++) L.ground.px(x - 3 + Math.floor(rnd() * 7), y + Math.floor(rnd() * 2), rnd() < 0.5 ? '#a98a58' : '#8f7447');
  }
  for (i = 0; i < 24; i++) { x = Math.floor(rnd() * W); y = G + 4 + Math.floor(rnd() * (H - G - 6)); L.ground.px(x, y, ['#ffffff', '#ffe27a', '#c9a0ff'][Math.floor(rnd() * 3)]); L.ground.px(x, y + 1, '#3a7a3a'); }
  // props: pines in a few lanes (the back lanes sit behind villagers), stumps, a log, bushes
  var backP = [], midP = [], k = 0, lanes = [62, 66, 70, 64, 74, 68, 78, 72];
  for (var px = 10; px < 352; px += 11 + Math.floor(rnd() * 8)) {
    var foot = lanes[k % lanes.length]; k++;
    if (rnd() < (px / W) * 0.7) continue; // sparser towards the camp
    (foot <= 70 ? backP : midP).push(obj(16, 26, px, foot, pine, { sh: 6 }));
  }
  midP.push(obj(10, 8, 318, 77, stump, { sh: 4 }), obj(10, 8, 262, 75, stump, { sh: 4 }), obj(18, 7, 158, 76, fallenlog, { sh: 6 }),
    obj(12, 8, 96, 74, bush, { sh: 5 }), obj(12, 8, 212, 77, bush, { sh: 5 }), obj(12, 8, 346, 72, bush, { sh: 5 }),
    obj(10, 6, 128, 78, rocks, { sh: 4 }), obj(10, 6, 288, 79, rocks, { sh: 4 }));
  L.static_back = layerOf(backP);
  L.static_mid = layerOf(midP);
  return L;
}

// ---- the east page: the camp's river, a spit of grass that runs into a beach, and the sea ----
// The river's far bank is 30 px nearer than the first sketch so a crossing is believable and the
// spit has room for props (issue #9); the sea takes the rest of the page.
var SEA_FRAMES = 3;
function riverEdge(y) { return 66 + Math.round((y - G) * 1.2); }                        // where the far bank starts
function shoreEdge(y) { return 205 + (y - G) * 2 + Math.round(Math.sin(y * 1.7)); }      // where the sea starts
var SAND = '#e2d3a6', SAND_MID = '#d8c9a0', SAND_PACK = '#cdbd92', SAND_WET = '#b3a47e';
var BAYER = [0, 2, 3, 1];
// What lies at a land pixel: grass far from the shore, a dithered band where grass and sand mix,
// then dry sand, packed sand and a wet edge.
function landColor(x, y) {
  var re = riverEdge(y), d = shoreEdge(y) - x;
  var gc = y < G + 2 ? '#a4c35c' : (y < G + 13 ? '#86a94c' : '#789a43');
  if (x < re) return SAND_MID;
  if (d <= 2) return (x + y) % 3 == 0 ? '#a69773' : SAND_WET;
  if (d <= 9) return rnd() < 0.12 ? SAND : SAND_PACK;
  if (d <= 30) { var r = rnd(); return r < 0.06 ? '#efe3bb' : (r < 0.14 ? '#d3c394' : SAND); }
  if (d <= 44) { // 25% / 50% / 75% sand, ordered dither
    var level = d <= 35 ? 0.75 : (d <= 40 ? 0.5 : 0.25);
    return level > (BAYER[(x & 1) + 2 * (y & 1)] + 0.5) / 4 ? (rnd() < 0.5 ? SAND : '#cfc58f') : gc;
  }
  return gc;
}
function swellList() { // long, low swell marks (never a vertical or a triangle: nothing that reads as a sail)
  var list = [], i, y, x, len;
  for (i = 0; i < 42; i++) {
    y = G + 2 + Math.floor(rnd() * (H - G - 3)); len = 5 + Math.floor((y - G) / 4) + Math.floor(rnd() * 5);
    x = shoreEdge(y) + 12 + Math.floor(rnd() * (W - shoreEdge(y) - 12 - len - 6));
    if (x + len + 6 < W) list.push({ x: x, y: y, len: len, i: i });
  }
  return list;
}
// Draws the sea (x >= shoreEdge) in surf and swell phase `f` into `B`. Every phase covers the same
// pixels, so the animation never changes what is land.
function paintSea(B, f, swells) {
  var y, x, k;
  for (y = G; y < H; y++) {
    var s = shoreEdge(y);
    for (x = s; x < W; x++) {
      var d = x - s, c = y == G ? '#6da9d2' : (d < 3 ? '#7cc0d8' : (d < 9 ? '#4f9fc9' : (y < G + 5 ? '#3a80b7' : (y < G + 15 ? '#2f6fa8' : '#2a639b'))));
      if (d >= 3 && d < 9 && ((x + y) & 1) == 0) c = '#3f8fbf';
      if (d < 1 + f) c = '#f2fafc';
      else if (d == 1 + f && ((x + y) & 1) == 0) c = '#bfe4ee';
      else if (d == 6 + f * 2 && (x + y) % 3 != 0 && y > G) c = '#cfe9f2';
      B.px(x, y, c);
    }
  }
  for (k = 0; k < swells.length; k++) {
    var w = swells[k], ox = w.x + ((f + w.i) % SEA_FRAMES) * 2;
    B.rect(ox, w.y, w.len, 1, '#5a9fd0');
    if (w.y + 1 < H) B.rect(ox + 1, w.y + 1, w.len - 2, 1, '#25608f');
  }
}
function palm(b) { // 22x24: a leaning trunk and drooping fronds
  b.line(7, 23, 8, 17, WOOD, 2); b.line(8, 17, 10, 12, WOOD, 2); b.line(10, 12, 12, 8, WOOD, 2);
  b.px(7, 20, WOODL); b.px(8, 15, WOODL); b.px(10, 11, WOODL);
  var d = '#2f8545', g = '#3f9a52', t = '#58b05f';
  b.line(12, 9, 6, 5, d, 1); b.line(6, 5, 2, 9, d, 1); b.line(12, 9, 18, 5, d, 1); b.line(18, 5, 21, 9, d, 1);
  b.line(12, 9, 8, 11, d, 1); b.line(12, 9, 17, 11, d, 1);
  b.line(12, 8, 6, 4, g, 1); b.line(6, 4, 2, 8, g, 1); b.line(12, 8, 18, 4, g, 1); b.line(18, 4, 21, 8, g, 1);
  b.line(12, 8, 9, 1, g, 1); b.line(12, 8, 15, 1, g, 1); b.line(12, 8, 8, 10, g, 1); b.line(12, 8, 16, 10, g, 1);
  b.px(2, 8, t); b.px(21, 8, t); b.px(9, 1, t); b.px(15, 1, t); b.px(6, 4, t); b.px(18, 4, t);
  b.px(11, 10, '#6a4326'); b.px(13, 10, '#6a4326');
}
function driftwood(b) { // 11x4 bleached log
  b.rect(0, 1, 11, 2, '#b9a88a'); b.rect(0, 1, 11, 1, '#d8cbb0'); b.px(3, 0, '#b9a88a'); b.px(8, 3, '#9a8a6e'); b.px(10, 1, '#9a8a6e');
}
function eastPage() {
  var L = { sky: new Buf(W, H), far_hills: new Buf(W, H), near_hills: new Buf(W, H), trees: new Buf(W, H), ground: new Buf(W, H) };
  var x, y, i, off = 384;
  drawSky(L.sky);
  cloud(L.sky, 60, 11, 1.0); cloud(L.sky, 190, 20, 1.2); cloud(L.sky, 310, 8, 0.8);
  drawFar(L.far_hills, off, function (wx) { return 14 * smooth(470, 760, wx); });     // the range sinks towards the open water
  drawNear(L.near_hills, off, function (wx) { return 12 * smooth(540, 680, wx); });   // and the near hills vanish at the horizon
  for (x = -2; x < W + 4; x += 4) {
    if (x > 130 && rnd() < smooth(130, 190, x)) continue; // the tree line thins out and stops before the beach
    var th = 6 + Math.floor(rnd() * 5);
    L.trees.tri(x + 2, G - th, th, 2 + Math.floor(rnd() * 2), '#3f7a52', '#336544');
  }
  clearBelowGround(L.trees);
  // ground: the camp's grass where there is land, river and sea elsewhere, sand along every shore
  for (y = G; y < H; y++) {
    var re = riverEdge(y);
    for (x = 0; x < re; x++) {
      var wc = y == G ? '#9fd0ea' : (y < G + 5 ? '#62a8d6' : '#4f93c4');
      L.ground.px(x, y, x < re - 2 ? wc : SAND_MID);
    }
    for (x = re; x < shoreEdge(y); x++) L.ground.px(x, y, landColor(x, y));
  }
  var swells = swellList();
  paintSea(L.ground, 0, swells);
  for (i = 0; i < 160; i++) { // grass tufts, on grass only
    y = G + 2 + Math.floor(rnd() * (H - G - 2)); x = Math.floor(rnd() * W);
    if (x < riverEdge(y) + 2 || x >= shoreEdge(y) - 45) continue;
    var lt = rnd() < 0.5; L.ground.px(x, y, lt ? '#9bbb55' : '#5f8236'); if (rnd() < 0.5) L.ground.px(x, y - 1, lt ? '#9bbb55' : '#5f8236');
  }
  for (i = 0; i < 70; i++) { // dune grass: thick where the grass gives out, thinning towards the water
    y = G + 2 + Math.floor(rnd() * (H - G - 2)); var dd = 12 + Math.floor(rnd() * 32); x = shoreEdge(y) - dd;
    if (x < riverEdge(y) + 2 || rnd() > (dd - 12) / 32) continue;
    var dc = rnd() < 0.5 ? '#9aa85a' : '#74883f'; L.ground.px(x, y, dc); L.ground.px(x, y - 1, dc); if (rnd() < 0.4) L.ground.px(x + 1, y - 2, dc);
  }
  for (i = 0; i < 90; i++) { // river ripples
    y = G + 1 + Math.floor(rnd() * (H - G - 1)); x = Math.floor(rnd() * (W - 3));
    if (x > 1 && x + 2 < riverEdge(y) - 3) L.ground.rect(x, y, 3, 1, rnd() < 0.6 ? '#8cc8e8' : '#3b79ad');
  }
  for (i = 0; i < 14; i++) { // wildflowers on the bank
    y = G + 4 + Math.floor(rnd() * (H - G - 6)); x = riverEdge(y) + 4 + Math.floor(rnd() * 40);
    if (x < shoreEdge(y) - 48) { L.ground.px(x, y, ['#ffffff', '#ffe27a', '#c9a0ff'][Math.floor(rnd() * 3)]); L.ground.px(x, y + 1, '#3a7a3a'); }
  }
  for (i = 0; i < SEA_FRAMES; i++) { L['sea_' + i] = new Buf(W, H); paintSea(L['sea_' + i], i, swells); }
  // props: reeds on the river bank, a pine and bush on the grass, palms and driftwood on the sand
  var midP = [], onSand = { sh: 4, shc: '#bfae83' };
  for (i = 0; i < 8; i++) {
    y = 58 + Math.floor(rnd() * 20);
    var rx = riverEdge(y) + 3 + Math.floor(rnd() * 8);
    midP.push(obj(8, 13, rx, y + 2, reeds, { sh: 3 }));
  }
  midP.push(obj(10, 6, 96, 72, rocks, { sh: 4 }), obj(10, 6, 134, 76, rocks, { sh: 4 }),
    obj(16, 26, 104, 66, pine, { sh: 5 }), obj(16, 26, 128, 77, pine, { sh: 5 }),
    obj(12, 8, 156, 71, bush, { sh: 5 }), obj(12, 8, shoreEdge(75) - 52, 75, bush, { sh: 5 }));
  var palmAt = [[60, 26], [72, 28], [67, 8]];
  for (i = 0; i < palmAt.length; i++) midP.push(obj(22, 24, shoreEdge(palmAt[i][0]) - palmAt[i][1], palmAt[i][0], palm, onSand));
  midP.push(obj(11, 4, shoreEdge(64) - 6, 64, driftwood, { sh: 3, shc: '#bfae83' }),
    obj(11, 4, shoreEdge(75) - 7, 75, driftwood, { sh: 3, shc: '#bfae83', flip: true }),
    obj(10, 6, shoreEdge(77) - 18, 77, rocks, onSand));
  L.static_mid = layerOf(midP);
  return L;
}

// ---- render ---------------------------------------------------------------------------------
function composite(L) {
  var C = new Buf(W, H), stack = [L.sky, L.far_hills, L.near_hills, L.trees, L.ground, L.static_back, L.static_mid];
  for (var i = 0; i < stack.length; i++) if (stack[i]) blit(C, stack[i], 0, 0);
  return C;
}
var west = westPage(), east = eastPage();
IMG.putImageData(composite(west).d); SPR.save();
IMG.putImageData(composite(east).d); SPR.saveAs(DIR + 'art/reference/cave_east.png');
var count = 0, sides = { west: west, east: east };
for (var side in sides) {
  for (var name in sides[side]) { IMG.putImageData(sides[side][name].d); SPR.saveAs(GAME + side + '_' + name + '.png'); count++; }
}
console.log('cave pages done, ' + count + ' game layers');
