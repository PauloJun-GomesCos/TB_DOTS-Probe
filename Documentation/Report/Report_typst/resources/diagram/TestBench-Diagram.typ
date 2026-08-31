#import "@preview/cetz:0.5.2"

#let color-white = rgb("#ffffff")
#let color-black = rgb("#000000")
#let color-accent-1 = rgb("#031a38")
#let color-accent-4 = rgb("#2e9bff")
#let color-HOOC = rgb("#1a428e")
#let color-link = rgb("#e63946")
#let color-link-2 = rgb("#f2a41e")
#let color-coord = rgb("#1fb960")
#let color-muted = rgb("#8aa0b8")

#let port-w = 0.44cm
#let port-h = 0.4cm

#let rj45 = {
  let a = 0.08cm
  let b = 0.08cm
  let y1 = 0.25cm
  let y2 = 0.30cm
  polygon(
    fill: color-white,
    (0cm, 0cm),
    (port-w, 0cm),
    (port-w, y1),
    (port-w - a, y1),
    (port-w - a, y2),
    (port-w - b, y2),
    (port-w - b, port-h),
    (b, port-h),
    (b, y2),
    (a, y2),
    (a, y1),
    (0cm, y1),
  )
}

#let dot(x, y, color: color-link) = place(
  dx: x - 0.08cm,
  dy: y - 0.08cm,
  circle(radius: 0.08cm, fill: color),
)

#let link-line(pts, color: color-link, dashed: false) = place(
  curve(
    stroke: stroke(
      paint: color,
      thickness: 2.2pt,
      cap: "round",
      join: "round",
      dash: if dashed { "dashed" } else { none },
    ),
    curve.move(pts.first()),
    ..pts.slice(1).map(p => curve.line(p)),
  ),
)

#let ip(x, y, txt) = place(
  dx: x,
  dy: y,
  box(
    stroke: 0.0pt + color-muted,
    radius: 2.5pt,
    inset: (x: 3.5pt, y: 2.5pt),
    text(size: 6.5pt, weight: "bold", txt),
  ),
)

#let w = 1.5cm
#let h = 2cm

#let ports = (
  (0.32cm, 1cm, 90deg),
  (1.15cm, 0.625cm, -90deg),
  (1.15cm, 1.375cm, -90deg),
)

#let port(p, n) = {
  let (px, py, _) = ports.at(n)
  let lx = px - w / 2
  let ly = py - h / 2
  (
    p.x + lx * calc.cos(p.r) - ly * calc.sin(p.r),
    p.y + lx * calc.sin(p.r) + ly * calc.cos(p.r),
  )
}

#let half(r) = (
  calc.abs(w / 2 * calc.cos(r)) + calc.abs(h / 2 * calc.sin(r)),
  calc.abs(w / 2 * calc.sin(r)) + calc.abs(h / 2 * calc.cos(r)),
)

#let probe(x, y, r, label, label-pos: "top") = {
  place(
    dx: x - w / 2,
    dy: y - h / 2,
    rotate(r, reflow: false, block(width: w, height: h, {
      place(rect(width: w, height: h, fill: color-accent-1, radius: 0.12cm))
      for (px, py, o) in ports {
        place(dx: px - port-w / 2, dy: py - port-h / 2, rotate(o, reflow: false, rj45))
      }
    })),
  )

  let (hw, hh) = half(r)
  let gap = 0.18cm
  let name = text(size: 10pt, weight: "bold", tracking: 0.6pt, label)
  if label-pos == "top" {
    place(dx: x - 2cm, dy: y - hh - gap - 0.2cm, box(width: 4cm, align(center, name)))
  } else if label-pos == "bottom" {
    place(dx: x - 2cm, dy: y + hh + gap, box(width: 4cm, align(center, name)))
  } else if label-pos == "right" {
    place(dx: x + hw + gap, dy: y - 0.22cm, name)
  } else if label-pos == "left" {
    place(dx: x - hw - gap - 3cm, dy: y - 0.22cm, box(width: 3cm, align(right, name)))
  }
}

#let hooc-w = 1.7cm
#let hooc-h = 3.3cm

