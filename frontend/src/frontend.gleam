import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import gleam/result
import local_storage
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import page/about
import page/archery
import page/axe_throwing
import page/costume_voting
import page/hobby_horse_races
import page/home
import page/jousting
import page/login
import page/mystic_arts
import page/not_found
import page/potion_quiz
import page/riddles
import page/scavenger_hunt
import page/tournament
import plinth/javascript/global
import router.{type Route}
import rsvp

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

// MODEL -----------------------------------------------------------------------

const user_key = "rennyaysance:user"

type AuthState {
  LoggedOut(name: String, password: String, error: Option(String))
  LoggingIn(name: String, password: String)
  LoggedIn(name: String)
}

type Model {
  Model(
    route: Route,
    auth: AuthState,
    viewing_login: Bool,
    leaderboard: List(#(String, Int)),
    potion_quiz: potion_quiz.Model,
    archery: archery.Model,
    axe_throwing: axe_throwing.Model,
    jousting: jousting.Model,
    costume_voting: costume_voting.Model,
    hobby_horse_races: hobby_horse_races.Model,
  )
}

fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let route = case modem.initial_uri() {
    Ok(uri) -> router.parse_route(uri)
    Error(_) -> router.Home
  }
  let auth = case local_storage.get(user_key) {
    option.Some(name) -> LoggedIn(name)
    option.None -> LoggedOut("", "", option.None)
  }
  let #(voting_model, voting_effect) = costume_voting.init()
  let #(jousting_model, jousting_effect) = jousting.init()
  #(
    Model(
      route:,
      auth:,
      viewing_login: False,
      leaderboard: [],
      potion_quiz: potion_quiz.init(),
      archery: archery.init(),
      axe_throwing: axe_throwing.init(),
      jousting: jousting_model,
      costume_voting: voting_model,
      hobby_horse_races: hobby_horse_races.init(),
    ),
    effect.batch([
      modem.init(fn(uri) { OnRouteChange(router.parse_route(uri)) }),
      fetch_leaderboard(),
      effect.map(voting_effect, CostumeVotingMsg),
      effect.map(jousting_effect, JoustingMsg),
    ]),
  )
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  OnRouteChange(Route)
  UserTypedLoginName(String)
  UserTypedLoginPassword(String)
  UserSubmittedLogin
  UserWantsToLogin
  ServerRespondedToLogin(Result(String, rsvp.Error(String)))
  UserLoggedOut
  FetchLeaderboard
  LeaderboardFetched(Result(List(#(String, Int)), rsvp.Error(String)))
  PotionQuizMsg(potion_quiz.Msg)
  ArcheryMsg(archery.Msg)
  AxeThrowingMsg(axe_throwing.Msg)
  JoustingMsg(jousting.Msg)
  CostumeVotingMsg(costume_voting.Msg)
  HobbyHorseRacesMsg(hobby_horse_races.Msg)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    OnRouteChange(route) -> #(
      Model(..model, route:, viewing_login: False),
      effect.none(),
    )

    UserWantsToLogin -> #(Model(..model, viewing_login: True), effect.none())

    UserTypedLoginName(name) ->
      case model.auth {
        LoggedOut(_, password, error) -> #(
          Model(..model, auth: LoggedOut(name, password, error)),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    UserTypedLoginPassword(password) ->
      case model.auth {
        LoggedOut(name, _, error) -> #(
          Model(..model, auth: LoggedOut(name, password, error)),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    UserSubmittedLogin ->
      case model.auth {
        LoggedOut("", password, _) -> #(
          Model(
            ..model,
            auth: LoggedOut(
              "",
              password,
              option.Some("Please enter your name."),
            ),
          ),
          effect.none(),
        )
        LoggedOut(name, password, _) -> #(
          Model(..model, auth: LoggingIn(name, password)),
          do_login(name, password),
        )
        _ -> #(model, effect.none())
      }

    ServerRespondedToLogin(Ok(name)) -> {
      local_storage.set(user_key, name)
      #(Model(..model, auth: LoggedIn(name)), effect.none())
    }

    ServerRespondedToLogin(Error(_)) ->
      case model.auth {
        LoggingIn(name, password) -> #(
          Model(
            ..model,
            auth: LoggedOut(name, password, option.Some("Wrong password.")),
          ),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }

    UserLoggedOut -> {
      local_storage.remove(user_key)
      #(
        Model(..model, auth: LoggedOut("", "", option.None), viewing_login: False),
        effect.none(),
      )
    }

    FetchLeaderboard -> #(model, fetch_leaderboard())

    LeaderboardFetched(result) -> {
      let leaderboard = result |> result.unwrap(model.leaderboard)
      #(Model(..model, leaderboard:), schedule_leaderboard_poll())
    }

    PotionQuizMsg(sub_msg) -> {
      let handle = get_handle(model.auth)
      let #(sub_model, sub_effect) =
        potion_quiz.update(model.potion_quiz, sub_msg, handle)
      #(
        Model(..model, potion_quiz: sub_model),
        effect.map(sub_effect, PotionQuizMsg),
      )
    }

    ArcheryMsg(sub_msg) -> {
      let handle = get_handle(model.auth)
      let #(sub_model, sub_effect) =
        archery.update(model.archery, sub_msg, handle)
      #(
        Model(..model, archery: sub_model),
        effect.map(sub_effect, ArcheryMsg),
      )
    }

    AxeThrowingMsg(sub_msg) -> {
      let handle = get_handle(model.auth)
      let #(sub_model, sub_effect) =
        axe_throwing.update(model.axe_throwing, sub_msg, handle)
      #(
        Model(..model, axe_throwing: sub_model),
        effect.map(sub_effect, AxeThrowingMsg),
      )
    }

    JoustingMsg(sub_msg) -> {
      let handle = get_handle(model.auth)
      let #(sub_model, sub_effect) =
        jousting.update(model.jousting, sub_msg, handle)
      #(
        Model(..model, jousting: sub_model),
        effect.map(sub_effect, JoustingMsg),
      )
    }

    CostumeVotingMsg(sub_msg) -> {
      let handle = get_handle(model.auth)
      let #(sub_model, sub_effect) =
        costume_voting.update(model.costume_voting, sub_msg, handle)
      #(
        Model(..model, costume_voting: sub_model),
        effect.map(sub_effect, CostumeVotingMsg),
      )
    }

    HobbyHorseRacesMsg(sub_msg) -> {
      let handle = get_handle(model.auth)
      let #(sub_model, sub_effect) =
        hobby_horse_races.update(model.hobby_horse_races, sub_msg, handle)
      #(
        Model(..model, hobby_horse_races: sub_model),
        effect.map(sub_effect, HobbyHorseRacesMsg),
      )
    }

  }
}

