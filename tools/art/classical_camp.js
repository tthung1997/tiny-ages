// @open art/reference/classical_camp.png
// @canvas 384x80
// Classical Age world pieces (docs: ages, "Classical Age"): what the town gains, or upgrades in place, once
// it takes its seat among cities. Cave, Settled, Bronze and Iron art is kept; a slot the Classical Age
// redraws uses the same layer name in its own folder (WorldLayout.piece_path). The look is limestone and
// plaster, terracotta tile, columns and arches: pale and warm where the Iron Age was slate and thatch. The
// camp's big landmark is drawn by signature_landmarks.js. Game assets (game/assets/world/classical/), each
// a full 384x80 transparent PNG, every piece already at its final position (page-local x; world x =
// local - 384 on the west page, + 384 on the east):
//   camp page   building_hut (the Hut's slot redrawn in place: a plastered stone house under tile),
//               the street, laid in slabs from the west edge to the bridge in five pieces (paved_street_market and paved_street_west on the west page, paved_street_hall, paved_street, paved_street_bank on the camp page; one per place, in place of road_camp)
//   west page   west_roof_a / west_roof_b (the village's two small houses redrawn in place),
//               law_pillar (an inscribed pillar at the market's left edge), market_arcade (the square:
//               an arcade of arches under a tiled roof, which takes in the market stalls, the council
//               ring, the writing post and the coin tray), water_court (a basin under arches, in place
//               of the well)
//   east page   east_theatre (a two-storey arcade with stepped seats over it, on the back lane), east_harbour (a stone
//               mole with a lighthouse and moored ships, in place of the deep-keeled ship)
// Slots are mirrored in game/scripts/view/scene_props.gd and world_layout.gd.
// Previews: art/reference/classical_camp.png, classical_west.png, classical_east.png.
seed = 97;
var W = 384, H = 80, G = 56;
var GAME = DIR + 'game/assets/world/classical/';
var IMG = SPR.layer(0).cel(0).image;

function obj(w, h, cx, foot, fn, o) { o = o || {}; return { w: w, h: h, x: cx - Math.floor(w / 2), y: foot - h, fn: fn, flip: o.flip, sh: o.sh, raw: o.raw, fy: o.z || foot, foot: foot, cx: cx }; }
function drawObj(buf, ob) { // shadow, then the outlined sprite
  if (ob.sh) buf.ell(ob.cx, ob.foot, ob.sh, 1.5, '#5f8236');
  var tb = new Buf(ob.w, ob.h); ob.fn(tb); if (ob.flip) tb = mirror(tb);
  if (ob.raw) blit(buf, tb, ob.x, ob.y); else blit(buf, outlined(tb, OUT), ob.x - 1, ob.y - 1);
}
function layerOf(list) { var b = new Buf(W, H); list.sort(function (p, q) { return p.fy - q.fy; }); for (var k = 0; k < list.length; k++) drawObj(b, list[k]); return b; }

var STONE = ['#e4dccb', '#ddd4c0', '#ebe4d4'], STONED = '#b7ad96', STONEL = '#f7f2e6', STONES = '#a29a85';
var TERR = ['#c8663f', '#b85a36', '#d4764a'], TERRD = '#8f3f26', TERRL = '#e69468';
var PLASTER = '#f1ead8', PLASTERD = '#d8cfb6', DARK = '#2a2433', GLOWIN = '#3a3040';
var OAK = '#5b3d27', OAKL = '#7d5634', OAKD = '#3e281a', OAKH = '#9a6c40';
var WATER = '#4f93c4', WATERL = '#8cc8e8', WATERD = '#2f6890';
var SIL = '#e6edf5';

function courses(b, x, y, w, h, pal, joint, bw) {
  var r, xx, yy, x0, x1, tone, bh;
  b.rect(x, y, w, h, joint);
  for (r = 0; y + r * 3 < y + h; r++) {
    yy = y + r * 3; bh = Math.min(2, y + h - yy);
    for (xx = x - (r % 2) * Math.floor(bw / 2); xx < x + w; xx += bw + 1) {
      tone = (xx * 7 + r * 13 + ((xx * r) % 5)) % 3; if (tone < 0) tone += 3;
      x0 = Math.max(xx, x); x1 = Math.min(xx + bw, x + w);
      if (x1 > x0) b.rect(x0, yy, x1 - x0, bh, pal[tone]);
    }
  }
}
function roof(b, top, bot, rl, rr, el, er, paint) {
  var y, x, t, l, r;
  for (y = top; y <= bot; y++) {
    t = (y - top) / (bot - top);
    l = Math.round(rl + (el - rl) * t); r = Math.round(rr + (er - rr) * t);
    for (x = l; x <= r; x++) paint(x, y, t, x == l, x == r);
  }
}
// A tiled roof: rows of terracotta, a lit ridge row, a dark eave row, and a darker edge.
function tiles(b, top, bot, rl, rr, el, er) {
  roof(b, top, bot, rl, rr, el, er, function (px, py, t, left, right) {
    var c = TERR[((px >> 1) + py) % 3];
    if (py == top) c = TERRL; else if (py >= bot) c = TERRD;
    if (left || right) c = TERRD;
    b.px(px, py, c);
  });
}

// ---- the Hut's slot (34x24, foot row 23): a plastered stone house with a tiled hip roof and a balcony -----------
function stonehouse(b) {
  var x, y;
  courses(b, 2, 18, 30, 6, STONE, STONED, 6); b.rect(2, 18, 30, 1, STONEL);
  b.rect(3, 10, 28, 8, PLASTER); b.rect(3, 10, 28, 1, STONEL); b.rect(3, 17, 28, 1, PLASTERD);
  b.rect(3, 10, 2, 14, STONE[2]); b.rect(29, 10, 2, 14, STONE[0]); // quoins at the corners
  tiles(b, 1, 10, 9, 24, 0, 33);
  b.rect(8, 0, 2, 3, STONE[1]); b.rect(8, 0, 2, 1, STONEL); // a chimney
  // a balcony over the door, a shuttered window beside it
  b.rect(12, 15, 10, 1, OAKL); b.rect(12, 14, 1, 2, OAK); b.rect(21, 14, 1, 2, OAK); b.rect(12, 16, 10, 1, OAKD);
  b.rect(7, 12, 4, 5, DARK); b.rect(6, 11, 6, 1, STONED); b.rect(6, 17, 6, 1, STONED); b.rect(6, 12, 1, 5, OAK); b.rect(11, 12, 1, 5, OAK);
  b.rect(23, 12, 4, 5, DARK); b.rect(22, 11, 6, 1, STONED); b.rect(22, 17, 6, 1, STONED); b.rect(22, 12, 1, 5, OAK); b.rect(27, 12, 1, 5, OAK);
  // the arched door under the balcony, and a flower box of red
  b.rect(14, 18, 6, 6, DARK); b.rect(15, 17, 4, 1, DARK); b.rect(13, 18, 1, 6, STONED); b.rect(20, 18, 1, 6, STONED); b.rect(14, 16, 6, 1, STONED);
  b.rect(6, 17, 6, 1, OAKL); for (x = 6; x < 12; x += 2) b.px(x, 16, '#d85a4a');
}

