// @open art/reference/settled_camp.png
// @canvas 384x80
// Settled Age world pieces (docs: ages V10): what the camp gains, or upgrades in place, when the
// settlement stays. The cave world (cave_strip.js, cave_pages.js) is kept; these sit on top of it
// or replace one slot's art. Game assets (game/assets/world/settled/), each a full 384x80
// transparent PNG so every piece already sits at its final position:
//   building_hut, site_hut        a thatched roundhouse and its construction site (camp slot)
//   building_field, site_field    a field of ripe wheat and its site (camp slot)
//   west_plot_farm, west_plot_patch   the sown plot at the west meadow's edge: the farmers' bigger
//                                 one and the herders' small patch (west page: sprite at x = -384)
//   west_pen                      the herders' fenced pen and its animals (west page)
// Slots are mirrored in game/scripts/view/world_layout.gd (BUILDINGS, SceneProps): change both
// together. Preview: art/reference/settled_camp.png.
seed = 41;
var W = 384, H = 80, G = 56;
var GAME = DIR + 'game/assets/world/settled/';
var IMG = SPR.layer(0).cel(0).image;

function obj(w, h, cx, foot, fn, o) { o = o || {}; return { w: w, h: h, x: cx - Math.floor(w / 2), y: foot - h, fn: fn, flip: o.flip, sh: o.sh, fy: o.z || foot, foot: foot, cx: cx }; }
function drawObj(buf, ob) { // shadow, then the outlined sprite
  if (ob.sh) buf.ell(ob.cx, ob.foot, ob.sh, 1.5, '#5f8236');
  var tb = new Buf(ob.w, ob.h); ob.fn(tb); if (ob.flip) tb = mirror(tb);
  blit(buf, outlined(tb, OUT), ob.x - 1, ob.y - 1);
}
function layerOf(list) { var b = new Buf(W, H); list.sort(function (p, q) { return p.fy - q.fy; }); for (var k = 0; k < list.length; k++) drawObj(b, list[k]); return b; }

var DAUB = '#dcc08f', DAUBL = '#ecd6ac', DAUBD = '#bf9f6f', STRAW = '#d9b858', STRAWL = '#ebd07a', STRAWD = '#b8923f', STRAWX = '#9a7a30';
var EARTH = '#8a5a36', EARTHD = '#6f4528', WHEAT = '#e8c24a', WHEATL = '#f7e08a', WHEATD = '#c4992a';

// Thatched roundhouse, 34x24: a daub wall with a plank door under a deep straw cone.
function roundhouse(b) {
  var x, y;
  b.rect(4, 13, 26, 11, DAUB); b.rect(4, 13, 26, 1, DAUBL); b.rect(4, 22, 26, 2, DAUBD);
  for (x = 6; x < 30; x += 5) b.rect(x, 14, 1, 8, DAUBD); // wattle showing through
  for (x = 4; x < 30; x += 3) b.px(x, 23, '#a8a5ae'); // stone footing
  b.tri(17, 0, 15, 17, STRAW, STRAWD);
  for (y = 3; y < 15; y += 3) for (x = 17 - Math.round(17 * (y + 1) / 15); x <= 17 + Math.round(17 * (y + 1) / 15); x += 2) b.px(x, y, x < 17 ? STRAWL : STRAWX);
  for (x = 0; x < 34; x += 2) b.px(x, 15, STRAWX); // the ragged eave
  b.px(17, 0, '#6f4528'); b.rect(17, 0, 1, 2, '#6f4528');
  b.rect(13, 15, 8, 9, EARTHD); b.rect(14, 16, 6, 8, '#2a2433'); b.rect(13, 15, 8, 1, EARTH);
  b.rect(13, 16, 1, 8, EARTH); b.rect(20, 16, 1, 8, EARTH);
  b.px(24, 17, '#2a2433'); b.px(24, 18, '#2a2433'); // a small window
}

