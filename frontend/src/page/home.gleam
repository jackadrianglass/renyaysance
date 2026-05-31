import gleam/int
import gleam/list
import layout
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import router

pub fn view(leaderboard: List(#(String, Int))) -> Element(msg) {
  layout.page("Rennyaysance", [
    html.p([], [html.text("Welcome to the party!")]),
    html.p([], [html.text("TODO: Fill out information for donation taking")]),
    html.h1([], [html.text("Events")]),
    html.h2([], [html.text("Performance Lineup")]),
    html.dl([attribute.class("lineup")], [
      html.div([attribute.class("lineup-slot")], [
        html.dt([], [html.text("4:00 PM")]),
        html.dd([], [html.text("Jack & Haley")]),
        html.dd([], [html.text("Jacob & Jacob")]),
        html.dd([], [html.text("Arrol")]),
      ]),
      html.div([attribute.class("lineup-slot")], [
        html.dt([], [html.text("6:00 PM")]),
        html.dd([], [html.text("Cass")]),
        html.dd([], [html.text("Moe")]),
        html.dd([], [html.text("Alysse")]),
        html.dd([], [html.text("Nicole & Tess")]),
      ]),
      html.div([attribute.class("lineup-slot")], [
        html.dt([], [html.text("8:00 PM")]),
        html.dd([], [html.text("Izzy & Jack")]),
        html.dd([], [html.text("Arrol")]),
      ]),
    ]),
    html.h2([], [html.text("Market")]),
    html.p([], [html.text("TODO: List vendors, stall locations, and what's for sale.")]),
    html.h2([], [html.text("Potluck")]),
    html.p([], [html.text("TODO: List who's bringing what and any dietary notes.")]),
    html.h1([], [html.text("Contest of Champions")]),
    html.h2([], [html.text("Leaderboard")]),
    view_leaderboard(leaderboard),
    html.h2([], [html.text("Main Quests")]),
    html.div([attribute.class("nav-grid")], [
      layout.nav_button(router.PotionQuiz, "Potion Quiz"),
      layout.nav_button(router.Archery, "Archery"),
      layout.nav_button(router.HobbyHorseRaces, "Hobby Horse Races"),
      layout.nav_button(router.Jousting, "King's Court Jousting"),
      layout.nav_button(router.CostumeVoting, "Costume Voting"),
    ]),
    html.h2([], [html.text("Side Quests")]),
    html.div([attribute.class("nav-grid")], [
      layout.nav_button(router.Riddles, "Riddles"),
      layout.nav_button(router.ScavengerHunt, "Scavenger Hunt"),
      layout.nav_button(router.SwordFighting, "Sword Fighting"),
      layout.nav_button(router.MysticArts, "Mystic Arts"),
    ]),
  ])
}

fn view_leaderboard(leaderboard: List(#(String, Int))) -> Element(msg) {
  case leaderboard {
    [] -> html.p([], [html.text("No scores yet.")])
    _ ->
      html.div([attribute.class("leaderboard-wrap")], [
      html.table([attribute.class("leaderboard")], [
        html.thead([], [
          html.tr([], [
            html.th([], [html.text("Rank")]),
            html.th([], [html.text("Name")]),
            html.th([], [html.text("Points")]),
          ]),
        ]),
        html.tbody([], {
          let #(rows, _) =
            list.fold(leaderboard, #([], 1), fn(acc, entry) {
              let #(rows, rank) = acc
              let #(handle, points) = entry
              let row =
                html.tr([], [
                  html.td([], [html.text(int.to_string(rank))]),
                  html.td([], [html.text(handle)]),
                  html.td([], [html.text(int.to_string(points))]),
                ])
              #([row, ..rows], rank + 1)
            })
          list.reverse(rows)
        }),
      ])])
  }
}
