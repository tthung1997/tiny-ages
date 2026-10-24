// @open art/reference/ui_achievements.png
// @canvas 440x20
// The achievement icons, one 440x20 sheet of 22 round medals (20x20 each, in the order of
// AchievementPresenter.ICON_ORDER, then a plain rosette for any achievement without its own)
// -> art/reference/ui_achievements.png and game/assets/ui/achievements.png. The cell order is
// mirrored in game/scripts/ui/achievement_presenter.gd; append new icons at the end.
seed = 11;
var IMG = SPR.layer(0).cel(0).image;
var INK = '#2b2d42', CREAM = '#f3e9d2', RIM = '#a8843c';

function fire(g) {
  g.rect(2, 10, 8, 2, WOOD); g.rect(2, 10, 8, 1, WOODL);
  g.ell(6, 7, 3.2, 3.6, '#e8504a'); g.ell(6, 7.5, 2.2, 2.8, '#f59a3a'); g.ell(6, 8.5, 1.2, 1.6, '#ffe27a');
  g.rect(5, 4, 2, 1, '#e8504a'); g.px(6, 3, '#e8504a'); g.px(6, 2, '#e8504a');
}
function stoneTools(g) {
  g.line(2, 10, 7, 5, WOOD, 2);
  g.rect(7, 1, 4, 5, '#9aa0aa'); g.rect(7, 1, 1, 5, '#bcc0cc'); g.rect(10, 2, 1, 3, '#6a6f7a');
  g.px(7, 6, '#e8504a'); g.px(6, 7, '#e8504a');
}
function food(g) {
  g.ell(5, 6, 3.6, 3.2, '#b86a4a'); g.ell(4, 5, 2, 1.6, '#d98a68');
  g.rect(8, 7, 3, 2, '#c9b99a'); g.px(10, 6, '#c9b99a'); g.px(10, 9, '#c9b99a');
}
function stories(g) {
  g.ell(6, 5, 4.6, 3.4, '#8fbfe0'); g.ell(5, 4, 2.6, 1.6, '#b8dcf0');
  g.px(3, 8, '#8fbfe0'); g.px(2, 9, '#8fbfe0'); g.px(4, 8, '#8fbfe0');
  g.px(4, 5, INK); g.px(6, 5, INK); g.px(8, 5, INK);
}
function group(g) {
  g.rect(1, 6, 4, 5, WOOD); g.ell(3, 4, 1.6, 1.6, SK); g.ell(3, 3.3, 1.7, 1, '#4a3320');
  g.rect(7, 6, 4, 5, '#4a7fa8'); g.ell(9, 4, 1.6, 1.6, SK); g.ell(9, 3.3, 1.7, 1, '#4a3320');
  g.rect(4, 5, 4, 6, '#a8452f'); g.ell(6, 3, 1.8, 1.8, SK); g.ell(6, 2.2, 1.9, 1.1, '#4a3320');
}
function garden(g) {
  g.rect(6, 6, 1, 5, '#3f9a52'); g.rect(4, 8, 2, 1, '#3f9a52'); g.rect(7, 7, 2, 1, '#3f9a52');
  var p = [[6, 1.6], [4, 3], [8, 3], [4.8, 5], [7.2, 5]];
  for (var i = 0; i < p.length; i++) g.ell(p[i][0], p[i][1], 1.4, 1.4, '#b07ce8');
  g.ell(6, 3.4, 1, 1, '#ffe27a');
}
function roof(g) {
  for (var y = 0; y < 5; y++) g.rect(5 - y, 1 + y, 2 + 2 * y, 1, '#d9a566');
  g.rect(1, 5, 10, 1, '#b07f44');
  g.rect(2, 6, 8, 5, '#b86a4a'); g.rect(5, 8, 2, 3, '#3a2a22');
}
function harvest(g) {
  g.line(4, 8, 3, 2, '#8fb843'); g.line(6, 8, 6, 1, '#8fb843'); g.line(8, 8, 9, 2, '#8fb843');
  g.ell(3, 2.5, 1, 1.6, '#e6c84a'); g.ell(6, 1.8, 1, 1.6, '#e6c84a'); g.ell(9, 2.5, 1, 1.6, '#e6c84a');
  g.ell(6, 9, 5, 2.8, '#c58f50'); g.rect(1, 8, 10, 1, '#8f4f38'); g.px(3, 10, '#8f4f38'); g.px(6, 11, '#8f4f38'); g.px(9, 10, '#8f4f38');
}
function clay(g) {
  g.ell(6, 7, 4.2, 3.6, '#b86a4a'); g.px(4, 6, '#d98a68'); g.px(4, 7, '#d98a68');
  g.rect(4, 2, 4, 2, '#b86a4a'); g.rect(3, 2, 6, 1, '#8f4f38'); g.rect(2, 7, 8, 1, '#8f4f38'); g.rect(4, 10, 4, 1, '#8f4f38');
}
function cloth(g) {
  for (var j = 0; j < 5; j++) for (var i = 0; i < 5; i++)
    g.rect(1 + i * 2, 1 + j * 2, 2, 2, (i + j) % 2 ? '#e8c46a' : '#4aa0c8');
}
function village(g) {
  for (var h = 0; h < 2; h++) {
    var ox = h ? 6 : 1;
    g.rect(ox, 7, 5, 4, '#b86a4a'); g.rect(ox + 2, 9, 1, 2, '#3a2a22');
    g.rect(ox - 1, 6, 7, 1, '#d9a566'); g.rect(ox, 5, 5, 1, '#d9a566'); g.rect(ox + 1, 4, 3, 1, '#d9a566');
  }
}
function greenStone(g) {
  g.ell(6, 7, 4.8, 3.8, '#2f8f66'); g.ell(5, 6, 2.6, 1.8, '#5ccf94'); g.px(4, 5, '#c8f5de');
  g.rect(3, 10, 6, 1, '#1f6648');
}
function field(g) {
  g.rect(1, 2, 10, 9, '#8f6a3a');
  for (var r = 0; r < 4; r++) for (var x = 2; x < 11; x += 2) { g.px(x, 3 + 2 * r, '#7cd070'); g.px(x, 2 + 2 * r, '#3f9a52'); }
}
function pen(g) {
  g.rect(1, 5, 10, 1, WOODL); g.rect(1, 8, 10, 1, WOODL);
  g.rect(1, 3, 1, 8, WOOD); g.rect(5, 3, 2, 8, WOOD); g.rect(10, 3, 1, 8, WOOD);
}
function butterfly(g) {
  g.ell(3.5, 4, 2.8, 2.6, '#b07ce8'); g.ell(8.5, 4, 2.8, 2.6, '#b07ce8');
  g.ell(4, 8, 2, 2, '#d8b8ff'); g.ell(8, 8, 2, 2, '#d8b8ff');
  g.px(3, 4, '#ffe27a'); g.px(9, 4, '#ffe27a');
  g.rect(6, 3, 1, 7, INK); g.px(5, 2, INK); g.px(7, 2, INK);
}
function crucible(g) {
  g.rect(1, 4, 5, 1, '#f59a3a'); g.rect(1, 5, 5, 4, '#6f6c78'); g.rect(2, 9, 3, 1, '#6f6c78');
  g.rect(1, 5, 1, 4, '#8d8a93'); g.px(2, 4, '#ffe27a'); g.px(3, 4, '#ffe27a');
  g.line(6, 4, 8, 6, '#f59a3a', 1); g.px(8, 7, '#ffe27a');
  g.rect(7, 8, 5, 3, '#d9a23a'); g.rect(7, 8, 5, 1, '#f7d56a'); g.rect(7, 10, 5, 1, '#9a6a1f');
}
function alloy(g) {
  g.rect(3, 3, 7, 2, '#f7d56a'); g.rect(1, 5, 10, 5, '#d9a23a');
  g.rect(1, 5, 10, 1, '#f7d56a'); g.rect(1, 9, 10, 1, '#9a6a1f'); g.rect(10, 5, 1, 5, '#9a6a1f');
  g.px(3, 7, '#c8ccd6'); g.px(4, 7, '#c8ccd6'); g.px(4, 8, '#9aa0aa'); g.px(7, 6, '#c8ccd6');
  g.px(8, 8, '#c8ccd6'); g.px(8, 7, '#9aa0aa');
}
function brickWall(g) {
  g.rect(1, 2, 10, 8, '#e8d4a8');
  for (var r = 0; r < 4; r++) for (var b = -1; b < 3; b++) {
    var bx = 1 + b * 4 + (r % 2) * 2;
    var x0 = Math.max(bx, 1), x1 = Math.min(bx + 3, 11);
    if (x1 > x0) g.rect(x0, 2 + r * 2, x1 - x0, 1, (b + r) % 2 ? '#c98a55' : '#b86a4a');
  }
}
function wheel(g) {
  g.ell(6, 6, 5, 5, WOOD); g.ell(6, 6, 3.6, 3.6, CREAM);
  g.line(6, 2, 6, 10, WOOD, 1); g.line(2, 6, 10, 6, WOOD, 1);
  g.line(3, 3, 9, 9, WOOD, 1); g.line(9, 3, 3, 9, WOOD, 1);
  g.ell(6, 6, 1.6, 1.6, '#d9a23a'); g.px(5, 5, '#f7d56a'); g.px(6, 1, WOODL); g.px(1, 6, WOODL);
}
function town(g) {
  g.rect(4, 4, 4, 6, '#c98a55'); g.rect(4, 4, 1, 6, '#e0a874');
  for (var y = 0; y < 3; y++) g.rect(5 - y, 1 + y, 2 + 2 * y, 1, '#b86a4a');
  g.rect(0, 7, 4, 3, '#b86a4a'); g.rect(8, 7, 4, 3, '#b86a4a');
  g.rect(0, 6, 4, 1, '#d9a566'); g.rect(8, 6, 4, 1, '#d9a566');
  g.rect(5, 7, 2, 3, '#3a2a22'); g.px(5, 6, '#3a2a22'); g.px(6, 6, '#3a2a22'); g.rect(0, 10, 12, 1, '#8f6a3a');
}
function sail(g) {
  g.rect(6, 1, 1, 7, WOOD); g.tri(6, 1, 6, 4, '#f3e9d2', '#e8504a');
  g.rect(2, 7, 9, 2, WOOD); g.rect(1, 7, 1, 1, WOOD); g.rect(2, 7, 9, 1, WOODL);
  for (var x = 0; x < 12; x++) { g.px(x, 9 + (x % 4 < 2 ? 0 : 1), '#4a9ac8'); g.px(x, 10 + (x % 4 < 2 ? 0 : 1), '#8fbfe0'); }
}
function rosette(g) {
  g.rect(3, 8, 2, 3, '#e8504a'); g.rect(7, 8, 2, 3, '#c43a34');
  g.ell(6, 5, 3.6, 3.6, '#e8504a'); g.ell(6, 5, 1.8, 1.8, CREAM);
}

var GLYPHS = [fire, stoneTools, food, stories, group, garden, roof, harvest, clay, cloth, village,
  greenStone, field, pen, butterfly, crucible, alloy, brickWall, wheel, town, sail, rosette];
var SHEET = new Buf(440, 20);
for (var i = 0; i < GLYPHS.length; i++) {
  var medal = new Buf(18, 18);
  medal.ell(8.5, 8.5, 8.6, 8.6, RIM); medal.ell(8.5, 8.5, 7.2, 7.2, CREAM);
  var g = new Buf(12, 12); GLYPHS[i](g);
  blit(medal, g, 3, 3);
  blit(SHEET, outlined(medal, OUT), i * 20, 0);
}

IMG.putImageData(SHEET.d); SPR.save();
SPR.saveAs(DIR + 'game/assets/ui/achievements.png');
console.log('ui achievements done');