#let hooc-ports = (
  (0.5cm, 2.2cm, 90deg),
  (1.2cm, 2.2cm, -90deg),
  (0.5cm, 2.85cm, 90deg),
  (1.2cm, 2.85cm, -90deg),
)

#let hooc-port(p, n) = {
  let (px, py, _) = hooc-ports.at(n)
  let lx = px - hooc-w / 2
  let ly = py - hooc-h / 2
  (
    p.x + lx * calc.cos(p.r) - ly * calc.sin(p.r),
    p.y + lx * calc.sin(p.r) + ly * calc.cos(p.r),
  )
}

#let hooc(x, y, r, label) = {
  place(
    dx: x - hooc-w / 2,
    dy: y - hooc-h / 2,
    rotate(r, reflow: false, block(width: hooc-w, height: hooc-h, {
      place(rect(width: hooc-w, height: hooc-h, fill: color-HOOC, radius: 0.2cm))
      place(
        dx: hooc-w / 12,
        dy: hooc-h / 24,
        image("HOOC.svg", width: hooc-w - (hooc-w / 6)),
      )
      for (px, py, o) in hooc-ports {
        place(dx: px - port-w / 2, dy: py - port-h / 2, rotate(o, reflow: false, rj45))
      }
    })),
  )
}

#let manager_w = 1.7cm
#let manager_h = 4.5cm
#let manager-ports = ((0.32cm, 1cm, 90deg),)

#let manager-port(p, n: 0) = {
  let (px, py, _) = manager-ports.at(n)
  let lx = px - manager_w / 2
  let ly = py - h / 2
  (
    p.x + lx * calc.cos(p.r) - ly * calc.sin(p.r),
    p.y + lx * calc.sin(p.r) + ly * calc.cos(p.r),
  )
}

#let manager(x, y, r, label, label-pos: "top") = {
  place(
    dx: x - manager_w / 2,
    dy: y - manager_h / 2,
    rotate(r, reflow: false, block(width: manager_w, height: manager_h, {
      place(rect(width: manager_w, height: manager_h, fill: color-accent-1, radius: 0.25cm))
      for (px, py, o) in manager-ports {
        place(dx: px - port-w / 2, dy: (manager_h) / 2 - 6pt, rotate(o, reflow: false, rj45))
      }
    })),
  )

  let (hw, hh) = half(r)
  let gap = 0.18cm
  let name = text(size: 10pt, weight: "bold", tracking: 0.6pt, label)
  if label-pos == "top" {
    place(dx: x - 2cm, dy: y - hh - gap - 0.26cm, box(width: 4cm, align(center, name)))
  } else if label-pos == "bottom" {
    place(dx: x - 2cm, dy: y + hh + gap, box(width: 4cm, align(center, name)))
  } else if label-pos == "right" {
    place(dx: x + hw + gap, dy: y - 0.22cm, name)
  } else if label-pos == "left" {
    place(dx: x - hw - gap - 3cm, dy: y - 0.22cm, box(width: 3cm, align(right, name)))
  }

  let name = text(size: 8pt, weight: "medium", tracking: 0.0pt, "MANAGER")
  place(dx: x - 2cm, dy: y - 0.6cm, box(
    width: 1.8cm,
    height: 0.5cm,
    align(horizon + center, name),
    fill: color-white,
    radius: 0.1cm,
  ))

  let name = text(size: 8pt, weight: "medium", tracking: 0.0pt, "BROKER")
  place(dx: x + 0.2cm, dy: y - 0.6cm, box(
    width: 1.8cm,
    height: 0.5cm,
    align(horizon + center, name),
    fill: color-white,
    radius: 0.1cm,
  ))

  place(dx: x, dy: y, link-line(((-1.1cm, 0cm), (-1.1cm, 0.5cm), (-0.3cm, 0.5cm)), color: color-accent-4, dashed: true))
  place(dx: x, dy: y, link-line(((1.1cm, 0cm), (1.1cm, 0.5cm), (0.3cm, 0.5cm)), color: color-accent-4, dashed: true))
}

