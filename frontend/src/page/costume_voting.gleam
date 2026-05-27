import layout
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  layout.page("Costume Voting", [
    html.p([], [html.text("Vote for the best costume of the day.")]),
  ])
}
