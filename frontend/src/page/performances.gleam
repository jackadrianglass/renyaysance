import layout
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  layout.page("Performance Lineup", [
    html.p([], [html.text("See who is performing and when.")]),
  ])
}
