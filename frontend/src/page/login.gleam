import gleam/option.{type Option}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn view(
  name: String,
  password: String,
  error: Option(String),
  loading: Bool,
  on_name_input: fn(String) -> msg,
  on_password_input: fn(String) -> msg,
  on_submit: msg,
) -> Element(msg) {
  html.div([], [
    html.h1([], [html.text("Rennyaysance")]),
    html.p([], [html.text("Enter your name and the party password to join.")]),
    html.form([event.on_submit(fn(_) { on_submit })], [
      html.div([], [
        html.label([], [html.text("Name")]),
        html.input([
          attribute.type_("text"),
          attribute.value(name),
          attribute.placeholder("Your name"),
          event.on_input(on_name_input),
        ]),
      ]),
      html.div([], [
        html.label([], [html.text("Password")]),
        html.input([
          attribute.type_("password"),
          attribute.value(password),
          event.on_input(on_password_input),
        ]),
      ]),
      html.button(
        [attribute.type_("submit"), attribute.disabled(loading)],
        [
          html.text(case loading {
            True -> "Signing in..."
            False -> "Sign in"
          }),
        ],
      ),
    ]),
    case error {
      option.None -> element.none()
      option.Some(e) -> html.p([], [html.text(e)])
    },
  ])
}
