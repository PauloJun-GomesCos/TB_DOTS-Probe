// Generates the state machine diagrams used in the thesis report.
#let color-white = rgb("#ffffff")
#let color-black = rgb("#000000")
#let color-accent-1 = rgb("#031a38")
#let color-accent-2 = rgb("#043067")
#let color-accent-4 = rgb("#2e9bff")

#let node(x, y, title, subtitle: none, w: 5.2cm, h: 0.95cm, color: color-accent-1) = {
  let body = if subtitle != none {
    box(width: w - 0.4cm, align(center, {
      text(size: 9pt, weight: "bold", tracking: 0.3pt, fill: color-white, title)
      linebreak()
      text(size: 6.2pt, weight: "regular", fill: color-white.darken(0%), subtitle)
    }))
  } else {
    text(size: 9pt, weight: "bold", tracking: 0.3pt, fill: color-white, title)
  }
  place(
    dx: x - w / 2,
    dy: y - h / 2,
    box(width: w, height: h, radius: 0.15cm, fill: color, align(center + horizon, body)),
  )
}

#let arrow-head(x, y, dir, color) = place(
  dx: x,
  dy: y,
  polygon(fill: color, (0cm, 0cm), (-dir * 0.22cm, -0.13cm), (-dir * 0.22cm, 0.13cm)),
)

#let arrow-head-v(x, y, dir, color) = place(
  dx: x,
  dy: y,
  polygon(fill: color, (0cm, 0cm), (-0.13cm, -dir * 0.22cm), (0.13cm, -dir * 0.22cm)),
)

#let path(pts, color, dashed: false, arrow-end: true, arrow-start: false, thickness: 1.5pt) = {
  place(curve(
    stroke: (
      paint: color,
      thickness: thickness,
      cap: "round",
      join: "round",
      dash: if dashed { "dashed" } else { none },
    ),
    curve.move(pts.first()),
    ..pts.slice(1).map(p => curve.line(p)),
  ))
  if arrow-end {
    let (x2, y2) = pts.last()
    let (x1, y1) = pts.at(pts.len() - 2)
    if y1 == y2 { arrow-head(x2, y2, if x2 > x1 { 1 } else { -1 }, color) } else {
      arrow-head-v(x2, y2, if y2 > y1 { 1 } else { -1 }, color)
    }
  }
  if arrow-start {
    let (x1, y1) = pts.first()
    let (x2, y2) = pts.at(1)
    if y1 == y2 { arrow-head(x1, y1, if x1 > x2 { 1 } else { -1 }, color) } else {
      arrow-head-v(x1, y1, if y1 > y2 { 1 } else { -1 }, color)
    }
  }
}

#let tag(cx, cy, txt, color: color-accent-1, w: 5cm, size: 6.3pt) = place(
  dx: cx - w / 2,
  dy: cy,
  box(width: w, align(center, box(
    inset: (x: 4pt, y: 2pt),
    radius: 0.06cm,
    text(size: size, fill: color, weight: "medium", txt),
  ))),
)

#let corner(p1, p2, color, label: none, dashed: false, both: false) = {
  let (x1, y1) = p1
  let (x2, y2) = p2

  path(
    ((x1, y1), (x1, y2), (x2, y2)),
    color,
    dashed: dashed,
    arrow-start: both,
  )

  if label != none {
    tag(
      (x1 + x2) / 2,
      y2 - 0.3cm,
      label,
      color: color-accent-1,
      w: calc.abs(x2 - x1),
    )
  }
}

#let custom-path(
  pts,
  color,
  label: none,
  label-x: none,
  label-y: none,
  label-w: 5cm,
  dashed: false,
) = {
  path(pts, color, dashed: dashed)

  if label != none {
    tag(
      label-x,
      label-y,
      label,
      color: color-accent-1,
      w: label-w,
    )
  }
}

// Generates the state machine diagram.
#let state-machine-size = (w: 21cm, h: 5cm)
#let state-machine(w: 21cm, h: 5cm) = box(width: w, height: h, {
  set text(font: "Libertinus Serif", fill: color-black)

  let StateStarting_X = 4.5cm
  let StateRunning_X = 9cm
  let StateConnecting_X = 15.5cm

  let StateStarting_Y = 1cm
  let StateRunning_Y = 4cm
  let StateConnecting_Y = 1.5cm


  node(StateStarting_X, StateStarting_Y, "StateStarting", subtitle: "", w: 4cm, color: color-accent-4)
  node(StateConnecting_X, StateConnecting_Y, "StateConnecting", subtitle: "", w: 4cm, color: color-accent-4)
  node(StateRunning_X, StateRunning_Y, "StateRunning", subtitle: "", w: 4cm, color: color-accent-4)

  corner(
    (StateStarting_X, StateStarting_Y + 0.51cm),
    (StateRunning_X - 2.03cm, StateRunning_Y),
    color-accent-2,
    label: "Initialization done",
    both: false,
  )

  custom-path(
    (
      (StateConnecting_X, StateConnecting_Y - 0.5cm),
      (StateConnecting_X, StateConnecting_Y - 1cm),
      (StateConnecting_X + 3cm, StateConnecting_Y - 1cm),
      (StateConnecting_X + 3cm, StateConnecting_Y),
      (StateConnecting_X + 2.03cm, StateConnecting_Y),
    ),
    color-accent-2,
  )

  tag(
    StateConnecting_X + 1.5cm,
    StateConnecting_Y - 1.3cm,
    "EventMQTTConnectionFailed",
    color: color-accent-2,
    w: 4cm,
  )

  corner(
    (StateConnecting_X, StateConnecting_Y + 0.51cm),
    (StateRunning_X + 2.03cm, StateRunning_Y),
    color-accent-2,
    label: "EventMQTTConnected",
    both: false,
  )

  corner(
    (StateRunning_X, StateRunning_Y - 0.51cm),
    (StateConnecting_X - 2.03cm, StateConnecting_Y),
    color-accent-2,
    label: "EventMQTTDisconnected",
    both: false,
  )
})
