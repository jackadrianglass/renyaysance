import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import router.{type Route}

pub fn nav_link(route: Route, label: String) -> Element(msg) {
  html.a([router.href(route)], [html.text(label)])
}

pub fn nav_button(route: Route, label: String) -> Element(msg) {
  html.a([router.href(route), attribute.class("nav-button")], [
    html.text(label),
  ])
}

pub fn action_button(
  on_click msg: msg,
  label label: String,
  selected selected: Bool,
) -> Element(msg) {
  html.button(
    [
      event.on_click(msg),
      attribute.class(case selected {
        True -> "nav-button nav-button--selected"
        False -> "nav-button"
      }),
    ],
    [html.text(label)],
  )
}

pub fn page(title: String, body: List(Element(msg))) -> Element(msg) {
  html.div([attribute.class("page")], [
    html.h1([], [html.text(title)]),
    ..body
  ])
}
