import gleam/dynamic/decode
import gleam/json
import gleam/list

pub fn score(shots: List(List(Int))) -> Int {
  list.fold(shots, 0, fn(acc, shot) {
    acc + list.fold(shot, 0, fn(inner, pin) { inner + pin })
  })
}

pub fn encode_shots(shots: List(List(Int))) -> json.Json {
  json.array(shots, fn(shot) { json.array(shot, json.int) })
}

pub fn shots_decoder() -> decode.Decoder(List(List(Int))) {
  decode.list(decode.list(decode.int))
}
