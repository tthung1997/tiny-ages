// @open art/reference/ui_weather.png
// @canvas 132x12
// The season and weather glyphs for the strip: eleven 12x12 cells in one 132x12 sheet -> art/
// reference/ui_weather.png and game/assets/ui/weather_glyphs.png. Cells: 0 spring (a sprout),
// 1 summer (a sun), 2 autumn (a leaf), 3 winter (a snowflake), 4 rain, 5 snow, 6 storm, 7 drought,
// 8 flood, 9 tornado, 10 wreckage. Mirrored in game/scripts/view/weather_look.gd (GLYPH_CELLS).
seed = 9;
var IMG = SPR.layer(0).cel(0).image;
var SHEET = new Buf(132, 12);

function cloud(b, c1, c2) { b.ell(5, 4, 4.5, 2.5, c1); b.ell(3, 5, 2.5, 2, c1); b.ell(7, 5, 2.5, 2, c1); b.rect(1, 5, 8, 1, c2); }
var ICONS = [
  function (b) { b.rect(4, 4, 1, 5, '#3a7a3a'); b.ell(2, 3, 2, 1.5, '#58b05f'); b.ell(7, 2, 2.4, 1.6, '#7cd070'); b.px(4, 9, '#8a5a36'); },
  function (b) { b.ell(5, 5, 2.6, 2.6, '#ffd84a'); b.rect(4, 0, 2, 1, '#ffd84a'); b.rect(4, 9, 2, 1, '#ffd84a'); b.rect(0, 4, 1, 2, '#ffd84a'); b.rect(9, 4, 1, 2, '#ffd84a'); b.px(1, 1, '#ffd84a'); b.px(8, 1, '#ffd84a'); b.px(1, 8, '#ffd84a'); b.px(8, 8, '#ffd84a'); },
  function (b) { b.ell(5, 4, 3.5, 3.5, '#e8873a'); b.ell(4, 3, 1.5, 1.5, '#f2b05a'); b.line(5, 5, 5, 9, '#8a5a36', 1); b.px(7, 6, '#c8602a'); },
  function (b) { b.rect(5, 0, 1, 10, '#e6f1ff'); b.rect(0, 5, 10, 1, '#e6f1ff'); b.line(1, 1, 8, 8, '#bcd8f2', 1); b.line(8, 1, 1, 8, '#bcd8f2', 1); b.rect(4, 4, 3, 3, '#ffffff'); },
  function (b) { cloud(b, '#aab6c8', '#8793a8'); b.px(2, 7, '#4f9bd9'); b.px(2, 8, '#4f9bd9'); b.px(5, 8, '#4f9bd9'); b.px(5, 9, '#4f9bd9'); b.px(8, 7, '#4f9bd9'); b.px(8, 8, '#4f9bd9'); },
  function (b) { cloud(b, '#d4dbe6', '#aab6c8'); b.px(2, 8, '#ffffff'); b.px(5, 7, '#ffffff'); b.px(5, 9, '#ffffff'); b.px(8, 8, '#ffffff'); b.px(3, 6, '#ffffff'); },
  function (b) { cloud(b, '#59607a', '#434960'); b.line(5, 6, 3, 8, '#ffe27a', 1); b.line(3, 8, 6, 8, '#ffe27a', 1); b.line(6, 8, 4, 10, '#ffe27a', 1); },
  function (b) { b.ell(5, 4, 3, 3, '#ff9a3a'); b.px(4, 3, '#ffd89a'); b.line(0, 8, 4, 8, '#8a5a36', 1); b.line(4, 8, 5, 10, '#8a5a36', 1); b.line(5, 8, 9, 9, '#8a5a36', 1); b.px(7, 7, '#8a5a36'); },
  function (b) { b.rect(0, 3, 10, 1, '#7cc4ee'); b.rect(0, 5, 10, 4, '#4f9bd9'); b.px(2, 4, '#4f9bd9'); b.px(6, 4, '#4f9bd9'); b.px(8, 4, '#4f9bd9'); b.px(3, 6, '#d6efff'); b.px(4, 6, '#d6efff'); b.px(7, 7, '#d6efff'); b.px(8, 7, '#d6efff'); },
  function (b) { b.rect(0, 0, 10, 2, '#7d8197'); b.rect(1, 2, 8, 2, '#8d91a3'); b.rect(2, 4, 6, 2, '#7d8197'); b.rect(3, 6, 4, 2, '#8d91a3'); b.rect(4, 8, 2, 2, '#6c7087'); },
  function (b) { b.rect(0, 7, 8, 2, WOOD); b.rect(0, 7, 8, 1, WOODL); b.rect(6, 3, 2, 6, WOOD); b.line(2, 5, 6, 2, '#6f4528', 1); b.px(1, 9, '#d9c46a'); b.px(9, 8, '#d9c46a'); }
];
for (var n = 0; n < ICONS.length; n++) {
  var cell = new Buf(10, 10); ICONS[n](cell);
  blit(SHEET, outlined(cell, OUT), n * 12, 0);
}

IMG.putImageData(SHEET.d); SPR.save();
SPR.saveAs(DIR + 'game/assets/ui/weather_glyphs.png');
console.log('weather glyphs done');
