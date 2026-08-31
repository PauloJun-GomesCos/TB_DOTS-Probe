
// - mqtt-discovery-sequence : discovery & presence sequence diagram
// - mqtt-setup-sequence     : configuration (setup) sequence diagram
// - mqtt-command-sequence   : test execution (command), sync + async

#let color-white = rgb("#ffffff")
#let color-black = rgb("#000000")
#let color-accent-1 = rgb("#031a38")
#let color-accent-2 = rgb("#043067")
#let color-muted = rgb("#8aa0b8")

#let color-down = rgb("#0f63bf")
#let color-up = rgb("#1fb960")
#let color-async = rgb("#e6a817")

#let legend(entries) = {
  for (i, entry) in entries.enumerate() {
    let (color, dashed, txt) = entry
    place(
      bottom + left,
      dx: 2.85cm,
      dy: -1.2cm + i * 0.35cm,
      text(size: 6pt, txt),
    )
    place(
      bottom + left,
      dx: 0.9cm,
      dy: -1.26cm + i * 0.35cm,
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

#let actor-box(x, y, title, subtitle: none, color: color-accent-1) = {
  let txt = if subtitle != none {
    text(size: 9.5pt, weight: "bold", tracking: 0.4pt, fill: color-white, title)
    v(-0.3cm)
    text(size: 6.5pt, weight: "regular", tracking: 0.2pt, fill: color-white, subtitle)
  } else {
    text(size: 9.5pt, weight: "bold", tracking: 0.4pt, fill: color-white, title)
  }

  place(
    dx: x - 2.6cm,
    dy: y - 0.37cm,
    box(
      width: 5.2cm,
      height: 0.74cm,
      radius: 0.15cm,
      fill: color,
      align(center + horizon, txt),
    ),
  )
}

#let lifeline(x, y0, y1, color: color-muted) = place(
  dx: x,
  dy: y0,
  line(end: (0cm, y1 - y0), stroke: (paint: color, thickness: 0.8pt, dash: "dashed")),
)

#let arrow-head(x, y, dir, color) = place(
  dx: x,
  dy: y,
  polygon(
    fill: color,
    (0cm, 0cm),
    (-dir * 0.22cm, -0.13cm),
    (-dir * 0.22cm, 0.13cm),
  ),
)

#let hline(x1, x2, y, color, dashed: false) = place(
  dx: calc.min(x1, x2),
  dy: y,
  line(
    end: (calc.abs(x2 - x1), 0cm),
    stroke: (paint: color, thickness: 1.6pt, cap: "round", dash: if dashed { "dashed" } else { none }),
  ),
)

#let msg(x1, x2, y, color, dashed: false, topic: none, note: none) = {
  let dir = if x2 > x1 { 1 } else { -1 }
  hline(x1, x2, y, color, dashed: dashed)
  arrow-head(x2, y, dir, color)
  let lo = calc.min(x1, x2)
  let width = calc.abs(x2 - x1)
  if topic != none {
    place(dx: lo, dy: y - 0.56cm, box(width: width, align(center, raw(topic, block: false))))
  }
  if note != none {
    place(dx: lo, dy: y + 0.14cm, box(width: width, align(center, text(size: 6.3pt, fill: color-muted, note))))
  }
}

#let frame(x1, x2, y0, y1, label, color: color-muted) = {
  place(
    dx: x1,
    dy: y0,
    rect(
      width: x2 - x1,
      height: y1 - y0,
      fill: none,
      stroke: (paint: color, thickness: 0.8pt, dash: "dashed"),
      radius: 0.08cm,
    ),
  )
  place(
    dx: x1,
    dy: y0,
    box(fill: color, inset: (x: 5pt, y: 2.5pt), text(size: 6.5pt, weight: "bold", fill: color-white, label)),
  )
}

#let divider(x1, x2, y, label) = {
  place(dx: x1, dy: y, line(end: (x2 - x1, 0cm), stroke: (paint: color-muted, thickness: 0.6pt, dash: "dashed")))
  place(
    dx: (x1 + x2) / 2 - 2.2cm,
    dy: y - 0.22cm,
    box(width: 4.4cm, fill: color-white, align(center, text(size: 6.3pt, style: "italic", fill: color-muted, label))),
  )
}

#let mqtt-topic-table-size = (w: 21cm, h: 14cm)

