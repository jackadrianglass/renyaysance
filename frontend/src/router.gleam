import gleam/uri.{type Uri}

import lustre/attribute.{type Attribute}

pub type Route {
  Home
  Riddles
  ScavengerHunt
  SwordFighting
  MysticArts
  Market
  Performances
  Potluck
  PotionQuiz
  Archery
  HobbyHorseRaces
  Jousting
  CostumeVoting
  Tournament
  NotFound
}

pub fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] | [""] -> Home
    ["riddles"] -> Riddles
    ["scavenger-hunt"] -> ScavengerHunt
    ["sword-fighting"] -> SwordFighting
    ["mystic-arts"] -> MysticArts
    ["market"] -> Market
    ["performances"] -> Performances
    ["potluck"] -> Potluck
    ["potion-quiz"] -> PotionQuiz
    ["archery"] -> Archery
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
    Riddles -> "/riddles"
    ScavengerHunt -> "/scavenger-hunt"
    SwordFighting -> "/sword-fighting"
    MysticArts -> "/mystic-arts"
    Market -> "/market"
    Performances -> "/performances"
    Potluck -> "/potluck"
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
