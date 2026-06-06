import gleam/list

// Points by finish time (seconds). Tiers checked in order; first match wins.
// | < 30s  | 100 pts |
// | 30–44s |  80 pts |
// | 45–59s |  60 pts |
// | 60–89s |  40 pts |
// | 90s+   |  20 pts |
const points_table: List(#(Int, Int)) = [
  #(30, 100),
  #(45, 80),
  #(60, 60),
  #(90, 40),
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