// ---- the village's two small houses (26x19, foot row 18) ------------------------------------------------------
function smallstonehouse(b) {
  var x;
  courses(b, 2, 14, 22, 5, STONE, STONED, 6); b.rect(2, 14, 22, 1, STONEL);
  b.rect(3, 8, 20, 6, PLASTER); b.rect(3, 8, 20, 1, STONEL); b.rect(3, 13, 20, 1, PLASTERD);
  b.rect(3, 8, 2, 11, STONE[2]); b.rect(21, 8, 2, 11, STONE[0]);
  tiles(b, 1, 8, 8, 17, 0, 25);
  b.rect(18, 0, 2, 3, STONE[1]); b.rect(18, 0, 2, 1, STONEL);
  b.rect(6, 10, 4, 4, DARK); b.rect(5, 9, 6, 1, STONED); b.rect(5, 13, 6, 1, STONED);
  b.rect(12, 14, 5, 5, DARK); b.rect(13, 13, 3, 1, DARK); b.rect(11, 14, 1, 5, STONED); b.rect(17, 14, 1, 5, STONED); b.rect(12, 12, 5, 1, STONED);
  b.rect(18, 11, 3, 3, DARK); b.rect(17, 10, 5, 1, STONED);
}

// ---- the square: an arcade of arches under a tiled roof (54x27, foot row 26) -----------------------------------
function arcade(b) {
  var x, y, k, goods = ['#c0504a', '#d9a23a', '#6a9a4a', '#4a7fa8'];
  // base steps
  courses(b, 0, 24, 54, 3, STONE, STONED, 7); b.rect(0, 24, 54, 1, STONEL); b.rect(0, 26, 54, 1, STONES);
  // the back wall in shadow, with the goods in each bay
  b.rect(2, 9, 50, 15, '#8c8573');
  for (x = 2; x < 52; x += 4) b.px(x, 13, '#7a7360');
  // roof: a tiled slope with a cornice under it
  tiles(b, 0, 6, 3, 50, 0, 53);
  b.rect(0, 7, 54, 2, STONE[0]); b.rect(0, 7, 54, 1, STONEL); b.rect(0, 8, 54, 1, STONED);
  // four bays between piers: a dark arch, an awning in each, and a few goods
  for (k = 0; k < 4; k++) {
    var x0 = 4 + k * 12;
    for (y = 10; y < 24; y++) {
      var inset = y < 13 ? 13 - y : 0;
      for (x = x0 + inset; x <= x0 + 8 - inset; x++) b.px(x, y, y < 22 ? '#3a3040' : '#6a6454');
    }
    b.rect(x0 + 1, 14, 7, 2, k % 2 ? '#c0504a' : '#efe6d0'); b.rect(x0 + 1, 16, 7, 1, k % 2 ? '#8f3a2d' : '#d8cdb0'); // an awning
    b.px(x0 + 2, 21, goods[k % 4]); b.px(x0 + 4, 22, goods[(k + 1) % 4]); b.px(x0 + 6, 21, goods[(k + 2) % 4]); b.rect(x0 + 1, 22, 7, 1, '#6a5238');
    b.rect(x0 - 2, 9, 3, 15, STONE[2]); b.rect(x0 - 2, 9, 1, 15, STONEL); b.rect(x0, 9, 1, 15, STONED); // the pier on the left
  }
  b.rect(50, 9, 3, 15, STONE[2]); b.rect(50, 9, 1, 15, STONEL); b.rect(52, 9, 1, 15, STONED);
  b.rect(26, 5, 2, 4, STONED); b.rect(26, 2, 2, 4, IRON_M); b.rect(27, 2, 6, 3, '#b8402f'); b.px(26, 1, IRON_L); // a banner at the roof
}
// ---- an inscribed pillar at the market's left edge (10x20, foot row 19) ------------------------------------------
function lawpillar(b) {
  var y;
  b.rect(0, 17, 10, 3, STONE[0]); b.rect(0, 17, 10, 1, STONEL); b.rect(1, 16, 8, 1, STONED);
  b.rect(2, 2, 6, 14, STONE[0]); b.rect(2, 2, 1, 14, STONEL); b.rect(7, 2, 1, 14, STONED);
  b.rect(1, 0, 8, 3, STONE[2]); b.rect(1, 0, 8, 1, STONEL); b.rect(1, 2, 8, 1, STONED);
  for (y = 4; y < 15; y += 2) { b.rect(3, y, 4, 1, '#6a5a3a'); if (y % 4 == 0) b.px(6, y, STONE[0]); }
  b.rect(3, 15, 4, 1, TERR[0]);
}

