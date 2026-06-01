import gleam/dynamic/decode
import gleam/json
import gleam/list

const missed_points = 0

const outer_ring_points = 3

const inner_ring_points = 7

const bullseye_points = 10

pub type AxeThrowingShot {
  AxeMissed
  AxeOuterRing
  AxeInnerRing
  AxeBullseye
}

pub fn score(shots: List(AxeThrowingShot)) -> Int {
  list.fold(shots, 0, fn(acc, shot) {
    acc
    + case shot {
      AxeMissed -> missed_points
      AxeOuterRing -> outer_ring_points
      AxeInnerRing -> inner_ring_points
      AxeBullseye -> bullseye_points
    }
  })
}

pub fn encode_shot(shot: AxeThrowingShot) -> json.Json {
  case shot {
    AxeMissed -> json.string("missed")
    AxeOuterRing -> json.string("outer_ring")
    AxeInnerRing -> json.string("inner_ring")
    AxeBullseye -> json.string("bullseye")
  }
}

pub fn shot_decoder() -> decode.Decoder(AxeThrowingShot) {
  use str <- decode.then(decode.string)
  case str {
    "outer_ring" -> decode.success(AxeOuterRing)
    "inner_ring" -> decode.success(AxeInnerRing)
    "bullseye" -> decode.success(AxeBullseye)
    _ -> decode.success(AxeMissed)
  }
}
