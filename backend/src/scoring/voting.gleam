import gleam/list
import gleam/result

const rank_points = [25, 15, 10, 5, 1]

pub fn score_rank(rank: Int) -> Int {
  list.drop(rank_points, rank - 1)
  |> list.first
  |> result.unwrap(0)
}
