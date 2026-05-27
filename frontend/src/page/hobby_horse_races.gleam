import layout
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  layout.page("Hobby Horse Races", [
    html.p([], [html.text("Mount up. The track awaits.")]),
  ])
}