#let cloud-w = 2.6cm
#let cloud-h = 1.6cm

#let cloud(x, y, label: "INTERNET", color: rgb("#007700")) = place(
  dx: x - cloud-w / 2,
  dy: y - cloud-h / 2,
  block(width: cloud-w, height: cloud-h, {
    let f = color.lighten(80%)
    place(dx: 0.3cm, dy: 0.7cm, rect(width: 2cm, height: 0.65cm, fill: f, radius: 0.33cm))
    place(dx: 0.42cm, dy: 0.38cm, circle(radius: 0.42cm, fill: f))
    place(dx: 0.95cm, dy: 0.12cm, circle(radius: 0.55cm, fill: f))
    place(dx: 1.6cm, dy: 0.45cm, circle(radius: 0.4cm, fill: f))
    place(dy: 0.78cm, box(width: cloud-w, align(center, text(
      size: 7pt,
      weight: "bold",
      tracking: 0.4pt,
      fill: color.darken(30%),
      label,
    ))))
  }),
)

#let legend(entries) = {
  for (i, entry) in entries.enumerate() {
    let (color, dashed, txt) = entry
    let colorCount = if type(color) == array { color.len() } else { 1 }
    let colorArray = if type(color) == array { color } else { (color,) }
    place(
      bottom + left,
      dx: 1.95cm,
      dy: -1.0cm + i * 0.35cm,
      text(size: 6pt, txt),
    )
    let w = 1.95cm - 1.1cm
    for (j, c) in colorArray.enumerate() {
      place(
        bottom + left,
        dx: (w / colorCount) * j,
        dy: -1.06cm + i * 0.35cm,
        link-line(((1.1cm, 0cm), (1.1cm + (w / colorCount - 0.15cm), 0cm)), color: c, dashed: dashed),
      )
    }
  }
}

// Generates the test bench diagram.
#let testbench-size = (w: 21cm, h: 12cm)

