import gleam/list
import gleam/result

const rank_points = [25, 15, 10, 5, 1]

const excluded: List(String) = ["Maison"]

pub fn score_rank(rank: Int) -> Int {
  list.drop(rank_points, rank - 1)
  |> list.first
  |> result.unwrap(0)
}

pub fn filter_candidates(users: List(String)) -> List(String) {
  list.filter(users, fn(u) { !list.contains(excluded, u) })
}
