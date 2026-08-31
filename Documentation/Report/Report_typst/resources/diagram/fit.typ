// Scales a fixed-size diagram (native width/height in cm) down to fit the
// available width of its container, preserving aspect ratio. Needed because
// the diagrams in this folder are drawn with absolute `place()` coordinates
// sized for A4 posters (21cm wide), wider than the thesis text column.
#let fit(w, h, body) = layout(size => {
  let ratio = size.width / w
  scale(x: ratio * 100%, y: ratio * 100%, origin: top + left, reflow: true, box(width: w, height: h, body))
})
