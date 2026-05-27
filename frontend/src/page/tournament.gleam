import layout
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  layout.page("Tournament Leaderboard", [
    html.p([], [
      html.text(
        "Points accumulated across all events. Top competitors advance to the final tournament.",
      ),
    ]),
  ])
}
