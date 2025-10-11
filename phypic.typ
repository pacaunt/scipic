#import "@preview/cetz:0.4.2" as cetz: canvas, draw
#import "@preview/pull-eh:0.1.1" as pull-eh: wind
#import "@preview/cetz-plot:0.1.2" as plt
#import "@local/ohmicron:0.0.1": components, to
#import "@preview/fletcher:0.5.8" as flt: diagram, edge, node
#let gen-color(abbrev, color) = (
  str(abbrev): color,
  "l" + str(abbrev): color.transparentize(30%),
  "ll" + str(abbrev): color.transparentize(50%),
  "lll" + str(abbrev): color.transparentize(70%),
  "c" + str(abbrev): color.transparentize(90%),
)

#let palette = (
  r: red,
  g: green,
  b: blue,
  o: orange,
  y: yellow,
  p: fuchsia,
  v: purple,
  e: eastern,
  k: black,
  a: gray,
)

#let pl = {
  palette.pairs().map(((k, v)) => gen-color(k, v)).join()
}

#let shadow = cetz.draw.rect.with(stroke: 0pt, fill: pl.lla)

#let arw(fill: pl.k, flip: false, ..args) = cetz.draw.line(
  stroke: (paint: fill),
  mark: {
    let pos = if flip { "start" } else { "end" }
    (str(pos): "stealth", fill: fill)
  },
  ..args,
)

#let ctext = cetz.draw.content.with(padding: 5pt)

#let ruler(width: 0.2, ..args, symbol: "|") = draw.line(
  mark: (symbol: symbol, width: width),
  ..args,
)

#let dashl = draw.line.with(stroke: (dash: "dashed"))

#let angle = cetz.angle.angle.with(radius: 3em, label-radius: 2em)

#let connect(fill: black, ..args) = cetz.draw.line(
  mark: (symbol: "o", fill: fill, anchor: "center"),
  ..args,
)

#let style-shadow = (stroke: 0pt, fill: pl.lla)

#let pline(..args, name: none) = {
  import draw: *
  group(name: name, {
    let kwargs = args.named()
    let points = args.pos()
    for (i, p) in points.enumerate() {
      anchor("v" + str(i), p)
    }
    line(..args, name: "line")
  })
}

#let tick(pos, on: "y", ..args, length: 0.2) = {
  import draw: *
  let coor = (-length / 2, length / 2)
  if on == "x" {
    coor = coor.map(i => (rel: (0, i), to: pos))
  } else if on == "y" {
    coor = coor.map(i => (rel: (i, 0), to: pos))
  }
  line(..coor, ..args)
}

#let x-tick(pos, val, ..args, name: none, position: "bottom") = {
  let anchor
  if position == "top" {
    position = "end"
    anchor = "south"
  } else if position == "bottom" {
    position = "start"
    anchor = "north"
  }
  draw.group(name: name, {
    tick(on: "x", pos, ..args, name: "t")
    ctext("t." + position, anchor: anchor, val)
  })
}

#let y-tick(pos, val, ..args, name: none, position: "left") = {
  let anchor
  if position == "right" {
    position = "end"
    anchor = "west"
  } else if position == "left" {
    position = "start"
    anchor = "east"
  }
  draw.group(name: name, {
    tick(on: "y", pos, ..args, name: "t")
    ctext("t." + position, anchor: anchor, val)
  })
}


#let hang(fill: black, ..args) = draw.line(mark: (start: "o", fill: fill, anchor: "center"), ..args)

#let pulley(radius: 0.5, ..args) = {
  let kwargs = args.named()
  args = args.pos()
  let exkwargs = (circle: (:), rect: (:))
  draw.group(..kwargs, {
    if "name" in kwargs.keys() {
      exkwargs.insert("circle", (name: "circle"))
      exkwargs.insert("rect", (name: "rect"))
    }
    draw.circle(radius: radius, ..args, ..exkwargs.circle)
    draw.on-layer(1, draw.rect(
      (to: (), rel: (-0.2 * radius, -1.1 * radius)),
      fill: white,
      (rel: (0.4 * radius, 2 * 1.1 * radius)),
      ..exkwargs.rect,
    ))
    draw.on-layer(1, { draw.circle(radius: 0.1, fill: black, ..args) })
  })
}

#let pline(..points, name: none) = {
  import draw: anchor, group, line
  group(name: name, {
    for (i, p) in points.pos().enumerate() {
      anchor("p" + str(i), p)
    }
    line(..points)
  })
}

