// @open art/reference/weather.png
// @canvas 384x1600
// Weather, one 384-wide sheet of 80-pixel rows (the size of the viewport) -> game/assets/world/
// weather.png. Everything is transparent light and shade, with no outline (it is weather, not an
// object). The game fades each piece with the sprite's own alpha. Rows are mirrored in
// game/scripts/view/weather_layer.gd: change both together.
//   0-2 rain (a falling loop)         3-5 snow (a falling loop)      6-7 heat shimmer
//   8   cracked ground, camp page     9 cracked ground, west page    10-11 flood water, camp page
//   12-13 flood water, east page      14-16 tornado funnel (sways)   17-18 storm clouds (drift)
//   19  wreckage: two 28x14 cells at x 0 and x 32, drawn at the foot of a broken building
seed = 77;
var IMG = SPR.layer(0).cel(0).image;
var S = new Buf(384, 1600), i, j, k, x, y;
function row(r) { return r * 80; }

// ---- rain: streaks that fall 9 pixels a frame and repeat every 27, so three frames loop ----
var streaks = [];
for (i = 0; i < 74; i++) streaks.push([Math.floor(rnd() * 384), Math.floor(rnd() * 27)]);
for (k = 0; k < 3; k++) for (i = 0; i < streaks.length; i++) for (j = 0; j < 3; j++) {
  x = streaks[i][0]; y = (streaks[i][1] + 9 * k) % 27 + 27 * j;
  if (y > 76) continue;
  S.px(x, row(k) + y, '#e4f2ff'); S.px(x, row(k) + y + 1, '#bcd8f2'); S.px(x - 1, row(k) + y + 2, '#bcd8f2');
}

// ---- snow: flakes that fall 6 pixels a frame (period 18) and sway ----
var flakes = [];
for (i = 0; i < 90; i++) flakes.push([Math.floor(rnd() * 384), Math.floor(rnd() * 18), rnd() < 0.18]);
for (k = 0; k < 3; k++) for (i = 0; i < flakes.length; i++) for (j = 0; j < 5; j++) {
  x = flakes[i][0] + (k == 1 ? 1 : (k == 2 ? -1 : 0)); y = (flakes[i][1] + 6 * k) % 18 + 18 * j;
  if (y > 78) continue;
  S.px(x, row(3 + k) + y, '#ffffff');
  if (flakes[i][2]) { S.px(x + 1, row(3 + k) + y, '#e6eefa'); S.px(x, row(3 + k) + y + 1, '#e6eefa'); }
}

// ---- heat shimmer: pale wavering dashes just above the ground ----
for (k = 0; k < 2; k++) {
  for (i = 0; i < 26; i++) {
    var sx = Math.floor(rnd() * 372), sy = 44 + Math.floor(rnd() * 18), len = 6 + Math.floor(rnd() * 9);
    for (j = 0; j < len; j++) S.px(sx + j + (k ? 2 : 0), row(6 + k) + sy + ((j >> 2) & 1) * (k ? 0 : 1), '#fff0c0');
  }
}

// ---- cracked ground: dark zig-zag cracks across the ground band ----
function cracks(r, x0, x1) {
  for (i = 0; i < 16; i++) {
    var cx = x0 + Math.floor(rnd() * (x1 - x0)), cy = 66 + Math.floor(rnd() * 12), n = 4 + Math.floor(rnd() * 5);
    for (j = 0; j < n; j++) {
      S.px(cx, row(r) + cy, '#6a4e36');
      if ((j & 1) == 0) cx += (rnd() < 0.5 ? -1 : 1); else cy += 1;
      if ((j & 3) == 3) S.px(cx + 1, row(r) + cy, '#8a6a4a');
    }
  }
}
cracks(8, 8, 280);
cracks(9, 8, 376);

