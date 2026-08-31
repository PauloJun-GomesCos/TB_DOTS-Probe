#import "@preview/hei-synd-thesis:0.4.0": *

//-------------------------------------
// Document options
//
#let option = (
  type : sys.inputs.at("type", default:"final"),    // [draft|final]
  lang : sys.inputs.at("lang", default:"en"),       // [en|fr|de]
  template    : "thesis",   // [thesis/midterm]
)
//-------------------------------------
// Optional generate titlepage image
//
/*
#import "@preview/fractusist:0.3.2":*
#let project-logo= dragon-curve(
  12,
  step-size: 1.6,
  stroke: stroke(
    paint: gradient.radial(..color.map.rocket),
    thickness: 0.5pt, join: "round"
  )
)
*/
#let project-logo = image(
  "/resources/img/Probe.webp"
)

//-------------------------------------
// Metadata of the document
//
#let doc= (
  title    : "Probes for DOTS (Distributed OT Test Suite)",
  subtitle : "Development of a test probe for performing distributed functional and security-related tests in OT environments.",
  author: (
    (
      gender      : "masculin",  // ["masculin"|"feminin"|"inclusive"]
      name        : "Paulo Junior Gomes Costa",
      email       : "paulojun.gomescos@hes-so.ch \npaulojuniorgomescosta@gmail.com",
      degree      : "Bachelor",
      affiliation : "HEI-Vs",
      place       : "Sion",
      url         : "https://synd.hevs.io",
      signature   : image("/resources/img/signature.png", width:3cm),
    ),
  ),
  keywords : ("OT", "MQTT", "Distributed probe", "HEI-Vs", "Systems Engineering", "Infotronics"),
  version  : "v0.1.0",
)

// Thesis Data Page
#let thesis-data-page = [
  #image("/resources/thesis-data.pdf", page: 1, width: 100%)
  #pagebreak()
  #image("/resources/thesis-data.pdf", page: 2, width: 100%)
]// [none|content][none|content]
                                                                        
// Summary Page
#let summary-page = (
  logo: project-logo,
  //one sentence with max. 240 characters, with spaces.
  objective: [
    The objective of this work is to develop and implement an embedded probe capable of performing various test operations within OT environments, collecting their results, and communicating them to a central coordinator.
  ],
  //summary max. 1200 characters, with spaces.
  content: [
   Operational Technology (OT) environments require numerous functional and security-related tests to be defined, repeated, and logged whenever a system is modified. Preparing and conducting these tests can be complex, as operations must be performed at different points of the system and their effects observed. This work focuses on the development of configurable probes in the form of embedded systems for distributed OT testing.

   The probe is a configurable and remotely controlled device capable of performing various commands when deployed in an OT environment. It connects to a central coordinator and advertises its capabilities and configurable parameters, allowing it to be adapted to different test environments. The coordinator can then send commands or configuration updates, while the probe executes the requested commands and returns their results. Communication relies on MQTT, while local logging provides traceability of executed operations.

   The solution was validated on a physical test bench composed of three probes and one Device Under Test. A test suite was conducted to evaluate the probe's operation and interporpapility with the DOTS coordinator.
  ],
  address: [HES-SO Valais Wallis • rue de l'Industrie 23 • 1950 Sion \ +41 58 606 85 11 • #link("mailto"+"info@hevs.ch")[info\@hevs.ch] • #link("www.hevs.ch")[www.hevs.ch]]
)

// Display Options for additional pages
#let display = (
  report-info: true,  // [true|false] display report info with declaration of honor
  thesis-data: true,  // [true|false] display thesis data page
  summary: true,      // [true|false] display summary page
)

#let professor = (
  (
    affiliation: "HEI-Vs",
    name: "Prof. Rico Steiner",
    email: "rico.steiner@hevs.ch",
  ),
)
#let expert = (
  (
    affiliation: "HOOC AG",
    name: "Gil Beauge",
    email: "gil.beauge@hooc.ch",
  ),
)
#let school= (
  name: none,
  orientation: none,
  specialisation: none,
)
#if option.lang == "de" {
  school.name = "Hochschule für Ingenieurwissenschaften Wallis, HES-SO"
  school.shortname = "HEI-Vs"
  school.orientation = "Systemtechnik"
  school.specialisation = "Infotronics"
} else if option.lang == "fr" {
  school.name = "Haute École d'Ingénierie du Valais, HES-SO"
  school.shortname = "HEI-Vs"
  school.orientation = "Systèmes industriels"
  school.specialisation = "Infotronics"
} else {
  school.name = "University of Applied Sciences Western Switzerland, HES-SO Valais Wallis"
  school.shortname = "HEI-Vs"
  school.orientation = "Systems Engineering"
  school.specialisation = "Infotronics"
}

#let date = (
  submission: datetime(year: 2026, month: 8, day: 14),
  mid-term-submission: datetime(year: 2026, month: 5, day: 1),
  today: datetime.today(),
)

#let logos = (
  main: project-logo,
  topleft: if option.lang == "fr" or option.lang == "de" {
    image("/resources/img/logos/hei-defr.svg", width: 6cm)
  } else {
    image("/resources/img/logos/hei-en.svg", width: 6cm)
  },
  topright: image("/resources/img/logos/hesso-logo.svg", width: 4cm),
  bottomleft: image("/resources/img/logos/hevs-pictogram.svg", width: 4cm),
  bottomright: image("/resources/img/logos/swiss_universities-valais-excellence-logo.svg", width: 5cm),
  )
)

//-------------------------------------
// Settings
//
#let tableof = (
  toc: true,
  tof: true,
  tot: true,
  tol: false,
  toe: false,
  maxdepth: 3,
)

#let gloss    = true
#let appendix = true
#let bib = (
  display : true,
  path  : "/tail/bibliography.bib",
  style : "ieee", //"apa", "chicago-author-date", "chicago-notes", "mla"
)

#let fonts = (
  text: "Libertinus Serif",
  mono: "DejaVu Sans Mono",
  math: "New Computer Modern Math",
)