#let testbench(w: 21cm, h: 12cm) = box(width: w, height: h, {
  set text(font: "Libertinus Serif", fill: color-black)

  legend((
    ((color-coord), false, "Coordination network link"),
    ((color-link-2, color-link), false, "Test network link"),
  ))

  let SEP0 = (x: 4cm, y: 6.83cm, r: 0deg)
  let BRIDGE = (x: 7cm, y: 9.0cm, r: -90deg)
  let LAN = (x: 16cm, y: 6.2cm, r: 180deg)
  let HOOC = (x: 10.6cm, y: 6.0cm, r: 0deg)

  let HOOC2 = (x: 19.2cm, y: 2.5cm, r: 0deg)
  let MANAGER = (x: 7cm, y: 2cm, r: 270deg)

  let SEP0_eth0 = port(SEP0, 0)
  let SEP0_eth2 = port(SEP0, 2)
  let BRIDGE_eth0 = port(BRIDGE, 0)
  let BRIDGE_eth1 = port(BRIDGE, 1)
  let BRIDGE_eth2 = port(BRIDGE, 2)
  let LAN_eth0 = port(LAN, 0)
  let LAN_eth1 = port(LAN, 1)
  let LAN_eth2 = port(LAN, 2)
  let HOOC_eth1 = hooc-port(HOOC, 1)
  let HOOC_eth2 = hooc-port(HOOC, 2)
  let HOOC2_wan = hooc-port(HOOC2, 0)
  let HOOC2_eth1 = hooc-port(HOOC2, 1)
  let HOOC2_eth2 = hooc-port(HOOC2, 2)
  let MANAGER_eth0 = manager-port(MANAGER)

  probe(SEP0.x, SEP0.y, SEP0.r, "SEP0", label-pos: "top")
  probe(BRIDGE.x, BRIDGE.y, BRIDGE.r, "BRIDGE", label-pos: "right")
  probe(LAN.x, LAN.y, LAN.r, "LAN", label-pos: "top")

  hooc(HOOC.x, HOOC.y, HOOC.r, "HOOC")
  hooc(HOOC2.x, HOOC2.y, HOOC2.r, "HOOC2")

  manager(MANAGER.x, MANAGER.y, MANAGER.r, "COORDINATOR", label-pos: "top")

  let HEIGHT_BUS = HOOC2_eth2.at(1)

  link-line((SEP0_eth2, (BRIDGE_eth1.at(0), SEP0_eth2.at(1)), BRIDGE_eth1), color: color-link-2)
  link-line((BRIDGE_eth2, (BRIDGE_eth2.at(0), HOOC_eth2.at(1)), HOOC_eth2), color: color-link-2)
  link-line((BRIDGE_eth2, BRIDGE_eth1), dashed: true, color: color-link-2)
  link-line((HOOC_eth1, LAN_eth1))

  link-line(
    (
      SEP0_eth0,
      (SEP0_eth0.at(0) - 2.5cm, SEP0_eth0.at(1)),
      (SEP0_eth0.at(0) - 2.5cm, HEIGHT_BUS),
      (MANAGER_eth0.at(0), HEIGHT_BUS),
      MANAGER_eth0,
    ),
    color: color-coord,
    dashed: false,
  )

  link-line(
    (
      BRIDGE_eth0,
      (BRIDGE_eth0.at(0), BRIDGE_eth0.at(1) + 1cm),
      (SEP0_eth0.at(0) - 2.5cm, BRIDGE_eth0.at(1) + 1cm),
      (SEP0_eth0.at(0) - 2.5cm, SEP0_eth0.at(1)),
    ),
    color: color-coord,
    dashed: false,
  )

  link-line(
    (
      LAN_eth0,
      (LAN_eth0.at(0) + 1.6cm, LAN_eth0.at(1)),
      (LAN_eth0.at(0) + 1.6cm, HEIGHT_BUS),
      (MANAGER_eth0.at(0), HEIGHT_BUS),
    ),
    color: color-coord,
    dashed: false,
  )
  link-line(
    (
      HOOC2_eth2,
      (MANAGER_eth0.at(0), HEIGHT_BUS),
    ),
    color: color-coord,
    dashed: false,
  )

  link-line((HOOC2_wan, (16cm, HOOC2_wan.at(1))), color: color-accent-4, dashed: true)
  link-line(((16cm, HOOC2_wan.at(1)), (16cm, 2cm)), color: color-accent-4, dashed: true)

  cloud(16cm, 2cm, color: color-accent-4)

  dot(SEP0_eth2.at(0), SEP0_eth2.at(1), color: color-link-2)
  dot(BRIDGE_eth1.at(0), BRIDGE_eth1.at(1), color: color-link-2)
  dot(BRIDGE_eth2.at(0), BRIDGE_eth2.at(1), color: color-link-2)
  dot(HOOC_eth2.at(0), HOOC_eth2.at(1), color: color-link-2)
  dot(HOOC_eth1.at(0), HOOC_eth1.at(1))
  dot(LAN_eth1.at(0), LAN_eth1.at(1))

  dot(SEP0_eth0.at(0), SEP0_eth0.at(1), color: color-coord)
  dot(BRIDGE_eth0.at(0), BRIDGE_eth0.at(1), color: color-coord)
  dot(LAN_eth0.at(0), LAN_eth0.at(1), color: color-coord)

  dot(HOOC2_eth2.at(0), HOOC2_eth2.at(1), color: color-coord)
  dot(MANAGER_eth0.at(0), MANAGER_eth0.at(1), color: color-coord)

  dot(HOOC2_wan.at(0), HOOC2_wan.at(1), color: color-accent-4)

  ip(4.8cm, 4.7cm + 2.15cm, "192.168.3.130")
  ip(7.4cm, 5.3cm + 2.55cm, "192.168.3.10")
  ip(8.1cm, 4.7cm + 2.15cm, "192.168.3.1")
  ip(11.7cm, 4.1cm + 2.05cm, "192.168.2.1")
  ip(13.65cm, 4.1cm + 2.05cm, "192.168.2.198")

  ip(7.1cm, 3cm, "10.0.0.2")
  ip(17.3cm, 3.35cm, "10.0.0.1")
  ip(7.1cm, 9.8cm, "10.0.0.81")
  ip(2.0cm, 6.45cm, "10.0.0.80")
  ip(16.75cm, 5.85cm, "10.0.0.82")

  place(
    top + left,
    dx: HOOC.x - 1.1cm,
    dy: HOOC.y - 1.9cm,
    rect(width: 2.2cm, height: 3.8cm, fill: none, radius: 0.36cm, stroke: (
      paint: color-accent-4,
      thickness: 1pt,
      dash: "dashed",
    )),
  )

  place(
    top + left,
    dx: HOOC.x + 1.5cm + 1cm,
    dy: HOOC.y + 2.5cm,
    text(size: 9pt, weight: "medium", tracking: 0pt, "Device under test (DUT)"),
  )

  place(
    top + left,
    dx: HOOC.x + 1cm,
    dy: HOOC.y + 2.6cm - 0.5cm,
    cetz.canvas(length: 1cm, {
      import cetz.draw: *
      bezier(
        (0, 0.5),
        (1.4, 0),
        (0.5, 0),
        stroke: blue,
        mark: (start: ">", fill: blue),
      )
    }),
  )
})

