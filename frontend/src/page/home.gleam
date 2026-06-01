import gleam/int
import gleam/list
import layout
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import router

pub fn view(leaderboard: List(#(String, Int))) -> Element(msg) {
  layout.page("Contest of Champions", [
    html.h2([], [html.text("Leaderboard")]),
    view_leaderboard(leaderboard),
    html.h2([], [html.text("Tournament")]),
    html.div([attribute.class("nav-grid")], [
      layout.nav_button(router.Archery, "Archery"),
      layout.nav_button(router.HobbyHorseRaces, "Hobby Horsing"),
      layout.nav_button(router.PotionQuiz, "Potion"),
      layout.nav_button(router.Jousting, "King's Court Jousting"),
    ]),
    html.h2([], [html.text("Quests")]),
    html.div([attribute.class("nav-grid")], [
      layout.nav_button(router.Riddles, "Riddles"),
      layout.nav_button(router.SwordFighting, "Sword Fighting"),
      layout.nav_button(router.ScavengerHunt, "Scavenger Hunt"),
      layout.nav_button(router.CostumeVoting, "Costume Voting"),
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
