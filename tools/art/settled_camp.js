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
//   pots, cloth_line, cloth_dyed, loom, low_wall, green_stones, hens      what answers and
//   west_kiln, west_well, west_scarecrow, west_roof_a, west_roof_b       milestones put on the
//                                 ground (SceneProps decides when each shows)
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

// ---- what the answers put on the ground (docs/ages.md V10, PR B) ---------------------------------
var POT = '#c96a42', POTL = '#e08a5c', POTD = '#8a3a22', CLOTH = '#efe6cf', CLOTHD = '#cdc0a0', RED = '#c0504a', REDD = '#8f3a2d';

// Fired pots, 18x10: a big one, a smaller one and a bowl, with a dark mouth each.
function pots(b) {
  b.ell(5, 6, 4.5, 3.8, POT); b.rect(2, 1, 6, 2, POT); b.rect(2, 1, 6, 1, POTL); b.rect(3, 2, 4, 1, '#2a2433'); b.px(3, 5, POTL); b.px(7, 8, POTD);
  b.ell(12, 7, 3.2, 2.8, POT); b.rect(10, 3, 5, 2, POT); b.rect(10, 3, 5, 1, POTL); b.rect(11, 4, 3, 1, '#2a2433'); b.px(11, 7, POTL);
  b.rect(14, 7, 4, 3, POT); b.rect(14, 7, 4, 1, POTL); b.rect(15, 8, 2, 1, '#2a2433'); b.px(17, 9, POTD);
  b.rect(0, 9, 18, 1, POTD);
}

// A kiln, 26x26: a clay dome with a dark mouth, a hole at the top and a thread of smoke.
function kiln(b) {
  b.ell(13, 19, 12, 8, '#c27a52'); b.rect(1, 19, 24, 7, '#c27a52'); b.ell(10, 15, 6, 3, '#d99466');
  b.rect(1, 24, 24, 2, '#9a5a3a');
  b.ell(13, 22, 4.5, 4, '#2a2433'); b.rect(9, 22, 9, 4, '#2a2433'); b.rect(11, 20, 5, 1, '#e0614a'); b.px(13, 22, '#f59e2b');
  b.rect(11, 9, 5, 3, '#9a5a3a'); b.rect(12, 9, 3, 1, '#2a2433');
  b.ell(13, 6, 2.2, 1.8, '#cfd4da'); b.ell(15, 3, 2.6, 2, '#dfe3e8'); b.ell(13, 1, 2.2, 1.5, '#eef0f3');
}

// Cloth drying on a line, 40x17: two posts, a cord, and three pieces of undyed cloth.
function cloth(b, only) {
  var xs = [5, 16, 27], i, x;
  if (!only) {
    b.rect(1, 0, 2, 17, WOOD); b.rect(37, 0, 2, 17, WOOD); b.line(2, 2, 38, 3, '#f0e4c0', 1);
  }
  for (i = 0; i < xs.length; i++) {
    if (only && i != 1) continue;
    x = xs[i];
    b.rect(x, 3, 8, 9 + (i % 2), only ? RED : CLOTH); b.rect(x + 5, 4, 3, 8 + (i % 2), only ? REDD : CLOTHD);
    b.rect(x, 12 + (i % 2), 8, 1, only ? REDD : CLOTHD); b.px(x + 1, 13 + (i % 2), only ? RED : CLOTH); b.px(x + 4, 13 + (i % 2), only ? RED : CLOTH);
  }
}
function clothline(b) { cloth(b, false); }
function dyedcloth(b) { cloth(b, true); }

// An upright loom, 16x16: two posts, a beam top and bottom, taut warp threads and a woven band.
function loom(b) {
  var x;
  b.rect(1, 0, 2, 16, WOOD); b.rect(13, 0, 2, 16, WOOD); b.rect(1, 1, 14, 2, WOODL); b.rect(1, 13, 14, 2, WOODL);
  for (x = 4; x < 13; x += 2) b.rect(x, 3, 1, 10, CLOTH);
  b.rect(3, 9, 10, 2, RED); b.rect(3, 11, 10, 1, '#e8c24a'); b.rect(3, 8, 10, 1, REDD);
  for (x = 4; x < 13; x += 2) { b.px(x, 14, '#8a8792'); b.px(x, 15, '#6f6c78'); }
}