// ---- the water court (16x22, foot row 21): a basin under two arches --------------------------------------------
function watercourt(b) {
  var x, y;
  courses(b, 0, 14, 16, 8, STONE, STONED, 5); b.rect(0, 14, 16, 1, STONEL);
  b.rect(1, 16, 14, 3, WATER); b.rect(1, 16, 14, 1, WATERL); b.px(4, 17, WATERL); b.px(10, 18, WATERL);
  b.rect(0, 4, 16, 10, STONE[0]); b.rect(0, 4, 16, 1, STONEL);
  // one wide arch with a lion-head spout in its back wall, pilasters either side
  for (y = 6; y < 14; y++) { var inset = y < 9 ? 9 - y : 0; for (x = 3 + inset; x <= 12 - inset; x++) b.px(x, y, '#5e6a78'); }
  b.rect(0, 5, 2, 9, STONE[2]); b.rect(0, 5, 1, 9, STONEL); b.rect(14, 5, 2, 9, STONE[0]);
  b.rect(7, 9, 2, 2, STONES); b.px(7, 9, STONEL);
  b.rect(7, 11, 2, 3, WATERL);  b.rect(7, 14, 2, 1, WATER); b.px(7, 15, WATERL); b.px(8, 15, WATERL); // a spout and its fall
  b.rect(0, 2, 16, 3, STONE[2]); b.rect(0, 2, 16, 1, STONEL); b.rect(0, 4, 16, 1, STONED);
  b.rect(6, 0, 4, 2, TERR[0]); b.rect(6, 0, 4, 1, TERRL); // an amphora on the parapet
}

// ---- a paved street (w x 5, raw, on the front lane's top rows): set slabs with a lit curb ---------------------------
function pavedstreet(w) {
  return function (b) {
    var x, y;
    for (y = 0; y < 5; y++) for (x = 0; x < w; x++) {
      var off = (y % 2) * 3, edge = ((x + off) % 7) == 0;
      b.px(x, y, y == 0 ? '#e0dac9' : (edge ? '#8f8a7c' : (y == 4 ? '#a8a292' : '#bdb7a6')));
    }
    for (x = 1; x < w; x += 9) b.px(x, 2, '#cfc9b8');
  };
}
// ---- the theatre (46x25, foot row 66): a two-storey arcade round the stage, the stepped seats showing over it ----
function theatre(b) {
  var x, y, k, x0, inset;
  b.rect(0, 23, 46, 2, STONES); b.rect(0, 23, 46, 1, STONED);
  // the seats, in steps above the roof of the arcade
  b.rect(10, 0, 26, 1, STONEL); b.rect(6, 1, 34, 2, STONE[0]); b.rect(6, 1, 34, 1, STONEL); b.rect(2, 3, 42, 2, STONE[2]); b.rect(2, 3, 42, 1, STONEL);
  for (x = 8; x < 40; x += 6) { b.px(x, 2, STONED); b.px(x + 2, 4, STONED); }
  b.rect(8, 0, 1, 1, TERR[0]); b.rect(37, 0, 1, 1, TERR[0]); // two awning poles' tops
  // the upper arcade: small windows
  b.rect(1, 5, 44, 8, STONE[0]); b.rect(1, 5, 44, 1, STONEL);
  for (k = 0; k < 6; k++) { x0 = 4 + k * 7; b.rect(x0, 7, 3, 5, DARK); b.rect(x0 - 1, 6, 5, 1, STONED); b.rect(x0 - 1, 12, 5, 1, STONED); }
  b.rect(0, 13, 46, 1, STONEL); b.rect(0, 14, 46, 1, STONED);
  // the lower arcade: round arches on piers
  b.rect(1, 15, 44, 8, STONE[1]);
  for (k = 0; k < 6; k++) {
    x0 = 3 + k * 7;
    for (y = 16; y < 23; y++) { inset = y < 18 ? 18 - y : 0; for (x = x0 + inset; x <= x0 + 4 - inset; x++) b.px(x, y, y < 21 ? DARK : '#3a3040'); }
    b.rect(x0 - 2, 15, 2, 8, STONE[2]); b.rect(x0 - 2, 15, 1, 8, STONEL);
  }
  b.rect(43, 15, 2, 8, STONE[2]); b.rect(44, 15, 1, 8, STONED);
  // a red banner at one end
  b.rect(42, 0, 1, 5, IRON_M); b.rect(43, 0, 3, 3, '#b8402f');
}

// ---- the harbour (84x34, foot row 72): a stone mole running out from the shore with the lighthouse standing on its end ---
function harbour(b) {
  var x, y, hw;
  // the mole: ashlar along the water with mooring rings and a walkway on top; the shore end has a landing
  courses(b, 0, 21, 74, 8, STONE, STONED, 7); b.rect(0, 21, 74, 2, STONEL); b.rect(0, 22, 74, 1, STONE[0]);
  for (x = 6; x < 58; x += 14) { b.rect(x, 24, 2, 2, IRON_M); b.px(x, 24, IRON_L); }
  b.rect(0, 23, 3, 6, STONE[2]); b.rect(0, 23, 1, 6, STONEL);
  for (x = 0; x < 74; x++) { b.px(x, 29, WATERD); b.px(x, 30, (x % 6 < 3) ? WATER : WATERL); }
  // the lighthouse stands on the mole's end: a tapering shaft in courses, a gallery, a glass lantern and its flame
  for (y = 6; y < 22; y++) { hw = 3 + Math.floor((y - 6) / 6); courses(b, 66 - hw, y, hw * 2 + 1, 1, STONE, STONED, 4); }
  b.rect(61, 21, 11, 1, STONEL);
  b.rect(62, 12, 9, 1, TERR[1]); b.rect(63, 9, 7, 3, DARK);
  b.rect(64, 9, 5, 3, '#f59a3a'); b.rect(65, 10, 3, 2, '#ffe27a');
  tiles(b, 5, 8, 66, 66, 62, 70); b.px(66, 4, IRON_L);
}

// ---- a trading ship moored along the mole (26x18, outlined on its own so it reads against the stone) ------------
function ship(b) {
  var x;
  b.rect(2, 15, 22, 2, '#5a3a26'); b.rect(3, 17, 20, 1, '#3a281a'); b.rect(1, 14, 24, 1, OAKL);
  b.px(0, 13, OAKL); b.px(1, 13, OAKL); b.px(25, 12, OAKL); b.px(24, 13, OAKL); b.px(25, 13, OAKL); // a raised prow and stern
  b.rect(3, 15, 20, 1, '#e8dcb8');
  for (x = 5; x < 22; x += 4) b.px(x, 16, '#c9b88a'); // oar ports
  b.rect(13, 1, 1, 13, OAK);
  b.rect(5, 2, 17, 1, OAK);
  for (x = 7; x < 20; x++) for (var y = 3; y < 11; y++) b.px(x, y, (x % 4 < 2) ? '#c0504a' : '#f3e9d2');
  b.rect(7, 3, 13, 1, '#a8402f'); b.rect(7, 10, 13, 1, '#d8cdb0');
  b.rect(14, 0, 4, 2, '#b8402f');
}

