// @open art/reference/cave_strip.png
// @canvas 384x80
// Cave Age world: 384x80, ground line y=56. Draws the scene as separate pieces so the game can
// show what the simulation says, and also a composite preview of everything built.
//
// Preview: art/reference/cave_strip.png (+ layers/cave_*.png, as before).
// Game assets (game/assets/world/cave/), each a full 384x80 transparent PNG so every piece
// already sits at its final position:
//   sky, far_hills, near_hills, trees, ground          backdrop layers (ground has no props)
//   static_back, static_mid                            always-present props (cliff/pine/mammoth;
//                                                      bush/rocks)
//   fire_pit_0..3                                      the fire pit (four flame frames) and firelight in
//                                                      the cave mouth, shown once the fire is found
//   fire_glow                                          the warm light it casts at night (additive)
//   building_<id>, site_<id>                           state-driven: finished building / its
//                                                      construction site, at the same slot
//   flower_sprout, flower_bloom                        the strange flower's two stages
// Layout slots below are mirrored in game/scripts/view/world_layout.gd; change both together.
seed = 12;
var W = 384, H = 80, G = 56;
var GAME = DIR + 'game/assets/world/cave/';
var SKY = new Buf(W, H), FAR = new Buf(W, H), NEAR = new Buf(W, H), TREES = new Buf(W, H);
var GROUND = new Buf(W, H), x, y, i;

// colder sky, pale sun, clouds
var sky = ['#86b4d6', '#9cc4de', '#b4d4e6', '#cde2ee', '#e4eef3'];
for (y = 0; y < G; y++) {
  var bi = Math.min(4, Math.floor(y / 11)), t = y % 11;
  for (x = 0; x < W; x++) { var c = sky[bi]; if (t >= 9 && bi < 4 && ((x + y) & 1) == 0) c = sky[bi + 1]; SKY.px(x, y, c); }
}
SKY.ell(352, 13, 5, 5, '#fff3c4'); SKY.ell(352, 13, 3.5, 3.5, '#fffbe6');
cloud(SKY, 70, 12, 1); cloud(SKY, 200, 8, 1.2); cloud(SKY, 300, 20, 0.7);

// far mountains with snow caps, near rolling hills, a conifer tree line
for (x = 0; x < W; x++) {
  var r1 = Math.round(33 + 6 * Math.sin(x / 41) + 3 * Math.sin(x / 15 + 1));
  for (y = r1; y < G; y++) {
    var snow = r1 < 34 && y < r1 + 3;
    FAR.px(x, y, snow ? (y < r1 + 1 ? '#f4f8fb' : '#dbe6ee') : (y < r1 + 1 ? '#b3c4d1' : '#9fb2c2'));
  }
  var r2 = Math.round(46 + 4 * Math.sin(x / 29 + 2) + 1.5 * Math.sin(x / 11));
  for (y = r2; y < G; y++) NEAR.px(x, y, y < r2 + 1 ? '#a9c49c' : '#8eab85');
}
for (x = -2; x < W + 4; x += 4) {
  var th = 7 + Math.floor(rnd() * 5);
  TREES.tri(x + 2, G - th, th, 2 + Math.floor(rnd() * 2), '#3f7a52', '#336544');
}
for (y = G; y < H; y++) for (x = 0; x < W; x++) TREES.d[(y * W + x) * 4 + 3] = 0;