// Construction site, 24x12: a ring of posts half woven with withies, and a bundle of reed.
function hutsite(b) {
  var x;
  b.rect(2, 2, 1, 10, EARTH); b.rect(8, 3, 1, 9, EARTH); b.rect(15, 3, 1, 9, EARTH); b.rect(21, 2, 1, 10, EARTH);
  for (x = 2; x <= 20; x++) { b.px(x, 9, x % 2 ? '#d9a566' : '#c58f50'); b.px(x, 7, x % 2 ? '#c58f50' : '#d9a566'); }
  b.px(2, 2, '#e0614a'); b.px(21, 2, '#e0614a');
  b.rect(10, 10, 12, 2, STRAW); b.rect(12, 8, 8, 2, STRAWL);
}

// A field of ripe wheat, 48x12, with a stake at each corner.
function wheatfield(b) {
  var x, r;
  b.rect(0, 3, 48, 9, EARTH);
  for (r = 0; r < 3; r++) b.rect(0, 5 + r * 3, 48, 1, EARTHD);
  for (r = 0; r < 3; r++) for (x = 2 + (r % 2) * 2; x < 46; x += 4) {
    var h = 4 + ((x * 7 + r) % 3);
    b.rect(x, 5 + r * 3 - h + 1, 1, h, WHEATD); b.px(x, 5 + r * 3 - h, WHEATL); b.px(x - 1, 5 + r * 3 - h + 1, WHEAT); b.px(x + 1, 5 + r * 3 - h + 2, WHEAT);
  }
  b.rect(0, 1, 1, 6, WOOD); b.rect(47, 1, 1, 6, WOOD); b.rect(0, 8, 1, 4, WOOD); b.rect(47, 8, 1, 4, WOOD);
}

// Field construction site, 24x12: a plot marked with stakes and cord, the first rows turned.
function fieldsite(b) {
  var r;
  b.rect(0, 5, 24, 7, EARTH);
  for (r = 0; r < 2; r++) { b.rect(0, 5 + r * 3, 24, 2, '#a8764a'); b.rect(0, 7 + r * 3, 24, 1, EARTHD); }
  b.px(5, 6, '#c58f50'); b.px(14, 9, '#c58f50'); b.px(18, 6, '#c58f50');
  b.rect(1, 1, 1, 6, WOOD); b.px(1, 1, '#e0614a'); b.rect(22, 1, 1, 6, WOOD); b.px(22, 1, '#e0614a');
  b.line(1, 3, 22, 3, '#f0e4c0', 1);
}

// The farmers' sown plot, 58x12: rows of young green shoots behind a low brush fence.
function sownplot(b) {
  var x, r;
  b.rect(0, 3, 58, 9, EARTH);
  for (r = 0; r < 3; r++) b.rect(0, 5 + r * 3, 58, 1, EARTHD);
  for (r = 0; r < 3; r++) for (x = 2 + (r % 2) * 2; x < 56; x += 4) { b.px(x, 4 + r * 3, '#9bdf6a'); b.px(x, 5 + r * 3, '#6fbf4a'); }
  for (x = 0; x < 58; x += 6) { b.rect(x, 0, 1, 4, WOOD); b.px(x, 0, WOODL); }
  b.rect(0, 1, 58, 1, '#8c5f31'); b.rect(0, 2, 58, 1, '#6f4528');
}

// The herders' small patch, 26x9: a few rows, just enough to say the group has sown something.
function patch(b) {
  var x, r;
  b.rect(0, 2, 26, 7, EARTH);
  for (r = 0; r < 2; r++) b.rect(0, 5 + r * 3, 26, 1, EARTHD);
  for (r = 0; r < 2; r++) for (x = 3 + r * 2; x < 24; x += 4) { b.px(x, 3 + r * 3, '#9bdf6a'); b.px(x, 4 + r * 3, '#6fbf4a'); }
  b.rect(0, 0, 1, 4, WOOD); b.rect(25, 0, 1, 4, WOOD); b.rect(0, 1, 26, 1, '#8c5f31');
}

