import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import local_storage
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import page/archery
import page/costume_voting
import page/donations
import page/hobby_horse_races
import page/home
import page/jousting
import page/login
import page/market
import page/mystic_arts
import page/not_found
import page/performances
import page/potluck
import page/potion_quiz
import page/riddles
import page/scavenger_hunt
import page/sword_fighting
import page/tournament
import router.{type Route}
import rsvp

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

// MODEL -----------------------------------------------------------------------

const user_key = "rennyaysance:user"

type Model {
  Model(
    route: Route,
    user: Option(String),
    login_name: String,
    login_password: String,
    login_error: Option(String),
    login_loading: Bool,
  )
}

fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let route = case modem.initial_uri() {
    Ok(uri) -> router.parse_route(uri)
    Error(_) -> router.Home
  }
  let model =
    Model(
      route:,
      user: local_storage.get(user_key),
      login_name: "",
      login_password: "",
      login_error: option.None,
      login_loading: False,
    )
  #(model, modem.init(fn(uri) { OnRouteChange(router.parse_route(uri)) }))
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  OnRouteChange(Route)
  UserTypedLoginName(String)
  UserTypedLoginPassword(String)
  UserSubmittedLogin
  ServerRespondedToLogin(Result(String, rsvp.Error(String)))
  UserLoggedOut
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    OnRouteChange(route) -> #(Model(..model, route:), effect.none())

    UserTypedLoginName(name) -> #(
      Model(..model, login_name: name),
      effect.none(),
    )

    UserTypedLoginPassword(password) -> #(
      Model(..model, login_password: password),
      effect.none(),
    )

    UserSubmittedLogin ->
      case model.login_name {
        "" -> #(
          Model(..model, login_error: option.Some("Please enter your name.")),
          effect.none(),
        )
        name -> #(
          Model(..model, login_loading: True, login_error: option.None),
          do_login(name, model.login_password),
        )
      }

    ServerRespondedToLogin(Ok(name)) -> {
      local_storage.set(user_key, name)
      #(
        Model(
          ..model,
          user: option.Some(name),
          login_loading: False,
          login_error: option.None,
        ),
        effect.none(),
      )
    }

    ServerRespondedToLogin(Error(_)) -> #(
      Model(
        ..model,
        login_loading: False,
        login_error: option.Some("Wrong password."),
      ),
      effect.none(),
    )

    UserLoggedOut -> {
      local_storage.remove(user_key)
      #(
        Model(..model, user: option.None, login_name: "", login_password: ""),
        effect.none(),
      )
    }
  }
}

fn do_login(name: String, password: String) -> Effect(Msg) {
  let body =
    json.object([
      #("name", json.string(name)),
      #("password", json.string(password)),
    ])
  let decoder = {
    use name <- decode.field("name", decode.string)
    decode.success(name)
  }
  rsvp.post("/api/login", body, rsvp.expect_json(decoder, ServerRespondedToLogin))
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  case model.user {
    option.None ->
      login.view(
        model.login_name,
        model.login_password,
        model.login_error,
        model.login_loading,
        UserTypedLoginName,
        UserTypedLoginPassword,
        UserSubmittedLogin,
      )

    option.Some(_) ->
      html.div([], [
        html.nav([attribute.class("nav")], [
          html.a(
            [router.href(router.Home), attribute.class("nav-brand")],
            [html.text("Rennyaysance")],
          ),
          html.button(
            [event.on_click(UserLoggedOut), attribute.class("nav-logout")],
            [html.text("Logout")],
          ),
        ]),
        view_page(model.route),
      ])
  }
}

fn view_page(route: Route) -> Element(Msg) {
  case route {
    router.Home -> home.view()
    router.Login -> home.view()
    router.Riddles -> riddles.view()
    router.ScavengerHunt -> scavenger_hunt.view()
    router.SwordFighting -> sword_fighting.view()
    router.MysticArts -> mystic_arts.view()
    router.Market -> market.view()
    router.Performances -> performances.view()
    router.Potluck -> potluck.view()
    router.Donations -> donations.view()
    router.PotionQuiz -> potion_quiz.view()
    router.Archery -> archery.view()
    router.HobbyHorseRaces -> hobby_horse_races.view()
    router.Jousting -> jousting.view()
    router.CostumeVoting -> costume_voting.view()
    router.Tournament -> tournament.view()
    router.NotFound -> not_found.view()
  }
}
