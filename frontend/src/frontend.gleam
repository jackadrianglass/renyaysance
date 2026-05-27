import gleam/uri.{type Uri}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

// ROUTES ----------------------------------------------------------------------

type Route {
  Home
  Login
  Riddles
  ScavengerHunt
  SwordFighting
  MysticArts
  Market
  Performances
  Potluck
  Donations
  PotionQuiz
  Archery
  HobbyHorseRaces
  Jousting
  CostumeVoting
  Tournament
  NotFound
}

fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] | [""] -> Home
    ["login"] -> Login
    ["riddles"] -> Riddles
    ["scavenger-hunt"] -> ScavengerHunt
    ["sword-fighting"] -> SwordFighting
    ["mystic-arts"] -> MysticArts
    ["market"] -> Market
    ["performances"] -> Performances
    ["potluck"] -> Potluck
    ["donations"] -> Donations
    ["potion-quiz"] -> PotionQuiz
    ["archery"] -> Archery
    ["hobby-horse"] -> HobbyHorseRaces
    ["jousting"] -> Jousting
    ["costume-voting"] -> CostumeVoting
    ["tournament"] -> Tournament
    _ -> NotFound
  }
}

fn href(route: Route) -> attribute.Attribute(Msg) {
  let path = case route {
    Home -> "/"
    Login -> "/login"
    Riddles -> "/riddles"
    ScavengerHunt -> "/scavenger-hunt"
    SwordFighting -> "/sword-fighting"
    MysticArts -> "/mystic-arts"
    Market -> "/market"
    Performances -> "/performances"
    Potluck -> "/potluck"
    Donations -> "/donations"
    PotionQuiz -> "/potion-quiz"
    Archery -> "/archery"
    HobbyHorseRaces -> "/hobby-horse"
    Jousting -> "/jousting"
    CostumeVoting -> "/costume-voting"
    Tournament -> "/tournament"
    NotFound -> "/404"
  }
  attribute.href(path)
}

// MODEL -----------------------------------------------------------------------

type Model {
  Model(route: Route)
}

fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let route = case modem.initial_uri() {
    Ok(uri) -> parse_route(uri)
    Error(_) -> Home
  }
  #(Model(route:), modem.init(fn(uri) { OnRouteChange(parse_route(uri)) }))
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  OnRouteChange(Route)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    OnRouteChange(route) -> #(Model(route:), effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  case model.route {
    Home -> view_home()
    Login -> view_login()
    Riddles -> view_riddles()
    ScavengerHunt -> view_scavenger_hunt()
    SwordFighting -> view_sword_fighting()
    MysticArts -> view_mystic_arts()
    Market -> view_market()
    Performances -> view_performances()
    Potluck -> view_potluck()
    Donations -> view_donations()
    PotionQuiz -> view_potion_quiz()
    Archery -> view_archery()
    HobbyHorseRaces -> view_hobby_horse_races()
    Jousting -> view_jousting()
    CostumeVoting -> view_costume_voting()
    Tournament -> view_tournament()
    NotFound -> view_not_found()
  }
}

fn nav_link(route: Route, label: String) -> Element(Msg) {
  html.a([href(route)], [html.text(label)])
}

fn page(title: String, body: List(Element(Msg))) -> Element(Msg) {
  html.div([], [
    html.nav([], [nav_link(Home, "Home")]),
    html.h1([], [html.text(title)]),
    ..body
  ])
}

// HOME -----------------------------------------------------------------------