#let balance(center, name: none, scaling: 1.0, cnt, ..styles) = {
  import draw: *
  styles = styles.named()
  styles = cetz.util.merge-dictionary(
    (
      body: (:),
      circle: (:),
      connect: (:),
      holder: (:),
      anchor: "center",
      all: (),
      content: (:),
    ),
    styles,
  )
  group(name: name, anchor: styles.anchor, {
    for func in styles.all {
      func
    }
    scale(scaling)
    anchor("default", center)
    anchor("start", (rel: (-1, -0.5), to: "default"))
    line(
      "start",
      (rel: (80deg, 1.3)),
      (rel: (1, 0)),
      (rel: (-80deg, 1.3)),
      close: true,
      name: "body",
      ..styles.body,
    )
    circle("body.centroid", radius: 0.4, name: "circle", ..styles.circle)
    line("body", (rel: (0, 1)), name: "connect", ..styles.connect)
    line((to: "connect.end", rel: (-0.8, 0)), (rel: (1.6, 0)), name: "holder", ..styles.holder)
    content("circle.center", cnt, ..styles.content)
  })
}

#let cup(coor, size: (0.9, 1), name: none, ..styles) = {
  import draw: *
  styles = styles.named()
  styles = cetz.util.merge-dictionary(
    (
      container: (:),
      liquid: (:),
      anchor: "south",
      all: (),
    ),
    styles,
  )
  group(name: name, anchor: styles.anchor, {
    let (w, h) = size
    for func in styles.all {
      func
    }
    anchor("default", coor)
    pline(
      (0, 0),
      (rel: (0, -h)),
      (rel: (w, 0)),
      (rel: (0, h)),
      name: "container",
      ..styles.container,
    )
    on-layer(-1, {
      rect(
        "container.p1",
        "container.p3",
        stroke: 0pt,
        fill: pl.llla,
        ..styles.liquid,
        name: "liquid",
      )
    })
  })
}

#let myrect(center, size: (1, 1), name: none, ..styles) = {
  import draw: *
  styles = styles.named()
  styles = cetz.util.merge-dictionary(
    (
      anchor: "south",
      all: (),
    ),
    styles,
  )
  group(name: name, anchor: styles.remove("anchor"), {
    for func in styles.all {
      func
    }
    let (w, h) = size
    anchor("default", center)
    rect((rel: (-w / 2, 0), to: "default"), (rel: (w, h)), name: "rect", ..styles)
  })
}


#let wave-fn(
  f: 1 / 2,
  domain: (0, 6),
  amplitude: 1,
  phase: 0,
) = {
  x => amplitude * calc.sin(2 * calc.pi * f * x + 2 * calc.pi * phase)
}

#let plot-wave(
  f: 1 / 2,
  domain: (0, 6),
  range: (-4, 4),
  axis: (:),
  add: none,
  style: (:),
  size: (3, 3),
  x-label: $x$,
  y-label: $y$,
  phase: 0,
  name: none,
) = {
  import plt.plot
  let (y0, ym) = range
  plot.plot(
    size: size,
    x-tick-step: 1,
    y-tick-step: 2,
    y-max: ym,
    y-min: y0,
    axis-style: "school-book",
    x-label: x-label,
    y-label: y-label,
    name: name,
    ..axis,
    {
      plot.add(
        x => ym * calc.sin(2 * calc.pi * f * (x) + 2 * calc.pi * phase),
        domain: domain,
        line: "spline",
        style: (stroke: 1.5pt),
        ..style,
      )
      add
    },
  )
}

#let shift(x: .5, y: 0, from: ()) = draw.line(from, (rel: (x, y)))

#let face(ang: 0deg, delta: 60deg, radius: 2, ..args) = draw.arc(
  anchor: "arc-center",
  start: ang - delta / 2,
  radius: radius,
  delta: delta,
  ..args,
)

#let lens-converging(
  center,
  name: none,
  width: 0.5,
  height: 2,
  fill: gradient.linear(pl.le, white, pl.le, angle: 30deg),
  stroke: 1pt,
  ..styles,
) = {
  let decoration = (fill: fill, stroke: stroke)
  let alpha = calc.atan2(width, height)
  let theta = 180deg - 2 * alpha
  let radius = height / (2 * calc.sin(theta))
  let delta = 2 * theta
  import draw: *
  group(name: name, ..styles, {
    let face = face.with(radius: radius, delta: delta)
    set-origin(center)
    let faceL = face((0, 0), name: "L")
    let faceR = face("L.center", name: "R", anchor: "west", ang: 180deg)


    merge-path(faceL + faceR, fill: decoration.fill, stroke: decoration.stroke, close: true)

    stroke(none)
    faceL + faceR
  })
}

