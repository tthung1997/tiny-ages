// @open art/reference/cave_strip.png
// @canvas 384x80
// Cave Age strip sketch: 384x80, ground line y=56. Same layer structure as strip.js, with a cliff
// and cave mouth as the home of the settlement, furs and stone tools, a woolly mammoth, and the
// first slice's buildings (Lookout, Drying Rack, Knapping Spot) plus the strange flower.
// Composite -> cave_strip.png; layers -> art/reference/layers/cave_*.png.
seed = 12;
var W = 384, H = 80, G = 56;
var SKY = new Buf(W, H), FAR = new Buf(W, H), NEAR = new Buf(W, H), TREES = new Buf(W, H);
var S = new Buf(W, H), x, y, i;

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

// ground: drier grass in 3 bands, tufts, a trampled earth patch around the fire, a few wildflowers
for (y = G; y < H; y++) { var gc = y < G + 2 ? '#a4c35c' : (y < G + 13 ? '#86a94c' : '#789a43'); for (x = 0; x < W; x++) S.px(x, y, gc); }
for (i = 0; i < 220; i++) { x = Math.floor(rnd() * W); y = G + 2 + Math.floor(rnd() * (H - G - 2)); var lt = rnd() < 0.5; S.px(x, y, lt ? '#9bbb55' : '#5f8236'); if (rnd() < 0.5) S.px(x, y - 1, lt ? '#9bbb55' : '#5f8236'); }
S.ell(78, 77, 34, 3.2, '#b89a6a'); S.ell(78, 77, 30, 2.2, '#c9ad7d');
for (i = 0; i < 40; i++) { x = 50 + Math.floor(rnd() * 56); y = 75 + Math.floor(rnd() * 5); S.px(x, y, rnd() < 0.5 ? '#9a7e50' : '#d8c08e'); }
for (i = 0; i < 24; i++) { x = Math.floor(rnd() * W); y = G + 4 + Math.floor(rnd() * (H - G - 6)); S.px(x, y, ['#ffffff', '#ffe27a', '#c9a0ff'][Math.floor(rnd() * 3)]); S.px(x, y + 1, '#3a7a3a'); }

// river on the right (same shape as the day strip)
function edge(yv) { return Math.round(326 - (yv - G) * 1.2); }
for (y = G; y < H; y++) for (x = edge(y); x < W; x++) S.px(x, y, x < edge(y) + 2 ? '#d8c9a0' : '#4f93c4');
for (i = 0; i < 50; i++) { y = G + 1 + Math.floor(rnd() * (H - G - 1)); x = edge(y) + 3 + Math.floor(rnd() * (W - edge(y) - 6)); S.rect(x, y, 3, 1, rnd() < 0.6 ? '#8cc8e8' : '#3b79ad'); }

// objects: add(bufW, bufH, centreX, footY, drawFn, {sh: shadow radius, flip, z: sort override})
var objs = [];
function add(w, h, cx, foot, fn, o) { o = o || {}; objs.push({ w: w, h: h, x: cx - Math.floor(w / 2), y: foot - h, fn: fn, flip: o.flip, sh: o.sh, fy: o.z || foot, foot: foot, cx: cx }); }
add(100, 54, 50, 66, cliff, { sh: 34 });
add(16, 14, 72, 78, firepit, { sh: 8 });
add(27, 27, 88, 78, vil({ pal: PAL.furBrown, fur: true, hair: 'long', pose: 'idle' }), { sh: 5, flip: 1 });
add(12, 12, 106, 73, strangeflower, { sh: 5 });
add(22, 20, 132, 70, dryrack, { sh: 9 });
add(27, 27, 144, 79, vil({ pal: PAL.furGrey, fur: true, stone: true, pose: 'hammer', f: 1, hair: 'short' }), { sh: 5 });
add(18, 10, 160, 79, knapspot, { sh: 7 });
add(27, 27, 180, 77, vil({ pal: PAL.furTan, fur: true, role: 'gatherer', pose: 'walk', f: 1, hair: 'bun' }), { sh: 5 });
add(12, 8, 198, 71, bush, { sh: 5 });
add(16, 26, 204, 65, pine, { sh: 6 });
add(27, 27, 214, 79, vil({ pal: PAL.furOchre, fur: true, stone: true, pose: 'spear', hair: 'tuft' }), { sh: 5 });
add(42, 28, 236, 64, mammoth, { sh: 17 });
add(28, 22, 268, 71, leanto, { sh: 12 });
add(26, 34, 300, 66, lookout, { sh: 11 });
add(27, 27, 300, 44, vil({ pal: PAL.furBrown, fur: true, hair: 'short', pose: 'idle' }), { z: 68 });
add(10, 6, 30, 76, rocks, { sh: 4 }); add(10, 6, 250, 76, rocks, { sh: 4 }); add(10, 6, 120, 78, rocks, { sh: 4 });

objs.sort(function (a, b) { return a.fy - b.fy; });
for (i = 0; i < objs.length; i++) { var ob = objs[i]; if (ob.sh) S.ell(ob.cx, ob.foot, ob.sh, 1.5, '#5f8236'); }
for (i = 0; i < objs.length; i++) {
  ob = objs[i]; var tb = new Buf(ob.w, ob.h); ob.fn(tb); if (ob.flip) tb = mirror(tb);
  blit(S, outlined(tb, OUT), ob.x - 1, ob.y - 1);
}

var COMP = new Buf(W, H), IMG = SPR.layer(0).cel(0).image;
var stack = [SKY, FAR, NEAR, TREES, S];
for (i = 0; i < stack.length; i++) blit(COMP, stack[i], 0, 0);
IMG.putImageData(COMP.d);
SPR.save();
var names = ['sky', 'far_hills', 'near_hills', 'trees', 'ground'];
for (i = 0; i < stack.length; i++) {
  IMG.putImageData(stack[i].d);
  SPR.saveAs(DIR + 'art/reference/layers/cave_' + names[i] + '.png');
}
console.log('cave strip done');