// A goat, 11x8, facing right. Fur colours are passed in.
function goat(b, x0, y0, fur, shade) {
  b.rect(x0 + 2, y0 + 2, 7, 3, fur); b.rect(x0 + 2, y0 + 4, 7, 1, shade);
  b.rect(x0 + 8, y0, 3, 3, fur); b.px(x0 + 10, y0 + 2, shade); b.px(x0 + 8, y0 - 1, '#6f6a60'); b.px(x0 + 9, y0 - 1, '#6f6a60');
  b.px(x0 + 9, y0 + 1, '#1c1917');
  b.rect(x0 + 2, y0 + 5, 1, 3, '#5a4a3a'); b.rect(x0 + 4, y0 + 5, 1, 3, '#5a4a3a');
  b.rect(x0 + 7, y0 + 5, 1, 3, '#5a4a3a'); b.rect(x0 + 8, y0 + 5, 1, 2, '#5a4a3a');
  b.px(x0 + 1, y0 + 2, shade);
}

// The pen, 56x22: a woven fence round trampled earth with three goats.
function pen(b) {
  var x;
  b.ell(28, 16, 28, 5, '#b89a6a'); b.ell(28, 16, 24, 3.6, '#c9ad7d');
  for (x = 1; x < 56; x += 6) b.rect(x, 3, 1, 9, EARTH);
  b.rect(1, 5, 55, 1, '#8c5f31'); b.rect(1, 8, 55, 1, '#6f4528');
  goat(b, 8, 8, '#efe6cf', '#cdc0a0'); goat(b, 26, 10, '#8a5a36', '#6a4326'); goat(b, 40, 8, '#b4b1b9', '#8a8792');
  for (x = 1; x < 56; x += 12) b.rect(x, 14, 1, 5, EARTH);
  b.rect(1, 16, 55, 1, '#a6703f');
}

var layers = {};
// camp slots: [w, h, cx, foot, draw, shadow]
var HUT = [34, 24, 268, 71, roundhouse, 14], HUTSITE = [24, 12, 268, 71, hutsite, 9];
var FIELD = [48, 12, 226, 78, wheatfield, 0], FIELDSITE = [24, 12, 226, 78, fieldsite, 0];
layers.building_hut = layerOf([obj(HUT[0], HUT[1], HUT[2], HUT[3], HUT[4], { sh: HUT[5] })]);
layers.site_hut = layerOf([obj(HUTSITE[0], HUTSITE[1], HUTSITE[2], HUTSITE[3], HUTSITE[4], { sh: HUTSITE[5] })]);
layers.building_field = layerOf([obj(FIELD[0], FIELD[1], FIELD[2], FIELD[3], FIELD[4], { sh: FIELD[5] })]);
layers.site_field = layerOf([obj(FIELDSITE[0], FIELDSITE[1], FIELDSITE[2], FIELDSITE[3], FIELDSITE[4], { sh: FIELDSITE[5] })]);
// west page props: page-local x = world x + 384
layers.west_plot_farm = layerOf([obj(58, 12, 234, 78, sownplot, { z: 55 })]);
layers.west_plot_patch = layerOf([obj(26, 9, 234, 78, patch, { z: 55 })]);
layers.west_pen = layerOf([obj(56, 22, 354, 77, pen, { sh: 0 })]);

// preview: every piece on a plain meadow (the camp slots at their camp x, the west props shown at
// the page-local x they have in the file)
var P = new Buf(W, H), name, y, x;
for (y = 0; y < G; y++) for (x = 0; x < W; x++) P.px(x, y, '#9cc4de');
for (y = G; y < H; y++) for (x = 0; x < W; x++) P.px(x, y, y < G + 13 ? '#86a94c' : '#789a43');
for (name in layers) blit(P, layers[name], 0, 0);
IMG.putImageData(P.d); SPR.save();
SPR.saveAs(DIR + 'art/reference/settled_camp.png');
var count = 0;
for (name in layers) { IMG.putImageData(layers[name].d); SPR.saveAs(GAME + name + '.png'); count++; }
console.log('settled camp done, ' + count + ' game layers');
