// Generates the dual-environment system diagram used in the thesis report and presentation.
#import "@preview/cetz:0.5.2"

#let color-white = rgb("#ffffff")
#let color-black = rgb("#000000")
#let color-accent-1 = rgb("#031a38")
#let color-accent-4 = rgb("#2e9bff")
#let color-HOOC = rgb("#1a428e")
#let color-link = rgb("#e63946")
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

#let ip(x, y, txt, color: color-muted) = place(
  dx: x,
  dy: y,
  box(
    stroke: 0.0pt + color-muted,
    radius: 2.5pt,
    inset: (x: 3.5pt, y: 2.5pt),
    text(
      size: 6.5pt,
      weight: "bold",
      fill: color,
      txt,
    ),
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

#let legend-x = 2.3cm
#let legend-y = -7.5cm

#let legend(entries) = {
  for (i, entry) in entries.enumerate() {
    let (color, dashed, txt) = entry
    let colorCount = if type(color) == array { color.len() } else { 1 }
    let colorArray = if type(color) == array { color } else { (color,) }
    place(
      bottom + left,
      dx: legend-x + 1.95cm,
      dy: legend-y + i * 0.35cm,
      text(size: 6pt, txt),
    )
    let w = 1.95cm - 1.1cm
    for (j, c) in colorArray.enumerate() {
      place(
        bottom + left,
        dx: legend-x + (w / colorCount) * j,
        dy: legend-y - 0.06cm + i * 0.35cm,
        link-line(((1.1cm, 0cm), (1.1cm + (w / colorCount - 0.15cm), 0cm)), color: c, dashed: dashed),
      )
    }
  }
}

#let DualEnv-system-size = (w: 21cm, h: 17cm)

