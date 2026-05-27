import layout
import lustre/element.{type Element}
import lustre/element/html
import router

pub fn view() -> Element(msg) {
  html.div([], [
    html.h1([], [html.text("Rennyaysance")]),
    html.p([], [html.text("Welcome to the party. Choose your path.")]),
    html.h2([], [html.text("Side Quests")]),
    html.ul([], [
      html.li([], [layout.nav_link(router.Riddles, "Riddles")]),
      html.li([], [layout.nav_link(router.ScavengerHunt, "Scavenger Hunt")]),
      html.li([], [layout.nav_link(router.SwordFighting, "Sword Fighting")]),
      html.li([], [layout.nav_link(router.MysticArts, "Mystic Arts")]),
    ]),
    html.h2([], [html.text("Events")]),
    html.ul([], [
      html.li([], [layout.nav_link(router.Market, "Market")]),
      html.li([], [layout.nav_link(router.Performances, "Performance Lineup")]),
      html.li([], [layout.nav_link(router.Potluck, "Potluck")]),
      html.li([], [layout.nav_link(router.Donations, "Donations & Charity")]),
    ]),
    html.h2([], [html.text("Main Quests")]),
    html.ul([], [
      html.li([], [layout.nav_link(router.PotionQuiz, "Potion Quiz")]),
      html.li([], [layout.nav_link(router.Archery, "Archery")]),
      html.li([], [layout.nav_link(router.HobbyHorseRaces, "Hobby Horse Races")]),
      html.li([], [layout.nav_link(router.Jousting, "King's Court Jousting")]),
    ]),
    html.h2([], [html.text("Other")]),
    html.ul([], [
      html.li([], [layout.nav_link(router.CostumeVoting, "Costume Voting")]),
      html.li([], [layout.nav_link(router.Tournament, "Tournament Leaderboard")]),
      html.li([], [layout.nav_link(router.Login, "Login")]),
    ]),
  ])
}