// ---- the lighthouse's night light (east page, full 384x80): dithered warm bands round the lantern, drawn
// additively by the game like the Iron Age's beacon glow, and replacing it (same name) from the Classical Age on.
function lighthouseglow() {
  var g = new Buf(W, H), gx, gy, dx, dy, dd, v, a, bi;
  var bands = [[0.4, 150], [0.65, 100], [0.85, 56], [1.0, 26]];
  for (gy = 0; gy < H; gy++) for (gx = 0; gx < W; gx++) {
    dx = (gx - 303) / 34; dy = (gy - 48) / 24; dd = Math.sqrt(dx * dx + dy * dy); v = 0;
    for (bi = 0; bi < bands.length; bi++) {
      if (dd < bands[bi][0]) { v = bands[bi][1]; if (bi + 1 < bands.length && bands[bi][0] - dd < 0.07 && ((gx + gy) & 1) == 0) v = bands[bi + 1][1]; break; }
    }
    a = (gy * W + gx) * 4;
    if (v > 0) { g.d[a] = 255; g.d[a + 1] = 154; g.d[a + 2] = 60; g.d[a + 3] = v; }
  }
  return g;
}
var layers = {};
layers.building_hut = layerOf([obj(34, 24, 268, 71, stonehouse, { sh: 14 })]);
layers.west_roof_a = layerOf([obj(26, 19, 172, 72, smallstonehouse, { sh: 11 })]);
layers.west_roof_b = layerOf([obj(26, 19, 148, 71, smallstonehouse, { sh: 11, flip: 1 })]);
layers.market_arcade = layerOf([obj(54, 27, 28, 64, arcade, { sh: 0, z: 67 })]);
layers.law_pillar = layerOf([obj(10, 20, 6, 66, lawpillar, { sh: 0 })]);
layers.water_court = layerOf([obj(16, 22, 197, 75, watercourt, { sh: 0 })]);
layers.paved_street_market = layerOf([obj(56, 5, 28, 80, pavedstreet(56), { sh: 0, raw: true })]);
layers.paved_street_west = layerOf([obj(328, 5, 220, 80, pavedstreet(328), { sh: 0, raw: true })]);
layers.paved_street_hall = layerOf([obj(88, 5, 44, 80, pavedstreet(88), { sh: 0, raw: true })]);
layers.paved_street = layerOf([obj(176, 5, 176, 80, pavedstreet(176), { sh: 0, raw: true })]);
layers.paved_street_bank = layerOf([obj(40, 5, 284, 80, pavedstreet(40), { sh: 0, raw: true })]);
layers.east_theatre = layerOf([obj(46, 25, 138, 66, theatre, { sh: 0, z: 67 })]);
layers.east_harbour = layerOf([obj(84, 34, 279, 72, harbour, { sh: 0 }), obj(26, 18, 289, 75, ship, { sh: 0 })]);
layers.east_beacon_glow = lighthouseglow();

var groups = [
  ['classical_camp', ['building_hut', 'paved_street', 'paved_street_hall']],
  ['classical_west', ['paved_street_market', 'paved_street_west', 'market_arcade', 'law_pillar', 'water_court', 'west_roof_a', 'west_roof_b']],
  ['classical_east', ['east_theatre', 'east_harbour'], 'sea']
], gi, gj, P, name, x, y;
for (gi = 0; gi < groups.length; gi++) {
  P = new Buf(W, H);
  for (y = 0; y < G; y++) for (x = 0; x < W; x++) P.px(x, y, '#9cc4de');
  for (y = G; y < H; y++) for (x = 0; x < W; x++) P.px(x, y, y < G + 13 ? '#86a94c' : '#789a43');
  if (groups[gi][2] == 'sea') for (y = 57; y < H; y++) for (x = 200; x < W; x++) P.px(x, y, y < 60 ? '#3b79ad' : '#2f6890');
  for (gj = 0; gj < groups[gi][1].length; gj++) blit(P, layers[groups[gi][1][gj]], 0, 0);
  IMG.putImageData(P.d); if (gi == 0) SPR.save(); else SPR.saveAs(DIR + 'art/reference/' + groups[gi][0] + '.png');
}
var count = 0;
for (name in layers) { IMG.putImageData(layers[name].d); SPR.saveAs(GAME + name + '.png'); count++; }
console.log('classical camp done, ' + count + ' game layers');

function awning(b, x, y, w, cloth) {
  for (var dx = 0; dx < w; dx++) {
    var stripe = dx % 8 < 4;
    b.rect(x + dx, y, 1, 4, stripe ? cloth[1] : PLASTER);
    b.px(x + dx, y, stripe ? cloth[0] : STONEL);
    b.px(x + dx, y + 3, stripe ? cloth[2] : PLASTERD);
    if (dx % 4 === 1 || dx % 4 === 2) b.px(x + dx, y + 4, stripe ? cloth[2] : PLASTERD);
  }
}

function guildArcade(fair) {
  return function (b) {
    courses(b, 0, 24, 54, 3, STONE, STONED, 7);
    b.rect(0, 24, 54, 1, STONEL);
    b.rect(2, 9, 50, 15, '#51464a');
    for (var x = 3; x < 53; x += 12) {
      b.rect(x, 10, 2, 14, OAK);
      b.rect(x, 11, 1, 12, OAKH);
      b.line(x, 16, x + 4, 12, OAKH, 1);
    }
    tiles(b, 1, 9, 6, 45, 0, 53);
    b.rect(1, 9, 52, 1, OAKD);
    awning(b, 2, 10, 50, ['#98b7b6', '#5d8493', '#426070']);

    b.rect(5, 20, 9, 2, OAKH); b.rect(5, 21, 9, 1, OAK);
    b.rect(6, 22, 1, 2, OAKD); b.rect(12, 22, 1, 2, OAKD);
    b.line(7, 16, 10, 20, '#d3b483', 1); b.rect(7, 17, 4, 2, IRON_L);
    b.rect(18, 18, 8, 2, '#a95c4d'); b.rect(18, 20, 6, 2, '#d49c64');
    b.rect(18, 22, 8, 1, OAKH);
    b.rect(33, 14, 7, 7, OAKD);
    b.rect(34, 15, 5, 5, '#d5ab5a'); b.line(35, 18, 38, 16, '#846337', 1);
    b.rect(43, 19, 7, 2, OAKH); b.rect(44, 21, 1, 3, OAK);
    if (fair) {
      b.rect(16, 17, 10, 7, '#b48857'); b.rect(17, 17, 8, 2, '#ecd193');
      b.rect(21, 18, 1, 6, '#885b3c');
      b.ell(46, 21, 4, 2.5, '#b38049'); b.rect(44, 19, 5, 1, '#dab57b');
      b.px(45, 21, '#f1d39c'); b.px(47, 22, OAKL);
    }
  };
}

