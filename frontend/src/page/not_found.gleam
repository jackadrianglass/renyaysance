import layout
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  layout.page("404", [
    html.p([], [html.text("This path leads nowhere.")]),
  ])
}
