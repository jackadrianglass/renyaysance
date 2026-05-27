import layout
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  layout.page("Mystic Arts", [
    html.p([], [html.text("Demonstrate your command of the arcane.")]),
  ])
}