fn get_handle(auth: AuthState) -> String {
  case auth {
    LoggedIn(name) -> name
    _ -> ""
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

fn fetch_leaderboard() -> Effect(Msg) {
  let decoder =
    decode.list({
      use handle <- decode.field("handle", decode.string)
      use points <- decode.field("points", decode.int)
      decode.success(#(handle, points))
    })
  rsvp.get("/api/leaderboard", rsvp.expect_json(decoder, LeaderboardFetched))
}

fn schedule_leaderboard_poll() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let _ = global.set_timeout(5000, fn() { dispatch(FetchLeaderboard) })
    Nil
  })
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  case model.auth {
    LoggedIn(_) ->
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
        view_page(model),
      ])

    _ ->
      case model.viewing_login, model.route {
        False, router.Home | False, router.About ->
          html.div([], [
            html.nav([attribute.class("nav")], [
              html.a(
                [router.href(router.Home), attribute.class("nav-brand")],
                [html.text("Rennyaysance")],
              ),
              html.button(
                [event.on_click(UserWantsToLogin), attribute.class("nav-login")],
                [html.text("Login")],
              ),
            ]),
            about.view(),
          ])

        _, _ ->
          case model.auth {
            LoggedOut(name, password, error) ->
              login.view(
                name,
                password,
                error,
                False,
                UserTypedLoginName,
                UserTypedLoginPassword,
                UserSubmittedLogin,
              )
            LoggingIn(name, password) ->
              login.view(
                name,
                password,
                option.None,
                True,
                UserTypedLoginName,
                UserTypedLoginPassword,
                UserSubmittedLogin,
              )
            LoggedIn(_) -> view_page(model)
          }
      }
  }
}

fn view_page(model: Model) -> Element(Msg) {
  case model.route {
    router.Home -> home.view(model.leaderboard)
    router.About -> about.view()
    router.PotionQuiz ->
      element.map(potion_quiz.view(model.potion_quiz), PotionQuizMsg)
    router.Archery -> element.map(archery.view(model.archery), ArcheryMsg)
    router.AxeThrowing ->
      element.map(axe_throwing.view(model.axe_throwing), AxeThrowingMsg)
    router.Jousting ->
      element.map(
        jousting.view(model.jousting, get_handle(model.auth)),
        JoustingMsg,
      )
    router.Riddles -> riddles.view()
    router.ScavengerHunt -> scavenger_hunt.view()
    router.MysticArts -> mystic_arts.view()
    router.HobbyHorseRaces ->
      element.map(
        hobby_horse_races.view(model.hobby_horse_races),
        HobbyHorseRacesMsg,
      )
    router.CostumeVoting ->
      element.map(
        costume_voting.view(model.costume_voting),
        CostumeVotingMsg,
      )
    router.Tournament -> tournament.view()
    router.NotFound -> not_found.view()
  }
}
