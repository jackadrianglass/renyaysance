import gleam/list

// Points by finish time (seconds). Tiers checked in order; first match wins.
// | < 10s  | 100 pts |
// | 10–14s |  80 pts |
// | 15–19s |  60 pts |
// | 20–29s |  40 pts |
// | 30s+   |  20 pts |
const points_table: List(#(Int, Int)) = [
  #(10, 100),
  #(15, 80),
  #(20, 60),
  #(30, 40),
  #(99999, 20),
]

pub fn score(times: List(Int)) -> Int {
  list.fold(times, 0, fn(acc, seconds) { acc + points_for_time(seconds) })
}

fn points_for_time(seconds: Int) -> Int {
  do_lookup(seconds, points_table)
}

fn do_lookup(seconds: Int, table: List(#(Int, Int))) -> Int {
  case table {
    [] -> 0
    [#(max, points), ..rest] ->
      case seconds < max {
        True -> points
        False -> do_lookup(seconds, rest)
      }
  }
}
