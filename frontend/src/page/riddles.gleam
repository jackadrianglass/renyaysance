import layout
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  layout.page("Riddles", [
    html.p([], [html.text("Solve riddles to earn side quest points.")]),
  ])
}