#let lens-diverging(
  center,
  name: none,
  radius: 2,
  width: 0.5,
  gap: 0.2,
  height: 2,
  delta: 60deg,
  fill: gradient.linear(pl.le, white, pl.le, angle: 30deg),
  stroke: 1pt,
  ..styles,
) = {
  let decoration = (fill: fill, stroke: stroke)
  let dw = (width - gap)
  let alpha = calc.atan2(dw, height)
  let theta = 180deg - 2 * alpha
  let radius = height / (2 * calc.sin(theta))
  let delta = 2 * theta
  import draw: *
  group(name: name, ..styles, {
    let face = face.with(radius: radius, delta: delta)
    set-origin(center)
    let faceL = face((0, 0), name: "L")
    let faceR = face((rel: (gap, 0), to: "L.50%"), name: "R", anchor: "west", ang: 180deg)


    merge-path(faceL + faceR, fill: decoration.fill, stroke: decoration.stroke, close: true)

    stroke(none)
    faceL + faceR
  })
}

#let curved-mirror(
  radius: 2,
  shadow: pl.lla,
  thickness: 0.3,
  delta: 60deg,
  center,
  name: none,
  stroke: auto,
  fill: auto,
  flip: true,
  mode: "convex",
  ..styles,
) = {
  let decoration = (stroke: stroke, fill: fill)
  let face = face.with(radius: radius, decoration: decoration)
  let curved-mirror-styles = (
    concave: (L: (:), R: (anchor: "east")),
    convex: (L: (ang: 180deg), R: (anchor: "west", ang: 180deg)),
  )
  let mirror-styles = curved-mirror-styles.at(mode)
  import draw: *
  group(name: name, ..styles, {
    anchor("default", center)
    get-ctx(ctx => {
      let (ctx, center) = cetz.coordinate.resolve(ctx, center)
      if flip {
        scale(x: -100%, origin: center)
      }
      let faceL = face(center, name: "L", ..mirror-styles.L)
      let faceR = face(
        (rel: (thickness, 0), to: "L.50%"),
        name: "R",
        delta: -delta,
        ..mirror-styles.R,
      )
      merge-path(
        faceL + faceR,
        close: true,
        fill: shadow,
        stroke: none,
      )
      faceL
    })
  })
}

#let light-rays(fill: black, pos: 50%, ..args) = draw.line(
  mark: (pos: pos, end: ">", fill: fill, anchor: "center", shorten-to: none),
  stroke: (paint: fill),
  ..args,
)

#let put(
  pos,
  anchor: "center",
  cnt,
  radius: 2pt,
  fill: black,
  group-anchor: "default",
  padding: 5pt,
  name: none,
) = {
  draw.group(name: name, anchor: group-anchor, {
    draw.circle(radius: radius, fill: fill, pos, name: "circ")
  })
  ctext(pos, cnt, anchor: anchor, padding: padding)
}

#let right-angle = cetz.angle.right-angle.with(label: none, radius: 0.3)


#let fillcup(
  center,
  size: (2, 2),
  name: none,
  fill: pl.llla,
  ratio: 0.75,
  ..styling,
) = {
  let (w, h) = size
  let style = (fill: fill)
  import draw: *
  group(name: name, ..styling, {
    myrect(center, size: (w, h * ratio), fill: style.fill, name: "liq", stroke: none)
    myrect(center, size: (w, h), name: "container", stroke: none)
    pline(
      name: "outline",
      "container.north-west",
      "container.south-west",
      "container.south-east",
      "container.north-east",
    )
  })
}
#let puttick(
  symbol,
  pos: 50%,
  shorten-to: none,
  anchor: "center",
  stroke: 1pt,
  fill: pl.k,
  ..args,
) = (
  mark: (
    end: symbol,
    pos: pos,
    shorten-to: shorten-to,
    fill: fill,
    stroke: stroke,
    anchor: anchor,
    ..args.named(),
  ),
)

#canvas({
  import draw: *
  lens-converging((0, 0), name: "A")
  lens-diverging("A.south", anchor: "north", name: "B")
  curved-mirror("B.south", anchor: "west", name: "C")
  curved-mirror("C.south", anchor: "north")
  light-rays((0, 0), (3, 0))
})