// Generates the test setup diagram used to test the limits of the capture command.
// The diagram is included in the thesis presentation.
#let SetupTestCapture(w: 21cm, h: 12cm) = box(width: w, height: h, {
  set text(font: "Grift", fill: color-black)

  legend((
    ((color-coord), false, "Coordination network link"),
    ((color-link-2, color-link), false, "Test network link"),
  ))

  let SEP0 = (x: 4cm, y: 6.83cm, r: 0deg)
  let BRIDGE = (x: 7cm, y: 9.0cm, r: -90deg)

  let SEP0_eth0 = port(SEP0, 0)
  let SEP0_eth2 = port(SEP0, 2)
  let BRIDGE_eth0 = port(BRIDGE, 0)
  let BRIDGE_eth1 = port(BRIDGE, 1)
  let BRIDGE_eth2 = port(BRIDGE, 2)

  probe(SEP0.x, SEP0.y, SEP0.r, "SEP0", label-pos: "top")
  probe(BRIDGE.x, BRIDGE.y, BRIDGE.r, "BRIDGE", label-pos: "right")

  link-line(
    (
      SEP0_eth0,
      (SEP0_eth0.at(0) - 2cm, SEP0_eth0.at(1)),
    ),
    color: color-coord,
    dashed: false,
  )

  link-line(
    (
      BRIDGE_eth0,
      (BRIDGE_eth0.at(0), BRIDGE_eth0.at(1) + 1cm),
    ),
    color: color-coord,
    dashed: false,
  )

  link-line(
    (
      BRIDGE_eth2,
      (BRIDGE_eth2.at(0), BRIDGE_eth0.at(1) - 2.2cm),
      (BRIDGE_eth2.at(1) + 1.5cm, BRIDGE_eth0.at(1) - 2.2cm),
    ),
    color: color-link-2,
    dashed: false,
  )

  link-line((SEP0_eth2, (BRIDGE_eth1.at(0), SEP0_eth2.at(1)), BRIDGE_eth1), color: color-link-2)
  link-line((BRIDGE_eth2, BRIDGE_eth1), dashed: true, color: color-link-2)

  dot(SEP0_eth2.at(0), SEP0_eth2.at(1), color: color-link-2)
  dot(BRIDGE_eth1.at(0), BRIDGE_eth1.at(1), color: color-link-2)
  dot(BRIDGE_eth2.at(0), BRIDGE_eth2.at(1), color: color-link-2)

  dot(SEP0_eth0.at(0), SEP0_eth0.at(1), color: color-coord)
  dot(BRIDGE_eth0.at(0), BRIDGE_eth0.at(1), color: color-coord)

  ip(4.8cm, 3.8cm + 3.0cm, "192.168.3.130")
  ip(8cm, 5.3cm + 3.0cm, "192.168.3.10")

  ip(7cm, 9.9cm, "10.0.0.81")
  ip(2.0cm, 6.4cm, "10.0.0.80")
})
