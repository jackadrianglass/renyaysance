import layout
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  layout.page("Market", [
    html.p([], [html.text("Browse the market stalls and vendor offerings.")]),
  ])
}