function tendedCourt(b) {
  b.rect(3, 10, 3, 15, OAK); b.rect(3, 11, 1, 13, OAKH);
  b.rect(20, 10, 3, 15, OAKD); b.rect(20, 11, 1, 13, OAKL);
  b.line(4, 16, 8, 12, OAKH, 1); b.line(21, 16, 17, 12, OAK, 1);
  roof(b, 1, 12, 10, 12, 0, 25, function (x, y, t, left, right) {
    var c = x < 13 ? '#567f9f' : '#405b7b';
    if (left || y === 1) c = '#96bdcb';
    else if (right || y === 12) c = '#334458';
    else if (y % 3 === 0) c = x < 13 ? '#456785' : '#364d65';
    b.px(x, y, c);
  });
  b.rect(2, 12, 22, 2, OAKD); b.rect(3, 12, 20, 1, OAKL);

  b.rect(10, 14, 3, 4, STONES); b.rect(10, 14, 1, 3, STONEL);
  b.rect(11, 17, 2, 7, WATERL); b.rect(12, 19, 1, 5, WATER);
  b.rect(17, 15, 5, 5, OAKD); b.rect(17, 15, 4, 4, '#dfc789');
  b.px(18, 16, OAKL); b.px(18, 18, OAKL);

  courses(b, 1, 23, 24, 7, STONE, STONED, 5);
  b.rect(2, 22, 22, 1, STONEL); b.px(1, 23, STONEL); b.px(24, 23, STONEL);
  b.rect(3, 23, 20, 3, WATER); b.rect(3, 23, 20, 1, WATERL);
  b.rect(10, 24, 4, 1, '#c9ebf2'); b.px(17, 25, WATERD);
  b.rect(2, 26, 22, 1, STONEL);
}

function scriptorium(b) {
  b.rect(2, 12, 22, 16, PLASTER);
  b.rect(19, 11, 5, 17, PLASTERD);
  courses(b, 1, 25, 24, 4, STONE, STONED, 6);
  b.rect(18, 3, 4, 9, STONE[0]); b.rect(18, 3, 5, 1, STONEL);
  roof(b, 2, 15, 8, 10, 0, 23, function (x, y, t, left, right) {
    var c = x < 12 ? '#577884' : '#435b6b';
    if (left) c = '#8eaaab';
    else if (right || y === 15 || y % 3 === 0) c = '#384856';
    else if ((x + Math.floor(y / 3) * 2) % 5 === 0) c = '#6c8993';
    b.px(x, y, c);
  });
  b.rect(3, 15, 15, 10, OAKD);
  b.rect(5, 14, 11, 1, OAKH);
  b.rect(4, 16, 13, 7, '#e4a559'); b.rect(4, 16, 13, 2, '#ffde99');
  b.rect(8, 16, 1, 7, OAK); b.rect(12, 16, 1, 7, OAK);
  b.rect(5, 21, 11, 2, '#8d553b');
  b.rect(5, 20, 3, 1, '#f8e5b5'); b.rect(13, 20, 3, 1, '#f8e5b5');
  b.rect(2, 24, 17, 1, OAKH);
  b.rect(19, 20, 4, 7, DARK); b.rect(19, 19, 3, 1, OAKL);
  b.rect(19, 27, 6, 1, STONEL);
}

function fairWharf(b) {
  harbour(b); // Keep the lantern at its Classical coordinates for the existing night glow.
  b.rect(6, 12, 40, 9, '#54454a');
  tiles(b, 6, 12, 12, 38, 4, 47);
  awning(b, 6, 12, 40, ['#dfa779', '#ac6454', '#78463d']);
  b.rect(8, 16, 2, 6, OAK); b.rect(43, 16, 2, 6, OAK);
  b.px(8, 18, OAKH);
  b.rect(13, 18, 7, 4, '#9d7150'); b.rect(13, 18, 7, 1, '#c99d64');
  b.rect(15, 19, 1, 3, OAKL);
  b.ell(25, 19, 3, 2, '#d3b076'); b.ell(30, 20, 3, 1.5, '#c2a175');
  b.rect(36, 18, 5, 4, '#8e6c51'); b.rect(37, 19, 3, 1, '#d4a970');
  b.rect(49, 18, 2, 5, OAKL); b.rect(54, 18, 2, 5, OAK);
  b.line(50, 19, 54, 20, '#b2946a', 1);
}

function travellersHall(b) {
  b.rect(3, 10, 43, 16, PLASTER); b.rect(35, 10, 11, 16, PLASTERD);
  b.rect(37, 1, 5, 9, STONE[0]); b.rect(36, 1, 7, 2, STONED);
  b.px(37, 1, STONEL);
  tiles(b, 0, 12, 10, 33, 0, 48);
  b.rect(3, 12, 43, 2, OAK); b.rect(3, 12, 43, 1, OAKL);
  b.rect(5, 16, 26, 9, '#504349');
  b.rect(6, 15, 24, 2, OAK); b.rect(6, 15, 24, 1, OAKH);
  b.rect(5, 17, 2, 8, OAKL); b.rect(29, 17, 2, 8, OAK);
  b.line(6, 20, 10, 16, OAKH, 1); b.line(30, 20, 26, 16, OAK, 1);
  b.rect(11, 21, 15, 2, '#d9ad69'); b.rect(12, 22, 13, 1, OAKH);
  b.rect(13, 23, 1, 2, OAKL); b.rect(24, 23, 1, 2, OAKL);
  b.rect(16, 20, 5, 1, PLASTER); b.px(23, 20, '#e2a862');
  b.rect(36, 16, 7, 6, DARK); b.rect(37, 17, 5, 4, '#e1a65f');
  b.rect(39, 17, 1, 4, OAK);
  b.rect(34, 22, 11, 1, OAKH);
  b.rect(44, 14, 4, 1, OAKL); b.rect(45, 15, 3, 4, '#537d91'); b.px(46, 16, '#e8c687');
  courses(b, 1, 25, 46, 3, STONE, STONED, 7);
  b.rect(4, 25, 40, 1, STONEL); b.rect(7, 27, 34, 1, '#d0c6b1');
}