// A small roundhouse for the village's growth, 26x19.
function smallhut(b) {
  var x, y;
  b.rect(3, 10, 20, 9, DAUB); b.rect(3, 10, 20, 1, DAUBL); b.rect(3, 17, 20, 2, DAUBD);
  for (x = 5; x < 23; x += 5) b.rect(x, 11, 1, 6, DAUBD);
  b.tri(13, 0, 12, 13, STRAW, STRAWD);
  for (y = 3; y < 12; y += 3) for (x = 13 - Math.round(13 * (y + 1) / 12); x <= 13 + Math.round(13 * (y + 1) / 12); x += 2) b.px(x, y, x < 13 ? STRAWL : STRAWX);
  for (x = 0; x < 26; x += 2) b.px(x, 12, STRAWX);
  b.rect(10, 12, 6, 7, EARTHD); b.rect(11, 13, 4, 6, '#2a2433');
}

// A well, 16x17: a stone ring, a post each side with a crossbar, and a bucket on a rope.
function well(b) {
  b.rect(2, 10, 12, 7, ROCK); b.ell(8, 10, 6, 2.6, '#2a2433'); b.ell(8, 10, 4.5, 1.6, '#3b79ad');
  b.rect(2, 10, 12, 1, ROCKL); b.px(5, 13, ROCKD); b.px(9, 15, ROCKD); b.px(12, 13, ROCKD); b.px(3, 15, ROCKL);
  b.rect(2, 2, 2, 9, WOOD); b.rect(12, 2, 2, 9, WOOD); b.rect(2, 1, 12, 2, WOODL);
  b.line(8, 3, 8, 8, '#c9a66b', 1); b.rect(7, 8, 3, 2, '#8a5a36');
}

// A scarecrow, 12x18, in an old tunic and a straw hat.
function scarecrow(b) {
  b.rect(5, 5, 2, 13, WOOD); b.rect(0, 7, 12, 2, WOOD);
  b.rect(3, 6, 6, 7, '#a8703f'); b.rect(3, 6, 6, 1, '#c58f50'); b.rect(3, 12, 6, 1, '#7a4c28');
  b.ell(6, 4, 2.6, 2.6, '#e8d5a8'); b.px(5, 4, '#1c1917'); b.px(7, 4, '#1c1917');
  b.rect(2, 2, 8, 1, STRAW); b.rect(4, 0, 4, 2, STRAW);
  b.px(0, 9, STRAWL); b.px(11, 9, STRAWL); b.px(1, 10, STRAW); b.px(10, 10, STRAW);
}

// A low wall of fieldstones across the back of the village, 150x9, with a gap for a gate: two
// courses of blocky stones, the upper one offset, each with a pale top edge and dark joints.
function lowwall(b) {
  var row, x, w, h, y, s, tops = ['#b8b5bd', '#a8a5ae', '#c4c1c9'], fills = [ROCK, '#7f7c86', '#8d8a93'];
  for (row = 0; row < 2; row++) {
    y = row == 0 ? 4 : 0; h = 4; x = row == 0 ? 0 : 3;
    while (x < 150) {
      w = 5 + Math.floor(rnd() * 4);
      if (x < 96 && x + w > 84) { x = 96; continue; }
      s = Math.floor(rnd() * 3);
      b.rect(x, y, w - 1, h, fills[s]); b.rect(x, y, w - 1, 1, tops[s]);
      b.px(x, y, '#a8a5ae'); b.px(x + w - 2, y + h - 1, ROCKD); b.rect(x, y + h - 1, w - 1, 1, ROCKD);
      x += w;
    }
  }
  b.rect(0, 8, 150, 1, ROCKD);
}

// A heap of green stone, 14x8.
function greenstones(b) {
  b.ell(5, 5, 4.5, 3, '#3fa88a'); b.ell(10, 5, 3.5, 2.6, '#2a7a64'); b.ell(7, 3, 3, 2, '#5fcfae');
  b.px(5, 3, '#a8f0d8'); b.px(9, 4, '#5fcfae'); b.px(2, 6, '#2a7a64'); b.px(12, 6, '#3fa88a');
}