// ground: drier grass in 3 bands, tufts, a trampled earth patch around the fire, wildflowers
for (y = G; y < H; y++) { var gc = y < G + 2 ? '#a4c35c' : (y < G + 13 ? '#86a94c' : '#789a43'); for (x = 0; x < W; x++) GROUND.px(x, y, gc); }
for (i = 0; i < 220; i++) { x = Math.floor(rnd() * W); y = G + 2 + Math.floor(rnd() * (H - G - 2)); var lt = rnd() < 0.5; GROUND.px(x, y, lt ? '#9bbb55' : '#5f8236'); if (rnd() < 0.5) GROUND.px(x, y - 1, lt ? '#9bbb55' : '#5f8236'); }
GROUND.ell(78, 77, 34, 3.2, '#b89a6a'); GROUND.ell(78, 77, 30, 2.2, '#c9ad7d');
for (i = 0; i < 40; i++) { x = 50 + Math.floor(rnd() * 56); y = 75 + Math.floor(rnd() * 5); GROUND.px(x, y, rnd() < 0.5 ? '#9a7e50' : '#d8c08e'); }
for (i = 0; i < 24; i++) { x = Math.floor(rnd() * W); y = G + 4 + Math.floor(rnd() * (H - G - 6)); GROUND.px(x, y, ['#ffffff', '#ffe27a', '#c9a0ff'][Math.floor(rnd() * 3)]); GROUND.px(x, y + 1, '#3a7a3a'); }
function edge(yv) { return Math.round(326 - (yv - G) * 1.2); }
for (y = G; y < H; y++) for (x = edge(y); x < W; x++) GROUND.px(x, y, x < edge(y) + 2 ? '#d8c9a0' : '#4f93c4');
for (i = 0; i < 50; i++) { y = G + 1 + Math.floor(rnd() * (H - G - 1)); x = edge(y) + 3 + Math.floor(rnd() * (W - edge(y) - 6)); GROUND.rect(x, y, 3, 1, rnd() < 0.6 ? '#8cc8e8' : '#3b79ad'); }

// ---- objects --------------------------------------------------------------------
function obj(w, h, cx, foot, fn, o) { o = o || {}; return { w: w, h: h, x: cx - Math.floor(w / 2), y: foot - h, fn: fn, flip: o.flip, sh: o.sh, fy: o.z || foot, foot: foot, cx: cx }; }
function drawObj(buf, ob) { // shadow, then the outlined sprite
  if (ob.sh) buf.ell(ob.cx, ob.foot, ob.sh, 1.5, '#5f8236');
  var tb = new Buf(ob.w, ob.h); ob.fn(tb); if (ob.flip) tb = mirror(tb);
  blit(buf, outlined(tb, OUT), ob.x - 1, ob.y - 1);
}
function layerOf(list) { var b = new Buf(W, H); list.sort(function (p, q) { return p.fy - q.fy; }); for (var k = 0; k < list.length; k++) drawObj(b, list[k]); return b; }

// always-present
var backProps = [obj(100, 54, 50, 66, cliff, { sh: 34 }), obj(16, 26, 204, 65, pine, { sh: 6 }), obj(42, 28, 236, 64, mammoth, { sh: 17 })];
var midProps = [obj(12, 8, 198, 71, bush, { sh: 5 }),
  obj(10, 6, 30, 76, rocks, { sh: 4 }), obj(10, 6, 250, 76, rocks, { sh: 4 }), obj(10, 6, 120, 78, rocks, { sh: 4 })];
// the fire pit only exists once the fire is found (state-driven, like a building)
// warm light cast by the fire at night: dithered bands round the pit and a small pool in the cave
// mouth. Semi-transparent warm orange; the game draws it additively, fading it in as it darkens.
function glowLayer() {
  var g = new Buf(W, H), gx, gy, best, k;
  var pools = [[70, 72, 46, 20, 1.0], [34, 62, 13, 8, 0.7]];
  var bands = [[0.35, 170], [0.6, 115], [0.85, 66], [1.0, 34]];
  for (gy = 0; gy < H; gy++) for (gx = 0; gx < W; gx++) {
    best = 0;
    for (k = 0; k < pools.length; k++) {
      var p = pools[k], ddx = (gx - p[0]) / p[2], ddy = (gy - p[1]) / p[3];
      var dd = Math.sqrt(ddx * ddx + ddy * ddy), v = 0;
      for (var bi = 0; bi < bands.length; bi++) {
        if (dd < bands[bi][0]) { v = bands[bi][1]; if (bi + 1 < bands.length && bands[bi][0] - dd < 0.07 && ((gx + gy) & 1) == 0) v = bands[bi + 1][1]; break; }
      }
      best = Math.max(best, Math.round(v * p[4]));
    }
    if (best > 0) { var gi = (gy * W + gx) * 4; g.d[gi] = 255; g.d[gi + 1] = 154; g.d[gi + 2] = 60; g.d[gi + 3] = best; }
  }
  return g;
}
var FIREPIT = [16, 14, 72, 78];
// warm firelight low inside the cave mouth: the cliff is at (0, 12), its mouth dither at (26..42, 46..53)
function firelit(buf) {
  for (var fy = 46; fy < 54; fy++) for (var fx = 26; fx < 43; fx++)
    if (((fx + fy) & 1) == 0 && fy > 46 + Math.abs(fx - 34) / 3) buf.px(fx, fy + 12, '#a8643a');
  return buf;
}
// state-driven building slots: id -> [bufW, bufH, cx, foot, drawFn, shadow]
var SLOTS = {
  lookout: [26, 34, 300, 66, lookout, 11], drying_rack: [22, 20, 132, 70, dryrack, 9],
  knapping_spot: [18, 10, 160, 79, knapspot, 7], hut: [28, 22, 268, 71, leanto, 12], field: [44, 10, 228, 78, field, 0]
};
var FLOWER = [12, 12, 106, 73];
var SITE = [22, 10];