#let mqtt-topic-table(w: 21cm, h: 14cm) = box(width: w, height: h, {
  set text(font: "Grift", fill: color-black)

  place(
    dx: 1.3cm,
    dy: 2.1cm,
    box(
      width: 18.4cm,
      text(size: 8pt, fill: color-accent-1)[
        #table(
          columns: (2.9fr, 1.3fr, 3.4fr, 3.6fr),
          stroke: 0.4pt + color-muted,
          inset: 5pt,
          align: (left, center, left, left, left),
          fill: (_, y) => if y == 0 { color-accent-1 } else if calc.rem(y, 2) == 0 { rgb("#f3f8fd") } else {
            color-white
          },
          table.header(
            text(fill: color-white, weight: "bold", size: 7.5pt)[Topic],
            text(fill: color-white, weight: "bold", size: 7.5pt)[Direction],
            text(fill: color-white, weight: "bold", size: 7.5pt)[Payload],
            text(fill: color-white, weight: "bold", size: 7.5pt)[Purpose],
          ),

          raw("probes/discover"), text(size: 7pt)[ProbesManager\ ↓ \ Probes],
          text(size: 7pt)[`DiscoverRequest{id}`],
          text(
            size: 7pt,
          )[Ask every probe to (re)announce itself: sent at startup, on the auto-discovery timer, and from `POST /api/v1/probes/discover`.],

          raw("probes/announce"), text(size: 7pt)[ProbesManager\ ↑\ Probes],
          text(
            size: 7pt,
          )[`ProbeAnnounce{probe_id, type, name, firmware_version, status_interval_s, capabilities[], network, config[], config_groups[]}`],
          text(
            size: 7pt,
          )[Registers/updates identity, capabilities and config schema; also re-sent by the probe right after it applies a `control` setup.],

          raw("probes/{probe_id}/status"), text(size: 7pt)[ProbesManager\ ↑\ Probes],
          text(size: 7pt)[`ProbeStatus{name, state, uptime_seconds, cpu_percent, memory_percent}`],
          text(
            size: 7pt,
          )[Periodic heartbeat, interval set by the probe's own `status_interval_s`; missed heartbeats flag the probe offline.],

          raw("probes/{probe_id}/control"), text(size: 7pt)[ProbesManager\ ↓ \ Probes],
          text(size: 7pt)[`MQTTSetup{id, params}`],
          text(
            size: 7pt,
          )[Pushes a new configuration; `params` is keyed by the probe's own `ConfigSchema` field keys. Triggered by `POST /api/v1/probes/id/{probe_id}/control`.],

          raw("probes/{probe_id}/command"), text(size: 7pt)[TestsManager\ ↓ \ Probes],
          text(size: 7pt)[`MQTTRequest{id, action, params}`],
          text(size: 7pt)[Runs one test-suite command/action on the target probe during a suite run.],

          raw("probes/{probe_id}/response"), text(size: 7pt)[TestsManager\ ↑\ Probes],
          text(size: 7pt)[`MQTTResponse{id, action, status, error, result}`],
          text(
            size: 7pt,
          )[Reply to a `control` or `command` message, correlated by `id`. `status` may be `processing` first (async ack), then a second message carries the final `success` / `error` + `result`.],
        )
      ],
    ),
  )
})

#let mqtt-discovery-sequence-size = (w: 21cm, h: 9cm)

#let mqtt-discovery-sequence(w: 21cm, h: 9cm) = box(width: w, height: h, {
  set text(font: "Libertinus Serif", fill: color-black)

  let PRB_X = 4.2cm
  let MGR_X = 16.5cm
  let TOP = 0.5cm
  let BOT = 7.0cm

  lifeline(MGR_X, TOP + 0.4cm, BOT)
  lifeline(PRB_X, TOP + 0.4cm, BOT)

  actor-box(MGR_X, TOP, "COORDINATOR", color: color-accent-1)
  actor-box(PRB_X, TOP, "PROBE", color: color-accent-2)

  msg(
    MGR_X,
    PRB_X,
    3.5cm,
    color-down,
    topic: "probes/discover",
    note: "MsgDiscoverRequest{id}",
  )

  msg(
    PRB_X,
    MGR_X,
    5.0cm,
    color-up,
    topic: "probes/announce",
    note: "MsgAnnounce: capabilities + config parameters + network info",
  )

  msg(
    PRB_X,
    MGR_X,
    6.5cm,
    color-up,
    dashed: true,
    topic: "probes/{probe_id}/status",
    note: "MsgStatus repeats every status_interval_s",
  )

  legend((
    (color-down, false, "Coordinator -> Probe"),
    (color-up, false, "Probe -> Coordinator"),
    (color-up, true, "Periodic / repeated"),
  ))
})

