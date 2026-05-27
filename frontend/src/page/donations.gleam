import layout
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  layout.page("Donations & Charity", [
    html.p([], [html.text("Contribute to the cause. Cash and e-transfer accepted.")]),
  ])
}