// Generates the dual-environment system diagram
#let DualEnv-system(w: 21cm, h: 17cm) = block(width: w, height: h, {
  set text(font: "Libertinus Serif", fill: color-black)

  legend((
    ((color-coord), false, "Coordination network link"),
    ((color-link), false, "Test network link"),
  ))

  // Config Environment
  let SEP0 = (x: 5cm, y: 4.5cm, r: 180deg)
  let BRIDGE = (x: 5cm, y: 7.5cm, r: 180deg)
  let MANAGER = (x: 7.43cm, y: 1.4cm, r: 270deg)

  let SEP0_eth0 = port(SEP0, 0)
  let SEP0_eth1 = port(SEP0, 1)
  let SEP0_eth2 = port(SEP0, 2)
  let BRIDGE_eth0 = port(BRIDGE, 0)
  let BRIDGE_eth1 = port(BRIDGE, 1)
  let BRIDGE_eth2 = port(BRIDGE, 2)
  let MANAGER_eth0 = manager-port(MANAGER)

  probe(SEP0.x, SEP0.y, SEP0.r, "Probe 1", label-pos: "top")
  probe(BRIDGE.x, BRIDGE.y, BRIDGE.r, "Probe 2", label-pos: "top")
  manager(MANAGER.x, MANAGER.y, MANAGER.r, "Config Coordinator", label-pos: "top")

  link-line((BRIDGE_eth2, BRIDGE_eth1), dashed: true, color: color-link)

  link-line(
    (
      SEP0_eth1,
      (SEP0_eth1.at(0) - 0.5cm, SEP0_eth1.at(1)),
    ),
    color: color-link,
    dashed: false,
  )

  link-line(
    (
      SEP0_eth2,
      (SEP0_eth2.at(0) - 0.5cm, SEP0_eth2.at(1)),
    ),
    color: color-link,
    dashed: false,
  )

  link-line(
    (
      BRIDGE_eth1,
      (BRIDGE_eth1.at(0) - 0.5cm, BRIDGE_eth1.at(1)),
    ),
    color: color-link,
    dashed: false,
  )

  link-line(
    (
      BRIDGE_eth2,
      (BRIDGE_eth2.at(0) - 0.5cm, BRIDGE_eth2.at(1)),
    ),
    color: color-link,
    dashed: false,
  )

  link-line(
    (
      SEP0_eth0,
      (SEP0_eth0.at(0) + 2cm, SEP0_eth0.at(1)),
      (SEP0_eth0.at(0) + 2cm, 5cm),
      MANAGER_eth0,
    ),
    color: color-coord,
    dashed: false,
  )

  link-line(
    (
      BRIDGE_eth0,
      (BRIDGE_eth0.at(0) + 2cm, BRIDGE_eth0.at(1)),
      (BRIDGE_eth0.at(0) + 2cm, 5cm),
    ),
    color: color-coord,
    dashed: false,
  )

  dot(SEP0_eth1.at(0), SEP0_eth1.at(1), color: color-link)
  dot(SEP0_eth2.at(0), SEP0_eth2.at(1), color: color-link)
  dot(BRIDGE_eth1.at(0), BRIDGE_eth1.at(1), color: color-link)
  dot(BRIDGE_eth2.at(0), BRIDGE_eth2.at(1), color: color-link)

  dot(SEP0_eth0.at(0), SEP0_eth0.at(1), color: color-coord)
  dot(BRIDGE_eth0.at(0), BRIDGE_eth0.at(1), color: color-coord)

  dot(MANAGER_eth0.at(0), MANAGER_eth0.at(1), color: color-coord)

  ip(2.5cm, 3.95cm, "192.168.10.1", color: color-link)
  ip(2.5cm, 4.7cm, "192.168.3.130", color: color-link)
  ip(2.5cm, 7.33cm, "192.168.3.10", color: color-link)

  ip(5.7cm, 2.25cm, "192.168.38.54", color: color-coord)
  ip(5.7cm, 4.15cm, "192.168.38.175", color: color-coord)
  ip(5.7cm, 7.15cm, "192.168.38.176", color: color-coord)

  ip(5.7cm, 4.5cm, "10.0.0.80", color: color-coord)
  ip(5.7cm, 7.5cm, "10.0.0.81", color: color-coord)

  // Seperation line
  link-line(
    (
      (10.5cm, 0.3cm),
      (10.5cm, 10.1cm),
    ),
    color: color-black,
    dashed: true,
  )

  // Test Environment
  let SEP0_2 = (x: 13cm, y: 4.5cm, r: 0deg)
  let BRIDGE_2 = (x: 13cm, y: 7.5cm, r: 0deg)
  let MANAGER_2 = (x: 13.6cm, y:1.4cm, r: 270deg)
  let DUT = (x: 17.5cm, y: 6.7cm, r: 0deg)

  let SEP0_2_eth0 = port(SEP0_2, 0)
  let SEP0_2_eth1 = port(SEP0_2, 1)
  let SEP0_2_eth2 = port(SEP0_2, 2)
  let BRIDGE_2_eth0 = port(BRIDGE_2, 0)
  let BRIDGE_2_eth1 = port(BRIDGE_2, 1)
  let BRIDGE_2_eth2 = port(BRIDGE_2, 2)
  let MANAGER_2_eth0 = manager-port(MANAGER_2)
  let DUT__eth2 = hooc-port(DUT, 2)

  probe(SEP0_2.x, SEP0_2.y, SEP0_2.r, "Probe 1", label-pos: "top")
  probe(BRIDGE_2.x, BRIDGE_2.y, BRIDGE_2.r, "Probe 2", label-pos: "top")
  manager(MANAGER_2.x, MANAGER_2.y, MANAGER_2.r, "Test Coordinator", label-pos: "top")
  hooc(DUT.x, DUT.y, DUT.r, "DUT")
  
  link-line((BRIDGE_2_eth2, BRIDGE_2_eth1), dashed: true, color: color-link)

  link-line(
    (
      SEP0_2_eth2,
      (SEP0_2_eth2.at(0) + 1cm, SEP0_2_eth2.at(1)),
      (SEP0_2_eth2.at(0) + 1cm, 7.1cm),
    ),
    color: color-link,
    dashed: false,
  )

  link-line(
    (
      BRIDGE_2_eth1,
      (BRIDGE_2_eth1.at(0) + 1cm, BRIDGE_2_eth1.at(1)),
    ),
    color: color-link,
    dashed: false,
  )

  link-line(
    (
      BRIDGE_2_eth2,
      DUT__eth2,
    ),
    color: color-link,
    dashed: false,
  )

  link-line(
    (
      SEP0_2_eth0,
      (SEP0_2_eth0.at(0) - 1.5cm, SEP0_2_eth0.at(1)),
      (SEP0_2_eth0.at(0) - 1.5cm, 2.7cm),
      (MANAGER_2_eth0.at(0), 2.7cm),
      MANAGER_2_eth0,
    ),
    color: color-coord,
    dashed: false,
  )

  link-line(
    (
      BRIDGE_2_eth0,
      (BRIDGE_2_eth0.at(0) - 1.5cm, BRIDGE_2_eth0.at(1)),
      (BRIDGE_2_eth0.at(0) - 1.5cm, 3.5cm),
    ),
    color: color-coord,
    dashed: false,
  )

  dot(SEP0_2_eth2.at(0), SEP0_2_eth2.at(1), color: color-link)
  dot(BRIDGE_2_eth1.at(0), BRIDGE_2_eth1.at(1), color: color-link)
  dot(BRIDGE_2_eth2.at(0), BRIDGE_2_eth2.at(1), color: color-link)
  dot(DUT__eth2.at(0), DUT__eth2.at(1), color: color-link)

  dot(SEP0_2_eth0.at(0), SEP0_2_eth0.at(1), color: color-coord)
  dot(BRIDGE_2_eth0.at(0), BRIDGE_2_eth0.at(1), color: color-coord)

  dot(MANAGER_2_eth0.at(0), MANAGER_2_eth0.at(1), color: color-coord)

  ip(13.65cm, 4.5cm, "192.168.3.130", color: color-link)
  ip(13.65cm, 7.33cm, "192.168.3.10", color: color-link)
  ip(15.35cm, 7.55cm, "192.168.3.1", color: color-link)

  ip(12.58cm, 2.25cm, "10.0.0.2", color: color-coord)
  ip(11.2cm, 4.15cm, "10.0.0.80", color: color-coord)
  ip(11.2cm, 7.15cm, "10.0.0.81", color: color-coord)
})