#let mqtt-setup-sequence-size = (w: 21cm, h: 9cm)

#let mqtt-setup-sequence(w: 21cm, h: 9cm) = box(width: w, height: h, {
  set text(font: "Grift", fill: color-black)

  let PRB_X = 4.2cm
  let MGR_X = 16.5cm
  let TOP2 = 0.5cm
  let BOT2 = 7.0cm

  lifeline(MGR_X, TOP2 + 0.4cm, BOT2)
  lifeline(PRB_X, TOP2 + 0.4cm, BOT2)

  actor-box(MGR_X, TOP2, "COORDINATOR", color: color-accent-1)
  actor-box(PRB_X, TOP2, "PROBE", color: color-accent-2)

  msg(
    MGR_X,
    PRB_X,
    3.5cm,
    color-down,
    topic: "probes/{probe_id}/control",
    note: "MsgConfigurationRequest{id, params}",
  )

  msg(
    PRB_X,
    MGR_X,
    5.0cm,
    color-up,
    topic: "probes/{probe_id}/response",
    note: "MsgResponse{id, status: \"success\"|\"error\", result}",
  )

  msg(
    PRB_X,
    MGR_X,
    6.5cm,
    color-up,
    dashed: true,
    topic: "probes/announce",
    note: "MsgAnnounce with the new configuration values",
  )

  legend((
    (color-down, false, "Coordinator -> Probe"),
    (color-up, false, "Probe -> Coordinator"),
    (color-up, true, "Re-announce after setup"),
  ))
})

#let mqtt-command-sequence-size = (w: 21cm, h: 14cm)

#let mqtt-command-sequence(w: 21cm, h: 14cm) = box(width: w, height: h, {
  set text(font: "Grift", fill: color-black)

  let PRB_X = 4.2cm
  let MGR_X = 16.5cm
  let TOP3 = 0.5cm
  let BOT3 = 12.0cm

  lifeline(MGR_X, TOP3 + 0.4cm, BOT3)
  lifeline(PRB_X, TOP3 + 0.4cm, BOT3)

  actor-box(MGR_X, TOP3, "COORDINATOR", color: color-accent-1)
  actor-box(PRB_X, TOP3, "PROBE", color: color-accent-2)

  msg(
    MGR_X,
    PRB_X,
    3.5cm,
    color-down,
    topic: "probes/{probe_id}/command",
    note: "MsgConfigRequest{id, action, params}",
  )

  frame(2.4cm, 18.3cm, 4.35cm, 11.5cm, "alt", color: color-muted)

  msg(
    PRB_X,
    MGR_X,
    5.4cm,
    color-up,
    topic: "probes/{probe_id}/response",
    note: "MsgResponse{id, status: \"success\"|\"error\", result}",
  )

  place(dx: 2.7cm, dy: 4.75cm, text(size: 7pt, weight: "bold", fill: color-accent-1, "sync"))

  divider(2.4cm, 18.3cm, 6.7cm, "async, e.g. capture")

  msg(
    PRB_X,
    MGR_X,
    7.9cm,
    color-async,
    topic: "probes/{probe_id}/response",
    note: "MsgResponse{id, status: \"processing\", result}",
  )

  lifeline(MGR_X, 8.5cm, 10.1cm, color: color-muted)
  lifeline(PRB_X, 8.5cm, 10.1cm, color: color-muted)
  place(dx: (MGR_X + PRB_X) / 2 - 2cm, dy: 9.1cm, box(width: 4cm, align(center, text(
    size: 6.3pt,
    style: "italic",
    fill: color-muted,
    "probe keeps working...",
  ))))

  msg(
    PRB_X,
    MGR_X,
    10.7cm,
    color-up,
    topic: "probes/{probe_id}/response",
    note: "MsgResponse{id, status: \"success\"|\"error\", result}",
  )

  legend((
    (color-down, false, "Coordinator -> Probe"),
    (color-up, false, "Probe -> Coordinator (result)"),
    (color-async, false, "Probe -> Coordinator (processing)"),
  ))
})
