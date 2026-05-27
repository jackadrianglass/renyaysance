import layout
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  layout.page("Potion Quiz", [
    html.p([], [html.text("Identify the correct potion to advance.")]),
  ])
}
