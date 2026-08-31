// Generates the probe architecture diagram used in the thesis report.
#let color-white = rgb("#ffffff")
#let color-black = rgb("#000000")
#let color-accent-1 = rgb("#031a38")
#let color-accent-2 = rgb("#043067")
#let color-accent-3 = rgb("#0f63bf")
#let color-accent-4 = rgb("#2e9bff")
#let color-mqtt = rgb("#1fb960")

#let legend(entries) = {
  for (i, entry) in entries.enumerate() {
    let (color, dashed, txt) = entry
    place(
      bottom + left,
      dx: 4cm,
      dy: 0.05cm + i * 0.35cm,
      text(size: 6pt, txt),
    )
    place(
      bottom + left,
      dx: 2cm,
      dy: 0cm + i * 0.35cm,
      line(
        start: (0cm, 0cm),
        end: (1.75cm, 0cm),
        stroke: (
          paint: color,
          thickness: 2.2pt,
          cap: "round",
          dash: if dashed { "dashed" } else { none },
        ),
      ),
    )
  }
}

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

#let elbow(p1, p2, color, label: none, dashed: false, bend: 0.5, both: false, bend-y: none, label-w: 5cm) = {
  let (x1, y1) = p1
  let (x2, y2) = p2
  let ymid = if bend-y != none { bend-y } else { y1 + (y2 - y1) * bend }
  let raw = ((x1, y1), (x1, ymid), (x2, ymid), (x2, y2))
  let pts = (raw.first(),)
  for p in raw.slice(1) {
    if p != pts.last() { pts.push(p) }
  }
  path(pts, color, dashed: dashed, arrow-start: both)
  if label != none { tag((x1 + x2) / 2, ymid - 0.3cm, label, color: color-accent-1, w: label-w) }
}

#let vlink(x, y1, y2, color, label: none, dashed: false, both: false, label-dx: 0.2cm) = {
  path(((x, y1), (x, y2)), color, dashed: dashed, arrow-start: both)
  if label != none {
    place(dx: x + label-dx, dy: (y1 + y2) / 2 - 0.55cm, box(
      inset: (x: 4pt, y: 2pt),
      radius: 0.06cm,
      text(size: 6.3pt, fill: color-accent-1, weight: "medium", label),
    ))
  }
}

// Generates the probe architecture diagram.
#let probe-architecture-size = (w: 21cm, h: 13.7cm)
#let probe-architecture(w: 21cm, h: 13.1cm) = box(width: w, height: h, {
  set text(font: "Libertinus Serif", fill: color-black)

  let R0 = 1cm
  let R1 = 4cm
  let R2 = 8cm
  let R3 = 8.3cm
  let R4 = 12cm

  let BROKER_X = 4.5cm
  let INTERFACE_X = 16.5cm

  let MQTTCLIENT_X = 4.5cm
  let MODELS_X = 10.5cm
  let NETWORK_X = 16.5cm

  let PROBE_X = 10.5cm

  let COMMANDHANDLER_X = 6cm
  let CONTROLHANDLER_X = 10.5cm
  let DISCOVERHANDLER_X = 15cm
  
  let SERVICES_x = 4.1cm
  let STATUS_X = 8.4cm
  let CAPABILITIES_X = 12.7cm
  let CONFIG_X = 17cm

  node(BROKER_X, R0, "MQTT BROKER", subtitle: "", w: 4cm, color: color-accent-4)
  node(INTERFACE_X, R0, "INTERFACES", subtitle: "", w: 4cm, color: color-accent-4)

  node(MQTTCLIENT_X, R1, "mqttclient", subtitle: "", w: 5cm, color: color-accent-1)
  node(NETWORK_X, R1, "network", subtitle: "", w: 5cm, color: color-accent-1)
  node(MODELS_X, R1, "models", subtitle: "", w: 5cm, color: color-accent-1)

  node(PROBE_X, R2, "probe.probe", subtitle: "\n\n\n\n", w: 14cm, h: 2.5cm, color: color-accent-2)

  node(COMMANDHANDLER_X, R3, "Probe.HandleCommand", subtitle: "", w: 4cm, color: color-accent-3)
  node(CONTROLHANDLER_X, R3, "Probe.HandleControl", subtitle: "", w: 4cm, color: color-accent-3)
  node(DISCOVERHANDLER_X, R3, "Probe.HandleDiscover", subtitle: "", w: 4cm, color: color-accent-3)

  node(SERVICES_x, R4, "probe.services", subtitle: "", w: 4cm, color: color-accent-2)
  node(STATUS_X, R4, "probe.status", subtitle: "", w: 4cm, color: color-accent-2)
  node(CAPABILITIES_X, R4, "probe.capabilities", subtitle: "", w: 4cm, color: color-accent-2)
  node(CONFIG_X, R4, "probe.config", subtitle: "", w: 4cm, color: color-accent-2)

  // Connection broker -> mqttclient
  vlink(BROKER_X, R0 + 0.51cm, R1 - 0.51cm, color-mqtt, both: true)

  // Connection Interfaces -> network
  vlink(NETWORK_X, R0 + 0.51cm, R1 - 0.51cm, color-black)

  // Connection mqttclient -> probe
  elbow(
    (MQTTCLIENT_X, R1 + 0.51cm),
    (PROBE_X - 2.5cm, R2 - 1.28cm),
    color-mqtt,
    label: "Publish / Subscribe / MQTTEvents",
    both: true,
    label-w: 6cm,
  )

  // Connection models -> probe
  vlink(MODELS_X, R1 + 0.51cm, R2 - 1.28cm, color-black)

  // Connection models -> mqttclient
  elbow(
    (MODELS_X - 2.53cm, R1),
    (MQTTCLIENT_X + 2.53cm, R1),
    color-black,
    label: "",
    label-w: 6cm,
  )

  // Connection network -> probe
  elbow(
    (NETWORK_X, R1 + 0.51cm),
    (PROBE_X + 2.5cm, R2 - 1.28cm),
    color-black,
    label: "",
    label-w: 6cm,
  )

  // Connection probe -> services
  elbow(
    (PROBE_X - 3cm, R2 + 1.28cm),
    (SERVICES_x, R4 - 0.51cm),
    color-black,
    label: "",
    label-w: 6cm,
  )

  // Connection probe -> status
  elbow(
    (PROBE_X - 0.5cm, R2 + 1.28cm),
    (STATUS_X, R4 - 0.51cm),
    color-black,
    label: "",
    label-w: 6cm,
  )

  // Connection probe -> capabilities
  elbow(
    (PROBE_X + 0.5cm, R2 + 1.28cm),
    (CAPABILITIES_X, R4 - 0.51cm),
    color-black,
    label: "",
    label-w: 6cm,
  )

  // Connection probe -> config
  elbow(
    (PROBE_X + 3cm, R2 + 1.28cm),
    (CONFIG_X, R4 - 0.51cm),
    color-black,
    label: "",
    label-w: 6cm,
  )

  legend((
    (color-black, false, "In process Go call"),
    (color-mqtt, false, "MQTT (pub/sub)"),
  ))
})