var medieval = {
  tended_water_court: layerOf([obj(26, 30, 197, 75, tendedCourt)]),
  guild_arcade: layerOf([obj(54, 27, 28, 64, guildArcade(false))]),
  guild_arcade_fair: layerOf([obj(54, 27, 28, 64, guildArcade(true))]),
  scriptorium: layerOf([obj(26, 29, 280, 66, scriptorium)]),
  east_fair_wharf: layerOf([obj(84, 34, 279, 72, fairWharf), obj(26, 18, 289, 75, ship)]),
  east_travellers_hall: layerOf([obj(49, 28, 138, 69, travellersHall)]),
  stewardship_charter: layerOf([obj(8, 10, 42, 63, function (b) {
    b.rect(0, 0, 8, 8, OAK); b.rect(1, 1, 6, 6, '#edda9d');
    b.rect(2, 2, 4, 1, OAKL); b.rect(2, 4, 3, 1, OAKL); b.px(5, 5, '#a44838');
    b.rect(1, 8, 1, 2, OAK); b.rect(6, 8, 1, 2, OAK);
  })]),
  stewardship_pages: layerOf([obj(8, 4, 24, 63, function (b) {
    b.rect(0, 1, 8, 3, OAKL); b.rect(0, 0, 7, 2, '#f3e0a7'); b.rect(3, 0, 1, 4, '#b75b41');
  })])
};
for (name in medieval) {
  IMG.putImageData(medieval[name].d);
  SPR.saveAs(DIR + 'game/assets/world/medieval/' + name + '.png');
}

var paper = '#fff0c5', fold = '#cdb887', ink = '#526c86';
function pageBoard(b, map) {
  b.rect(0, 1, 13, 11, OAKD);
  b.rect(1, 0, 11, 10, paper);
  if (map) {
    b.rect(1, 1, 3, 8, '#8abdcf'); b.line(4, 1, 9, 8, '#558bbe', 2);
    b.line(10, 3, 4, 8, '#a47a4e', 1); b.rect(7, 2, 4, 2, '#799767');
  } else {
    b.rect(2, 2, 8, 2, fold); b.rect(3, 5, 7, 1, ink); b.rect(3, 7, 4, 1, ink);
  }
}

var renaissance = {
  print_sheets: layerOf([obj(13, 12, 12, 62, function (b) { pageBoard(b, false); })]),
  wayfinder_map: layerOf([obj(13, 12, 12, 62, function (b) { pageBoard(b, true); })]),
  town_rule: layerOf([obj(16, 8, 58, 61, function (b) {
    b.rect(0, 2, 16, 6, OAKD); b.rect(1, 0, 14, 6, '#e6b95e');
    for (var x = 2; x < 15; x += 3) b.rect(x, 1, 1, 3, OAKD);
  })]),
  observations_board: layerOf([obj(16, 12, 58, 62, function (b) {
    b.rect(0, 0, 16, 12, OAKD);
    b.rect(1, 2, 6, 8, paper); b.rect(9, 1, 6, 9, '#9bbac6');
    b.line(2, 8, 5, 4, ink, 1); b.line(10, 6, 14, 4, ink, 1);
  })]),
  map_house: layerOf([obj(26, 29, 82, 66, function (b) {
    b.rect(2, 12, 22, 16, '#ebceaa'); b.rect(20, 12, 4, 16, '#bb9b80');
    b.rect(19, 1, 4, 10, '#9d7466'); b.rect(18, 1, 6, 2, '#c19b86');
    roof(b, 4, 13, 8, 15, 0, 25, function (x, y, t, left, right) {
      var c = x < 17 ? '#bd775b' : '#96584b';
      if (left || t === 0) c = '#e2a480';
      else if (right || t === 1 || y % 3 === 0) c = '#834c41';
      b.px(x, y, c);
    });
    b.rect(2, 14, 22, 1, '#b7967a');
    b.rect(4, 16, 12, 10, '#6b5044'); b.rect(5, 17, 10, 8, '#d6a36a');
    b.rect(6, 18, 8, 6, paper); b.rect(7, 19, 2, 4, '#6b9ea8');
    b.line(9, 22, 13, 19, '#968358', 1); b.px(12, 22, '#719472');
    b.rect(3, 17, 2, 7, '#618077'); b.rect(15, 17, 2, 7, '#46685f');
    b.rect(4, 25, 12, 1, OAKH);
    b.rect(17, 18, 6, 10, '#d3b18d'); b.rect(18, 19, 4, 9, DARK);
    b.rect(18, 21, 3, 7, '#775544'); b.px(20, 24, '#ebbc79');
    b.rect(2, 27, 22, 2, '#a99481'); b.rect(17, 28, 6, 1, '#e3c9ad');
  })]),
  building_hut: layerOf([obj(34, 24, 268, 71, function (b) {
    stonehouse(b);
    b.rect(1, 9, 32, 5, '#397580'); b.rect(1, 9, 32, 1, '#83b5b6');
    b.rect(3, 6, 28, 4, '#4a8b95'); b.rect(7, 3, 20, 4, '#4f96a1');
    b.rect(12, 1, 11, 3, '#67a7ae'); b.rect(9, 6, 6, 6, '#e4c799');
    b.rect(10, 7, 4, 4, '#3d5361'); b.rect(11, 7, 1, 4, '#bc9e73');
    b.rect(23, 17, 8, 3, '#49745e');
    b.rect(24, 16, 6, 1, '#daa48b'); b.rect(23, 19, 8, 2, OAKL);
  }, { sh: 14 })]),
  building_granary: layerOf([obj(26, 30, 234, 67, function (b) {
    b.rect(2, 10, 22, 13, '#dbb77e'); b.rect(19, 10, 5, 13, '#aa7d57');
    b.rect(2, 12, 22, 2, '#8d603e');
    for (var x = 5; x < 23; x += 4) b.rect(x, 14, 1, 8, '#bc925e');
    roof(b, 2, 11, 9, 15, 0, 25, function (px, y, t, left, right) {
      var c = px < 14 ? '#538c97' : '#376774';
      if (left || y === 2) c = '#8fbcb9';
      else if (right || y === 11 || y % 3 === 1) c = '#324e60';
      b.px(px, y, c);
    });
    b.rect(2, 22, 22, 2, OAKD); b.rect(2, 22, 22, 1, OAKH);
    b.rect(3, 24, 4, 5, '#9f9181'); b.rect(20, 24, 3, 5, '#948675');
    b.rect(3, 25, 4, 1, '#d9c4a5'); b.rect(20, 25, 3, 1, '#c4b192');
    b.rect(2, 28, 6, 2, '#c8bca3'); b.rect(19, 28, 5, 2, '#c8bca3');
    b.rect(8, 13, 10, 10, OAKD); b.rect(9, 14, 7, 8, '#ae7545');
    b.line(9, 21, 15, 15, '#724632', 2); b.px(15, 19, '#e8bc67');
    b.rect(4, 16, 3, 2, OAKD); b.rect(20, 16, 3, 2, OAKD);
    b.rect(9, 23, 8, 2, '#b28359'); b.rect(8, 25, 10, 2, '#795943');
    b.rect(7, 27, 12, 2, '#b39a76'); b.rect(7, 28, 12, 1, '#795943');
  })]),
  building_quay: layerOf([obj(40, 24, 338, 72, function (b) {
    b.rect(0, 17, 40, 4, '#a99880'); b.rect(0, 17, 40, 1, '#eee1c5');
    for (var x = 2; x < 39; x += 9) b.rect(x, 21, 3, 3, '#777572');
    b.rect(7, 10, 2, 7, OAKL); b.rect(25, 10, 2, 7, OAK);
    b.rect(9, 14, 15, 2, OAKH); b.rect(12, 12, 6, 2, '#ebd39c');
    awning(b, 5, 7, 24, ['#96c0bf', '#4b8794', '#304f5d']);
    b.rect(6, 5, 22, 2, '#407682'); b.rect(9, 3, 16, 2, '#6fa8af');
    b.rect(35, 10, 2, 7, OAKD); b.rect(34, 8, 4, 3, '#e9b763');
  })])
};
for (name in renaissance) {
  IMG.putImageData(renaissance[name].d);
  SPR.saveAs(DIR + 'game/assets/world/renaissance/' + name + '.png');
}

