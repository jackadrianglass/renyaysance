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
    users: storail.Collection(List(String)),
    event_results: storail.Collection(List(EventResult)),
    votes: storail.Collection(List(Vote)),
  )
}

// SETUP -----------------------------------------------------------------------

pub fn setup() -> Store {
  let config = storail.Config(storage_path: "./data")

  let users =
    storail.Collection(
      name: "users",
      to_json: fn(names) { json.array(names, json.string) },
      decoder: decode.list(decode.string),
      config:,
    )

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

  Store(users:, event_results:, votes:)
}

pub fn all_users(store: Store) -> List(String) {
  storail.read(storail.key(store.users, "all"))
  |> result.unwrap([])
}

pub fn upsert_user(store: Store, name: String) -> Nil {
  let users = all_users(store)
  case list.contains(users, name) {
    True -> Nil
    False -> {
      let _ =
        storail.write(storail.key(store.users, "all"), list.append(users, [name]))
      Nil
    }
  }
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

pub fn recompute_voting_results(
  store: Store,
  all_handles: List(String),
) -> Nil {
  let votes = all_votes(store)

  // Count votes received per user
  let vote_counts =
    list.fold(votes, dict.new(), fn(acc, vote) {
      let current = dict.get(acc, vote.votee) |> result.unwrap(0)
      dict.insert(acc, vote.votee, current + 1)
    })

  // Ensure every user has an entry, defaulting to 0
  let all_counts =
    list.fold(all_handles, vote_counts, fn(acc, handle) {
      case dict.get(acc, handle) {
        Ok(_) -> acc
        Error(_) -> dict.insert(acc, handle, 0)
      }
    })

  // Sort descending to assign ranks
  let ranked =
    dict.to_list(all_counts)
    |> list.sort(fn(a, b) { int.compare(b.1, a.1) })

  // Upsert a voting result for every user
  list.fold(ranked, 1, fn(rank, pair) {
    let #(handle, _) = pair
    let voters =
      votes
      |> list.filter(fn(v) { v.votee == handle })
      |> list.map(fn(v) { v.voter })
    upsert_result(
      store,
      EventResult(
        handle:,
        event_id: "voting",
        raw: scoring.VotingRaw(voters:),
        points: scoring.score_voting_rank(rank),
      ),
    )
    rank + 1
  })

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