fn view_home() -> Element(Msg) {
  html.div([], [
    html.h1([], [html.text("Rennyaysance")]),
    html.p([], [html.text("Welcome to the party. Choose your path.")]),
    html.h2([], [html.text("Side Quests")]),
    html.ul([], [
      html.li([], [nav_link(Riddles, "Riddles")]),
      html.li([], [nav_link(ScavengerHunt, "Scavenger Hunt")]),
      html.li([], [nav_link(SwordFighting, "Sword Fighting")]),
      html.li([], [nav_link(MysticArts, "Mystic Arts")]),
    ]),
    html.h2([], [html.text("Events")]),
    html.ul([], [
      html.li([], [nav_link(Market, "Market")]),
      html.li([], [nav_link(Performances, "Performance Lineup")]),
      html.li([], [nav_link(Potluck, "Potluck")]),
      html.li([], [nav_link(Donations, "Donations & Charity")]),
    ]),
    html.h2([], [html.text("Main Quests")]),
    html.ul([], [
      html.li([], [nav_link(PotionQuiz, "Potion Quiz")]),
      html.li([], [nav_link(Archery, "Archery")]),
      html.li([], [nav_link(HobbyHorseRaces, "Hobby Horse Races")]),
      html.li([], [nav_link(Jousting, "King's Court Jousting")]),
    ]),
    html.h2([], [html.text("Other")]),
    html.ul([], [
      html.li([], [nav_link(CostumeVoting, "Costume Voting")]),
      html.li([], [nav_link(Tournament, "Tournament Leaderboard")]),
      html.li([], [nav_link(Login, "Login")]),
    ]),
  ])
}

// PAGES -----------------------------------------------------------------------

fn view_login() -> Element(Msg) {
  page("Login", [
    html.p([], [html.text("Sign in to track your progress and vote.")]),
  ])
}

fn view_riddles() -> Element(Msg) {
  page("Riddles", [
    html.p([], [html.text("Solve riddles to earn side quest points.")]),
  ])
}

fn view_scavenger_hunt() -> Element(Msg) {
  page("Scavenger Hunt", [
    html.p([], [html.text("Find hidden items scattered around the grounds.")]),
  ])
}

fn view_sword_fighting() -> Element(Msg) {
  page("Sword Fighting", [
    html.p([], [html.text("Test your mettle in honorable combat.")]),
  ])
}

fn view_mystic_arts() -> Element(Msg) {
  page("Mystic Arts", [
    html.p([], [html.text("Demonstrate your command of the arcane.")]),
  ])
}

fn view_market() -> Element(Msg) {
  page("Market", [
    html.p([], [html.text("Browse the market stalls and vendor offerings.")]),
  ])
}

fn view_performances() -> Element(Msg) {
  page("Performance Lineup", [
    html.p([], [html.text("See who is performing and when.")]),
  ])
}

fn view_potluck() -> Element(Msg) {
  page("Potluck", [
    html.p([], [html.text("The communal feast — see what's on the table.")]),
  ])
}

fn view_donations() -> Element(Msg) {
  page("Donations & Charity", [
    html.p([], [html.text("Contribute to the cause. Cash and e-transfer accepted.")]),
  ])
}

fn view_potion_quiz() -> Element(Msg) {
  page("Potion Quiz", [
    html.p([], [html.text("Identify the correct potion to advance.")]),
  ])
}

fn view_archery() -> Element(Msg) {
  page("Archery", [
    html.p([], [html.text("Loose your arrows and claim your score.")]),
  ])
}

fn view_hobby_horse_races() -> Element(Msg) {
  page("Hobby Horse Races", [
    html.p([], [html.text("Mount up. The track awaits.")]),
  ])
}

fn view_jousting() -> Element(Msg) {
  page("King's Court Jousting", [
    html.p([], [
      html.text(
        "Single-elimination bracket tournament. Winners advance to the final.",
      ),
    ]),
  ])
}

fn view_costume_voting() -> Element(Msg) {
  page("Costume Voting", [
    html.p([], [html.text("Vote for the best costume of the day.")]),
  ])
}

fn view_tournament() -> Element(Msg) {
  page("Tournament Leaderboard", [
    html.p([], [
      html.text(
        "Points accumulated across all events. Top competitors advance to the final tournament.",
      ),
    ]),
  ])
}

fn view_not_found() -> Element(Msg) {
  page("404", [
    html.p([], [html.text("This path leads nowhere.")]),
  ])
}
