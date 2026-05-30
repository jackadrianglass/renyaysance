import layout
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import router

pub fn view() -> Element(msg) {
  layout.page("Rennyaysance", [
    html.p([], [html.text("Welcome to the party!")]),
    html.p([], [html.text("TODO: Fill out information for donation taking")]),
    html.h1([], [html.text("Leaderboard")]),
    html.p([], [html.text("TODO: Draft the leaderboard")]),
    html.h1([], [html.text("Main Quests")]),
    html.div([attribute.class("nav-grid")], [
      layout.nav_button(router.PotionQuiz, "Potion Quiz"),
      layout.nav_button(router.Archery, "Archery"),
      layout.nav_button(router.HobbyHorseRaces, "Hobby Horse Races"),
      layout.nav_button(router.Jousting, "King's Court Jousting"),
      layout.nav_button(router.CostumeVoting, "Costume Voting"),
    ]),
    html.h1([], [html.text("Events")]),
    html.div([attribute.class("nav-grid")], [
      layout.nav_button(router.Market, "Market"),
      layout.nav_button(router.Performances, "Performance Lineup"),
      layout.nav_button(router.Potluck, "Potluck"),
    ]),
    html.h1([], [html.text("Side Quests")]),
    html.div([attribute.class("nav-grid")], [
      layout.nav_button(router.Riddles, "Riddles"),
      layout.nav_button(router.ScavengerHunt, "Scavenger Hunt"),
      layout.nav_button(router.SwordFighting, "Sword Fighting"),
      layout.nav_button(router.MysticArts, "Mystic Arts"),
    ]),
  ])
}