// Three hens, 20x8.
function hen(b, x0, y0, col, shade) {
  b.ell(x0 + 3, y0 + 3, 3, 2.4, col); b.rect(x0 + 5, y0, 2, 3, col); b.px(x0 + 6, y0 - 1, '#d8483a'); b.px(x0 + 7, y0 + 1, '#e8b53a');
  b.px(x0 + 6, y0 + 1, '#1c1917'); b.rect(x0 + 1, y0 + 2, 2, 2, shade); b.px(x0, y0 + 1, shade); b.px(x0 + 3, y0 + 5, '#e8b53a'); b.px(x0 + 4, y0 + 5, '#e8b53a');
}
function hens(b) { hen(b, 0, 2, CLOTH, CLOTHD); hen(b, 8, 1, '#c9803a', '#a05830'); hen(b, 13, 3, '#8a5a36', '#6a4326'); }

// ---- the river and the flats (docs/ages.md V13, issue #9) ----------------------------------------
var CLAY = '#c27a52', CLAYD = '#9a5a3a', CLAYL = '#d99466', WATER = '#4f93c4', WATERL = '#8cc8e8';

// Clay pits, 24x9: two shallow diggings of wet red clay, a heap beside them and a digging stick.
function claypits(b) {
  b.ell(6, 6, 6, 2.6, CLAYD); b.ell(6, 6, 4.8, 1.8, '#7a3f28'); b.rect(3, 5, 5, 1, CLAY);
  b.ell(16, 7, 5, 2.2, CLAYD); b.ell(16, 7, 3.8, 1.4, '#7a3f28'); b.rect(14, 6, 4, 1, CLAY);
  b.ell(21, 4, 3, 2.6, CLAY); b.ell(20, 3, 2, 1.6, CLAYL); b.px(22, 5, CLAYD);
  b.rect(11, 0, 1, 7, WOOD); b.px(11, 0, WOODL); b.rect(10, 6, 3, 1, CLAYD);
}

// Flax soaking in the shallows, 20x9: sheaves weighted with stones, half under the water.
function flaxsoak(b) {
  var i, x;
  b.rect(0, 5, 20, 4, WATER); b.rect(1, 6, 5, 1, WATERL); b.rect(11, 7, 6, 1, WATERL);
  for (i = 0; i < 3; i++) {
    x = 1 + i * 6;
    b.rect(x, 1 + (i % 2), 5, 5, '#c9b24a'); b.rect(x, 1 + (i % 2), 5, 1, '#e6d479'); b.px(x + 2, 6, '#7f9a3f');
    b.rect(x + 1, 6 + (i % 2), 3, 1, '#a8923a');
    b.rect(x + 1, 0 + (i % 2), 3, 1, '#9fb04a');
  }
  b.rect(2, 2, 2, 2, ROCK); b.px(2, 2, ROCKL); b.rect(14, 3, 3, 2, ROCK); b.px(14, 3, ROCKL); b.px(8, 3, ROCKD);
}

// Flax beaten out on the bank, 20x9: a flat stone, a heap of pale fibre and a wooden mallet.
function flaxbeaten(b) {
  b.ell(9, 6, 8, 2.6, ROCK); b.rect(2, 4, 14, 1, ROCKL);
  b.ell(8, 3, 6, 2.4, '#efe6cf'); b.ell(7, 2, 4, 1.6, '#f7f1e0'); b.px(11, 4, CLOTHD); b.px(5, 3, CLOTHD);
  b.line(14, 0, 18, 5, WOOD, 1); b.rect(13, 0, 4, 2, WOODL);
  b.px(0, 7, '#c9b24a'); b.px(1, 8, '#a8923a'); b.px(18, 7, '#c9b24a');
}

// The raised bank along the near edge of the river, 30x18, built up with earth and faced with
// stones. It follows the bank's slant: the river's left edge is x = 327 - 1.217 (y - 56).
function riverbank(b) {
  var y, x, ex;
  for (y = 0; y < 18; y++) {
    ex = Math.round(327 - (y + 62 - 56) * 1.217) - 291;   // the water's edge in this sprite's x
    for (x = ex - 10; x < ex - 1; x++) b.px(x, y, y == 0 ? '#8c5f31' : (x < ex - 8 ? EARTHD : EARTH));
    b.px(ex - 1, y, y % 2 ? ROCK : ROCKD); b.px(ex - 2, y, y % 2 ? ROCKL : ROCK);
    if (y % 3 == 1) b.px(ex - 5, y, EARTHD);
  }
}

