import layout
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  layout.page("King's Court Jousting", [
    html.p([], [
      html.text(
        "Single-elimination bracket tournament. Winners advance to the final.",
      ),
    ]),
  ])
}