#let simple-plot(
  ..args,
  body,
  origin: (0, 0),
  x-label: $x$,
  y-label: $y$,
  grid-step: 0.5,
  x-ticks: (),
  y-ticks: (),
  dim: (2, 2),
  grid-stroke: pl.lla,
  name: none,
  anchor: "default",
  padding: none,
) = {
  let _anchor = anchor
  import draw: *
  let (x-length, y-length) = dim
  group(name: name, anchor: _anchor, padding: padding, {
    set-origin(origin)
    arw(name: "x", (-.5, 0), (rel: (x-length + 1, 0)))
    arw(name: "y", (0, -.5), (rel: (0, y-length + 1)))
    ctext("x.end", anchor: "west", x-label)
    ctext("y.end", anchor: "south", y-label)
    grid(
      (0, 0),
      dim,
      stroke: grid-stroke,
      step: grid-step,
    )
    let y-ticks = y-ticks.map(y => {
      if type(y) != array {
        y-tick((0, y), $#y$)
      } else {
        let (pos, lab) = y
        y-tick((0, pos), $#lab$)
      }
    })
    let x-ticks = x-ticks.map(x => {
      if type(x) != array {
        x-tick((x, 0), $#x$)
      } else {
        let (pos, lab) = x
        x-tick((pos, 0), $#lab$)
      }
    })
    (x-ticks + y-ticks).sum(default: none)

    body
  })
}

#let mplot(
  data,
  x-step: 1,
  y-step: 1,
  labels: ($x$, $y$),
  size: (4, 3),
  ..args,
) = {
  let (x-label, y-label) = labels
  draw.set-style(axes: (stroke: 2pt))
  plt.plot.plot(
    size: size,
    x-tick-step: x-step,
    y-tick-step: y-step,
    x-label: x-label,
    y-label: y-label,
    axis-style: "school-book",
    stroke: 1pt,
    x-grid: true,
    y-grid: true,
    plot-style: (stroke: 2pt),
    ..args,

    {
      plt.plot.add(((0, 0),))
      data
    },
  )
}

#let mrect(center, size: (1, 1), text: [], ..kwargs) = {
  let (dx, dy) = size
  let start = (to: center, rel: (-dx / 2, -dy / 2))
  let end = (to: center, rel: (dx / 2, dy / 2))
  draw.rect(start, end, ..kwargs)
  draw.content(center, text)
}

#let textarw(start, end, txt, below: [], name: none, ..kwargs) = {
  arw(start, end, ..kwargs, name: name)
  ctext((start, 50%, end), txt, anchor: "south")
  ctext((start, 50%, end), below, anchor: "north")
}

#let mcanvas(it, ..styles) = cetz.canvas(
  {
    draw.stroke((thickness: 2pt))
    it
  },
  ..styles,
)

#let floor(name: none, length: 5, start: (0, 0), angle: 0deg, ..styles) = {
  draw.line(name: name, start, (rel: (angle, length)), ..styles)
}

#let arw-head(center, direction, fill: black, symbol: "stealth", ..styles) = draw.mark(
  center,
  direction,
  symbol: symbol,
  fill: fill,
  ..styles,
)

#let extrude-line(a, b, padding: 20%, ..args) = {
  let start = (a, -padding, b)
  let end = (a, 100% + padding, b)
  draw.line(start, end, ..args)
}

#let incline(perp, length: 4, angle: 30deg, name: none, anchor: "center", padding: 0pt, ..styles) = {
  draw.group(name: name, anchor: anchor, padding: padding, {
    import draw: *
    set-origin(perp)
    let w = length * calc.cos(angle)
    let h = length * calc.sin(angle)
    pline((0, 0), (w, 0), (0, h), close: true, name: "line", ..styles)
    hide({
      line(name: "A", (0, 0), (w, 0))
      line(name: "B", (0, 0), (0, h))
      line(name: "C", (w, 0), (0, h))
    })
  })
}

#let incline-sides(perp, size: (3, 2), name: none, anchor: "center", padding: 0pt, ..styles) = {
  draw.group(name: name, anchor: anchor, padding: padding, {
    import draw: *
    set-origin(perp)
    let (w, h) = size
    pline((0, 0), (w, 0), (0, h), close: true, name: "line", ..styles)
    hide({
      line(name: "A", (0, 0), (w, 0))
      line(name: "B", (0, 0), (0, h))
      line(name: "C", (w, 0), (0, h))
    })
  })
}

#let object(center, ..styles) = draw.circle(radius: .2, fill: pl.la, center, ..styles)