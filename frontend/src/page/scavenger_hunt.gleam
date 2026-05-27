import layout
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  layout.page("Scavenger Hunt", [
    html.p([], [html.text("Find hidden items scattered around the grounds.")]),
  ])
}