// A dugout canoe, 26x8, resting on the water: a hollowed log, pointed at both ends, with a paddle.
function dugout(b) {
  b.ell(13, 4, 12.5, 3, WOOD); b.rect(1, 1, 24, 1, WOODL);
  b.ell(13, 3, 10, 1.4, '#3a2a1f'); b.rect(0, 4, 2, 1, WOODL); b.rect(24, 4, 2, 1, WOODL);
  b.px(6, 5, '#6a4326'); b.px(17, 5, '#6a4326');
  b.line(9, 0, 13, 4, WOODL, 1); b.rect(8, 0, 2, 2, WOODL);
  b.rect(0, 7, 26, 1, WATERL); b.rect(3, 6, 20, 1, WATER);
}

// A reed raft, 24x7: three fat bundles lashed together with cord, low in the water.
function reedraft(b) {
  var i;
  for (i = 0; i < 3; i++) {
    b.rect(0 + i, 1 + i, 22, 2, i == 1 ? '#b8a84a' : '#a8923a'); b.rect(0 + i, 1 + i, 22, 1, '#d9c868');
  }
  b.rect(4, 0, 1, 6, '#8a5a36'); b.rect(11, 0, 1, 6, '#8a5a36'); b.rect(18, 0, 1, 6, '#8a5a36');
  b.line(22, 1, 23, 5, '#8a5a36', 1);
  b.rect(1, 6, 22, 1, WATERL);
}

// A fish weir of stones on the flats, 20x8: two curved arms of piled stones meeting in a point,
// with a few fish held in the pool between.
function weir(b) {
  var i, y, x;
  for (i = 0; i < 8; i++) {
    y = i; x = Math.round(i * i / 5);
    b.rect(x, y, 3, 1, i % 2 ? ROCK : ROCKD); b.px(x, y, ROCKL);
    b.rect(19 - x - 2, y, 3, 1, i % 2 ? ROCKD : ROCK); b.px(19 - x, y, ROCKL);
  }
  b.rect(6, 5, 8, 2, '#7cc0d8'); b.px(8, 5, '#cfd8e0'); b.px(11, 6, '#cfd8e0'); b.px(10, 4, '#cfd8e0');
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
// what the answers put on the ground: camp page first, then the west page (page-local x)
layers.pots = layerOf([obj(18, 10, 178, 79, pots, { sh: 8 })]);
layers.cloth_line = layerOf([obj(40, 17, 158, 67, clothline, { sh: 0 })]);
layers.cloth_dyed = layerOf([obj(40, 17, 158, 67, dyedcloth, { sh: 0, z: 68 })]);
layers.loom = layerOf([obj(16, 16, 192, 77, loom, { sh: 7 })]);
layers.low_wall = layerOf([obj(150, 9, 179, 63, lowwall, { sh: 0 })]);
layers.green_stones = layerOf([obj(14, 8, 9, 79, greenstones, { sh: 6 })]);
layers.hens = layerOf([obj(20, 8, 262, 79, hens, { sh: 0 })]);
layers.west_kiln = layerOf([obj(26, 26, 292, 78, kiln, { sh: 12 })]);
layers.west_well = layerOf([obj(16, 17, 268, 77, well, { sh: 8 })]);
layers.west_scarecrow = layerOf([obj(12, 18, 234, 76, scarecrow, { sh: 4 })]);
layers.west_roof_a = layerOf([obj(26, 19, 172, 72, smallhut, { sh: 11 })]);
layers.west_roof_b = layerOf([obj(26, 19, 148, 71, smallhut, { sh: 11, flip: 1 })]);
// the river (camp page; the weir is on the east page, page-local x)
layers.clay_pits = layerOf([obj(24, 9, 262, 79, claypits, { sh: 9 })]);
layers.flax_thread = layerOf([obj(20, 9, 312, 72, flaxsoak, { sh: 0 })]);
layers.flax_beaten = layerOf([obj(20, 9, 296, 74, flaxbeaten, { sh: 8 })]);
layers.river_bank = layerOf([obj(30, 18, 306, 80, riverbank, { sh: 0 })]);
layers.boat_dugout = layerOf([obj(26, 8, 352, 70, dugout, { sh: 0 })]);
layers.boat_raft = layerOf([obj(24, 7, 352, 70, reedraft, { sh: 0 })]);
layers.east_tide_weir = layerOf([obj(20, 8, 258, 78, weir, { sh: 0 })]);

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
