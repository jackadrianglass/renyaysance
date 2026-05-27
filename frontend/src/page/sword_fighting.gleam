import layout
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  layout.page("Sword Fighting", [
    html.p([], [html.text("Test your mettle in honorable combat.")]),
  ])
}
