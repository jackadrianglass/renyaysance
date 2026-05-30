import gleam/dict
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import scoring.{type RawInput}
import storail

// TYPES -----------------------------------------------------------------------

pub type EventResult {
  EventResult(handle: String, event_id: String, raw: RawInput, points: Int)
}

pub type Vote {
  Vote(voter: String, votee: String)
}

pub type Store {
  Store(
    event_results: storail.Collection(List(EventResult)),
    votes: storail.Collection(List(Vote)),
  )
}

// SETUP -----------------------------------------------------------------------

pub fn setup() -> Store {
  let config = storail.Config(storage_path: "./data")

  let event_results =
    storail.Collection(
      name: "event_results",
      to_json: fn(results) { json.array(results, encode_event_result) },
      decoder: decode.list(event_result_decoder()),
      config:,
    )

  let votes =
    storail.Collection(
      name: "votes",
      to_json: fn(vs) { json.array(vs, encode_vote) },
      decoder: decode.list(vote_decoder()),
      config:,
    )

  Store(event_results:, votes:)
}

// PUBLIC API ------------------------------------------------------------------

pub fn all_results(store: Store) -> List(EventResult) {
  storail.read(storail.key(store.event_results, "all"))
  |> result.unwrap([])
}

pub fn upsert_result(store: Store, new_result: EventResult) -> Nil {
  let results = all_results(store)
  let without_old =
    list.filter(results, fn(r) {
      r.handle != new_result.handle || r.event_id != new_result.event_id
    })
  let _ =
    storail.write(
      storail.key(store.event_results, "all"),
      list.append(without_old, [new_result]),
    )
  Nil
}

pub fn all_votes(store: Store) -> List(Vote) {
  storail.read(storail.key(store.votes, "all"))
  |> result.unwrap([])
}

pub fn upsert_vote(store: Store, new_vote: Vote) -> Nil {
  let votes = all_votes(store)
  let without_old = list.filter(votes, fn(v) { v.voter != new_vote.voter })
  let _ =
    storail.write(
      storail.key(store.votes, "all"),
      list.append(without_old, [new_vote]),
    )
  Nil
}

pub fn leaderboard(store: Store) -> List(#(String, Int)) {
  all_results(store)
  |> list.fold(dict.new(), fn(acc, r) {
    let current = dict.get(acc, r.handle) |> result.unwrap(0)
    dict.insert(acc, r.handle, current + r.points)
  })
  |> dict.to_list
  |> list.sort(fn(a, b) { int.compare(b.1, a.1) })
}

// JSON ENCODING ---------------------------------------------------------------

fn encode_event_result(r: EventResult) -> json.Json {
  json.object([
    #("handle", json.string(r.handle)),
    #("event_id", json.string(r.event_id)),
    #("raw", scoring.encode_raw_input(r.raw)),
    #("points", json.int(r.points)),
  ])
}

fn encode_vote(v: Vote) -> json.Json {
  json.object([
    #("voter", json.string(v.voter)),
    #("votee", json.string(v.votee)),
  ])
}

// JSON DECODING ---------------------------------------------------------------

fn event_result_decoder() -> decode.Decoder(EventResult) {
  use handle <- decode.field("handle", decode.string)
  use event_id <- decode.field("event_id", decode.string)
  use raw <- decode.field("raw", scoring.raw_input_decoder())
  use points <- decode.field("points", decode.int)
  decode.success(EventResult(handle:, event_id:, raw:, points:))
}

fn vote_decoder() -> decode.Decoder(Vote) {
  use voter <- decode.field("voter", decode.string)
  use votee <- decode.field("votee", decode.string)
  decode.success(Vote(voter:, votee:))
}
