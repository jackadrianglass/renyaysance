import layout
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  layout.page("Archery", [
    html.p([], [html.text("Loose your arrows and claim your score.")]),
  ])
}