function instrumentShop(b) {
  var slate = '#475c72', slatel = '#809aa5', slated = '#343e54';
  var x, g = '#e5c992', brick = ['#d3a17d', '#c38c6d', '#cd9876'];
  courses(b, 3, 12, 36, 24, brick, '#a87662', 6);
  b.rect(36, 13, 3, 22, '#a56f5b');
  b.rect(32, 1, 5, 9, brick[1]); b.rect(31, 1, 7, 2, g);
  roof(b, 4, 13, 10, 31, 0, 41, function (x, y, t, left, right) {
    b.px(x, y, left || t === 0 ? slatel : right || t === 1 || y === 9 ? slated : slate);
  });
  b.rect(1, 13, 40, 2, g);
  b.rect(1, 19, 24, 14, slated); b.rect(3, 17, 20, 3, slate);
  b.rect(3, 20, 20, 10, '#c58b54'); b.rect(4, 20, 18, 2, '#f2cb87');
  b.rect(3, 21, 3, 9, '#aa7950'); b.rect(20, 21, 3, 9, '#aa7950');
  for (x = 6; x <= 19; x += 13) b.rect(x, 20, 1, 10, '#805d4e');
  b.ell(13, 25, 5, 4, '#674839'); b.ell(13, 25, 4, 3, '#eab95f');
  b.rect(8, 21, 11, 3, '#dca46a'); b.line(12, 23, 16, 27, '#ffe4a3', 1);
  b.rect(1, 31, 24, 2, slate); b.rect(2, 31, 22, 1, slatel);
  b.rect(25, 14, 12, 21, g); b.rect(27, 15, 8, 20, DARK);
  b.rect(27, 16, 1, 18, '#73554d'); b.px(33, 28, '#d4a961');
  b.rect(3, 35, 36, 1, STONED); b.rect(24, 35, 15, 1, STONEL);
}

function trialHouse(b) {
  var glass = '#8eb5bc', shade = '#547783', shine = '#c9e2d9', bars = '#566c6e';
  b.rect(2, 11, 46, 25, PLASTER); b.rect(44, 11, 4, 25, STONED);
  roof(b, 3, 11, 23, 25, 0, 49, function (x, y, t, left, right) {
    b.px(x, y, left || y === 3 ? STONEL : right || y === 11 ? STONED : PLASTERD);
  });
  b.rect(0, 11, 50, 2, STONEL); b.rect(2, 13, 46, 1, STONED);
  for (var x = 5; x <= 33; x += 28) {
    b.ell(x + 6, 22, 7, 7, STONEL); b.rect(x - 1, 22, 15, 12, STONEL);
    b.ell(x + 6, 22, 5.5, 5.5, shade); b.rect(x + 1, 22, 11, 10, glass);
    b.line(x + 2, 20, x + 2, 27, shine, 1);
    b.rect(x + 6, 17, 1, 14, bars); b.rect(x + 1, 23, 11, 1, bars);
    b.rect(x + 3, 28, 7, 3, x === 5 ? '#83a058' : '#4b8565');
    b.rect(x + 2, 31, 9, 2, '#9d664c');
  }
  b.rect(19, 14, 12, 23, STONED); b.rect(21, 16, 8, 20, DARK);
  b.rect(22, 18, 6, 10, shade); b.rect(24, 18, 1, 10, shine);
  b.rect(22, 29, 6, 6, '#46656b');
  b.rect(0, 35, 50, 2, STONED); b.rect(1, 35, 48, 1, STONEL);
}

