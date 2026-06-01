import gleam/dynamic/decode
import gleam/json
import gleam/list

const points_per_win = 10

pub type Bout {
  BoutWon
  BoutLost
}

pub fn score(bouts: List(Bout)) -> Int {
  list.fold(bouts, 0, fn(acc, bout) {
    case bout {
      BoutWon -> acc + points_per_win
      BoutLost -> acc
    }
  })
}

pub fn encode_bout(bout: Bout) -> json.Json {
  case bout {
    BoutWon -> json.string("won")
    BoutLost -> json.string("lost")
  }
}

pub fn bout_decoder() -> decode.Decoder(Bout) {
  use str <- decode.then(decode.string)
  case str {
    "won" -> decode.success(BoutWon)
    _ -> decode.success(BoutLost)
  }
}