// ---- flood water: the river over its banks, two frames of ripples ----
function water(r, x0, x1, topY, wave) {
  for (x = x0; x <= x1; x++) {
    var edge = topY + Math.round(1.6 * Math.sin(x * 0.21 + wave * 0.3)) + (x < x0 + 6 ? (x0 + 6 - x) : 0) + (x > x1 - 6 ? (x - (x1 - 6)) : 0);
    for (y = edge; y < 80; y++) S.px(x, row(r) + y, ((x + y * 2) % 11 == wave * 4 % 11) ? '#9bd0f0' : '#5aa3d8');
    S.px(x, row(r) + edge, '#9bd0f0');
  }
  for (i = 0; i < 24; i++) {
    var rx = x0 + 4 + Math.floor(rnd() * (x1 - x0 - 12)), ry = topY + 4 + Math.floor(rnd() * 8) + wave;
    S.px(rx, row(r) + ry, '#d6efff'); S.px(rx + 1, row(r) + ry, '#d6efff'); S.px(rx + 2, row(r) + ry, '#d6efff');
  }
}
water(10, 176, 383, 66, 0); water(11, 176, 383, 66, 1);
water(12, 70, 330, 62, 0); water(13, 70, 330, 62, 1);

// ---- tornado funnel: stacked slices, narrowing to the ground, swaying a little each frame ----
function funnel(r, cx, sway) {
  for (y = 14; y < 78; y++) {
    var t = (y - 14) / 64, half = Math.round(15 * (1 - t) + 2), off = Math.round(sway * (1 - t) * 3 + 3 * Math.sin(y * 0.35 + sway));
    for (x = cx - half + off; x <= cx + half + off; x++) {
      var shade = (x - (cx - half + off)) / (2 * half);
      S.px(x, row(r) + y, ((y >> 1) & 1) ? (shade < 0.4 ? '#8d91a3' : '#6c7087') : (shade < 0.4 ? '#a7abbc' : '#7d8197'));
    }
  }
  for (i = 0; i < 14; i++) S.px(cx - 14 + Math.floor(rnd() * 28) + sway * 2, row(r) + 60 + Math.floor(rnd() * 16), (i & 1) ? '#8a5a36' : '#cfc7a8');
  S.ell(cx + sway, row(r) + 76, 11, 2, '#8d8a7f');
}
funnel(14, 170, -1); funnel(15, 170, 0); funnel(16, 170, 1);

// ---- storm clouds: a dark band over the sky, drifting three pixels between frames ----
for (k = 0; k < 2; k++) {
  var cseed = 11; seed = cseed;
  for (i = 0; i < 16; i++) {
    var cx2 = Math.floor(rnd() * 400) - 8 + k * 3, cy2 = 6 + Math.floor(rnd() * 20), rx2 = 22 + Math.floor(rnd() * 20);
    S.ell(cx2, row(17 + k) + cy2 + 4, rx2, 6, '#3c4156');
    S.ell(cx2, row(17 + k) + cy2, rx2 - 2, 7, '#4d546e');
    S.ell(cx2 - 4, row(17 + k) + cy2 - 3, rx2 - 9, 4, '#5f6784');
  }
}

// ---- wreckage: broken planks and strewn straw ----
function wreck(ox) {
  var oy = row(19);
  S.rect(ox + 2, oy + 9, 12, 2, '#8a5a36'); S.rect(ox + 2, oy + 9, 12, 1, '#a6703f');
  S.rect(ox + 12, oy + 6, 2, 6, '#8a5a36'); S.line(ox + 16, oy + 12, ox + 25, oy + 7, '#6f4528', 2);
  S.rect(ox + 6, oy + 5, 7, 2, '#a6703f'); S.rect(ox + 1, oy + 11, 5, 2, '#6f4528');
  for (j = 0; j < 12; j++) S.px(ox + 1 + Math.floor(rnd() * 26), oy + 8 + Math.floor(rnd() * 5), '#d9c46a');
}
wreck(0); wreck(32);

IMG.putImageData(S.d); SPR.save();
SPR.saveAs(DIR + 'game/assets/world/weather.png');
console.log('weather done');