var layerFiles = { sky: SKY, far_hills: FAR, near_hills: NEAR, trees: TREES, ground: GROUND,
  static_back: layerOf(backProps.slice()), static_mid: layerOf(midProps.slice()) };
for (var id in SLOTS) {
  var sl = SLOTS[id];
  layerFiles['building_' + id] = layerOf([obj(sl[0], sl[1], sl[2], sl[3], sl[4], { sh: sl[5] })]);
  layerFiles['site_' + id] = layerOf([obj(SITE[0], SITE[1], sl[2], sl[3], buildsite, { sh: 8 })]);
}
layerFiles.flower_sprout = layerOf([obj(FLOWER[0], FLOWER[1], FLOWER[2], FLOWER[3], sprout, { sh: 3 })]);
layerFiles.flower_bloom = layerOf([obj(FLOWER[0], FLOWER[1], FLOWER[2], FLOWER[3], strangeflower, { sh: 5 })]);
for (i = 0; i < FLAMES.length; i++) layerFiles['fire_pit_' + i] = firelit(layerOf([obj(FIREPIT[0], FIREPIT[1], FIREPIT[2], FIREPIT[3], flameFn(i), { sh: 8 })]));
function flameFn(frame) { return function (b) { firepit(b, frame); }; }
layerFiles.fire_glow = glowLayer();

// ---- composite preview: everything built, villagers placed -------------------------
var people = [
  obj(27, 27, 88, 78, vil({ pal: PAL.furBrown, fur: true, hair: 'long', pose: 'idle' }), { sh: 5, flip: 1 }),
  obj(27, 27, 144, 79, vil({ pal: PAL.furGrey, fur: true, stone: true, pose: 'hammer', f: 1, hair: 'short' }), { sh: 5 }),
  obj(27, 27, 180, 77, vil({ pal: PAL.furTan, fur: true, role: 'gatherer', pose: 'walk', f: 1, hair: 'bun' }), { sh: 5 }),
  obj(27, 27, 214, 79, vil({ pal: PAL.furOchre, fur: true, stone: true, pose: 'spear', hair: 'tuft' }), { sh: 5 }),
  obj(27, 27, 300, 44, vil({ pal: PAL.furBrown, fur: true, hair: 'short', pose: 'idle' }), { z: 68 })];
var all = backProps.concat(midProps, people, [obj(FIREPIT[0], FIREPIT[1], FIREPIT[2], FIREPIT[3], firepit, { sh: 8 })]);
for (id in SLOTS) { sl = SLOTS[id]; if (id != 'field') all.push(obj(sl[0], sl[1], sl[2], sl[3], sl[4], { sh: sl[5] })); }
all.push(obj(FLOWER[0], FLOWER[1], FLOWER[2], FLOWER[3], strangeflower, { sh: 5 }));
var FG = layerOf(all);
firelit(FG);

var COMP = new Buf(W, H), IMG = SPR.layer(0).cel(0).image;
var stack = [SKY, FAR, NEAR, TREES, GROUND, FG];
for (i = 0; i < stack.length; i++) blit(COMP, stack[i], 0, 0);
IMG.putImageData(COMP.d);
SPR.save();

// previews, then game assets
var prev = ['sky', 'far_hills', 'near_hills', 'trees', 'ground'];
for (i = 0; i < prev.length; i++) { IMG.putImageData(layerFiles[prev[i]].d); SPR.saveAs(DIR + 'art/reference/layers/cave_' + prev[i] + '.png'); }
var count = 0;
for (var name in layerFiles) { IMG.putImageData(layerFiles[name].d); SPR.saveAs(GAME + name + '.png'); count++; }
console.log('cave world done, ' + count + ' game layers');
