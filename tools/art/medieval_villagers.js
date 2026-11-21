// @open tools/art/dist/medieval_villagers_canvas.png
// @canvas 308x30
// Same poses and faces as the Classical sheets; only the clothes change.
var OUTDIR = DIR + 'game/assets/world/medieval/villagers/';
var IMG = SPR.layer(0).cel(0).image;
var LOOKS = {
  mira: { pal: PAL.hoodMira, stone: true, hair: 'bun' },
  theo: { pal: PAL.hoodTheo, stone: true, hair: 'tuft' },
  wren: { pal: PAL.hoodWren, stone: true, hair: 'long', role: 'gatherer' }
};
var OUTFITS = ['hood', 'guild'];
var FRAMES = [
  { pose: 'idle' }, { pose: 'walk', f: 0 }, { pose: 'walk', f: 1 }, { pose: 'walk', f: 2 },
  { pose: 'walk', f: 3 }, { pose: 'chop', f: 0 }, { pose: 'chop', f: 1 }, { pose: 'chop', f: 2 },
  { pose: 'hammer', f: 0 }, { pose: 'hammer', f: 1 }, { pose: 'spear' }
];
seed = 3;
for (var n = 0; n < OUTFITS.length; n++) {
  for (var who in LOOKS) {
    var sheet = new Buf(308, 30);
    for (var i = 0; i < FRAMES.length; i++) {
      var o = { outfit: OUTFITS[n] }, k;
      for (k in LOOKS[who]) o[k] = LOOKS[who][k];
      for (k in FRAMES[i]) o[k] = FRAMES[i][k];
      var body = new Buf(27, 27); vil(o)(body);
      sheet.ell(i * 28 + 14, 28, 5, 1.3, '#5f8236');
      blit(sheet, outlined(body, OUT), i * 28, 0);
    }
    IMG.putImageData(sheet.d);
    SPR.saveAs(OUTDIR + OUTFITS[n] + '/' + who + '.png');
  }
}
