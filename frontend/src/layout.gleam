import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import router.{type Route}

pub fn nav_link(route: Route, label: String) -> Element(msg) {
  html.a([router.href(route)], [html.text(label)])
}

pub fn page(title: String, body: List(Element(msg))) -> Element(msg) {
  html.div([attribute.class("page")], [
    html.h1([], [html.text(title)]),
    ..body
  ])
}
