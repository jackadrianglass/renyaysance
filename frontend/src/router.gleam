import gleam/uri.{type Uri}

import lustre/attribute.{type Attribute}

pub type Route {
  Home
  About
  ScavengerHunt
  MysticArts
  PotionQuiz
  Archery
  AxeThrowing
  HobbyHorseRaces
  Jousting
  CostumeVoting
  Tournament
  NotFound
}

pub fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] | [""] -> Home
    ["about"] -> About
    ["scavenger-hunt"] -> ScavengerHunt
    ["mystic-arts"] -> MysticArts
    ["potion-quiz"] -> PotionQuiz
    ["archery"] -> Archery
    ["axe-throwing"] -> AxeThrowing
    ["hobby-horse"] -> HobbyHorseRaces
    ["jousting"] -> Jousting
    ["costume-voting"] -> CostumeVoting
    ["tournament"] -> Tournament
    _ -> NotFound
  }
}

pub fn href(route: Route) -> Attribute(msg) {
  let path = case route {
    Home -> "/"
    About -> "/about"
    ScavengerHunt -> "/scavenger-hunt"
    MysticArts -> "/mystic-arts"
    PotionQuiz -> "/potion-quiz"
    Archery -> "/archery"
    AxeThrowing -> "/axe-throwing"
    HobbyHorseRaces -> "/hobby-horse"
    Jousting -> "/jousting"
    CostumeVoting -> "/costume-voting"
    Tournament -> "/tournament"
    NotFound -> "/404"
  }
  attribute.href(path)
}