function measuredField(b) {
  var earth = '#795244', furrow = '#61433a', straw = '#e8b94f', gold = '#f7d976';
  var y, r, x, left, right, aisle, bed, h, top;
  for (y = 5; y < 17; y++) {
    left = Math.max(0, 6 - (y - 5)); right = 54 - left;
    b.rect(left, y, right - left, 1, y === 16 || y % 3 === 1 ? furrow : earth);
    aisle = 30 - Math.floor((y - 5) / 2);
    b.rect(aisle - 2, y, 5, 1, y % 3 === 0 ? '#859856' : '#69834d');
  }
  for (r = 0; r < 3; r++) {
    y = 9 + r * 3; aisle = 30 - Math.floor((y - 5) / 2);
    for (bed = 0; bed < 2; bed++) {
      left = bed ? aisle + 4 : 7 - r * 2;
      right = bed ? 48 + r : aisle - 3;
      for (x = left + r % 2; x < right; x += 3) {
        h = 4 + ((x * 7 + r) % 4); top = y - h;
        b.rect(x, top + 1, 1, h, r === 2 ? '#c59039' : '#cda044');
        b.px(x, top, gold); b.px(x - 1, top + 1, straw); b.px(x + 1, top + 2, straw);
        b.px(x, top + 2, r ? '#eabc54' : '#ffe090');
        b.px(x - 1, y - 1, (x + r) % 2 ? '#aa8040' : '#9b884e');
      }
    }
  }
  for (x = 1; x <= 51; x += 50) {
    b.rect(x, 9, 2, 7, OAKH); b.rect(x, 10, 2, 1, '#f3e5b9');
    b.rect(x, 12, 2, 1, '#b9c9b2');
  }
  b.rect(22, 11, 2, 5, OAKH); b.rect(27, 11, 2, 5, OAKH);
  b.rect(22, 11, 7, 1, '#f3e5b9');
}

function measuredCourt(b) {
  var ledge = '#ece1be', wall = '#c7baa0', shade = '#9b8d7b', pool = '#3e8098';
  b.ell(12, 12, 10, 10, wall); b.rect(2, 12, 21, 12, wall);
  b.ell(12, 13, 6, 7, '#525366'); b.rect(6, 13, 13, 11, '#525366');
  b.rect(2, 13, 2, 10, ledge); b.rect(21, 13, 2, 10, shade);
  b.rect(11, 2, 3, 4, ledge); b.px(8, 4, ledge); b.px(16, 4, shade);
  b.rect(5, 7, 2, 1, ledge); b.rect(18, 8, 3, 1, shade);
  b.rect(2, 14, 4, 1, shade); b.rect(19, 14, 4, 1, shade);
  b.rect(2, 20, 4, 1, shade); b.rect(19, 20, 4, 1, shade);
  b.rect(15, 11, 3, 10, '#dfc27e');
  for (var y = 12; y <= 19; y += 3) b.rect(15, y, 2, 1, '#745a4c');
  b.rect(10, 10, 3, 4, ledge);
  b.rect(10, 14, 3, 10, WATERD); b.rect(10, 14, 2, 10, WATERL);
  b.ell(12, 24, 12, 4, ledge); b.ell(12, 24, 10, 2.6, pool);
  b.rect(4, 25, 17, 1, '#86c9ce'); b.rect(0, 27, 25, 2, wall);
  b.rect(2, 27, 21, 1, ledge); b.rect(2, 29, 21, 1, shade);
}

function reportBoard(b, corrected) {
  b.rect(0, 1, 16, 11, OAKD);
  b.rect(1, 2, 6, 8, paper); b.rect(9, 1, 6, 9, '#a7c7ce');
  b.line(2, 8, 6, 4, ink, 1);
  b.line(10, 7, 14, corrected ? 3 : 6, corrected ? '#984f3c' : ink, 1);
  if (corrected) b.rect(10, 8, 4, 1, '#984f3c');
}

var enlightenment = {
  instrument_shop: layerOf([obj(42, 36, 117, 66, instrumentShop)]),
  trial_house: layerOf([obj(50, 37, 173, 66, trialHouse)]),
  building_field: layerOf([obj(54, 17, 226, 78, measuredField)]),
  tended_water_court: layerOf([obj(26, 30, 197, 75, measuredCourt)]),
  report_pair: layerOf([obj(16, 12, 14, 62, function (b) { reportBoard(b, false); })]),
  correction_sheets: layerOf([obj(16, 12, 14, 62, function (b) { reportBoard(b, true); })]),
  method_diagram: layerOf([obj(16, 12, 57, 62, function (b) {
    b.rect(0, 0, 16, 12, OAKD); b.rect(1, 1, 14, 10, paper);
    for (var x = 2; x < 13; x += 5) b.rect(x, 4, 3, 4, ink);
    b.rect(5, 6, 2, 1, '#b4744d'); b.rect(10, 6, 2, 1, '#b4744d');
    b.rect(3, 9, 9, 1, fold);
  })]),
  reference_rules: layerOf([obj(16, 10, 57, 62, function (b) {
    b.rect(0, 0, 16, 10, OAKD);
    b.rect(1, 1, 14, 3, '#e6b95e'); b.rect(1, 6, 14, 3, paper);
    for (var x = 3; x < 14; x += 3) { b.px(x, 2, OAKD); b.px(x, 7, OAKD); }
  })]),
  trial_trays: layerOf([obj(16, 10, 57, 62, function (b) {
    for (var x = 0; x < 16; x += 8) {
      b.rect(x, 6, 7, 4, '#a06b50');
      b.rect(x + 1, 4, 5, 2, x === 0 ? '#a5b366' : '#639573');
      b.rect(x + 2, 2, 2, 4, '#7ca15d'); b.rect(x + 4, 3, 2, 3, '#94b270');
    }
  })]),
  pattern_jig: layerOf([obj(16, 10, 57, 62, function (b) {
    b.rect(0, 1, 7, 8, paper); b.line(1, 6, 5, 3, ink, 1);
    b.rect(8, 7, 8, 3, OAKH); b.rect(8, 2, 2, 6, '#d6a25f');
    b.rect(13, 3, 2, 5, '#d6a25f'); b.rect(9, 6, 5, 1, '#f2d89c');
  })])
};
for (name in enlightenment) {
  IMG.putImageData(enlightenment[name].d);
  SPR.saveAs(DIR + 'game/assets/world/enlightenment/' + name + '.png');
}
