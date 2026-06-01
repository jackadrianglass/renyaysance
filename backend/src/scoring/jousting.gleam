import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list

const points_per_win = 10

const win_cap = 6

pub type JoustingRound {
  Win
  Loss
}

pub fn score(rounds: List(JoustingRound)) -> Int {
  let wins =
    list.fold(rounds, 0, fn(acc, round) {
      case round {
        Win -> acc + 1
        Loss -> acc
      }
    })
  int.min(wins, win_cap) * points_per_win
}

pub fn encode_round(round: JoustingRound) -> json.Json {
  case round {
    Win -> json.string("win")
    Loss -> json.string("loss")
  }
}

pub fn round_decoder() -> decode.Decoder(JoustingRound) {
  use str <- decode.then(decode.string)
  case str {
    "win" -> decode.success(Win)
    _ -> decode.success(Loss)
  }
}
