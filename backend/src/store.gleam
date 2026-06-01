import gleam/dict
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import scoring.{type RawInput}
import storail

@external(erlang, "rand", "uniform_real")
fn rand_float() -> Float

// TYPES -----------------------------------------------------------------------

pub type BracketMatch {
  BracketMatch(p1: Option(String), p2: Option(String), winner: Option(String))
}

pub type BracketState {
  SignupPhase(participants: List(String))
  ActivePhase(rounds: List(List(BracketMatch)))
}

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
    jousting_bracket: storail.Collection(BracketState),
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

  let jousting_bracket =
    storail.Collection(
      name: "jousting_bracket",
      to_json: encode_bracket_state,
      decoder: bracket_state_decoder(),
      config:,
    )

  Store(users:, event_results:, votes:, jousting_bracket:)
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

// JOUSTING BRACKET ------------------------------------------------------------

pub fn get_bracket_state(store: Store) -> BracketState {
  storail.read(storail.key(store.jousting_bracket, "state"))
  |> result.unwrap(SignupPhase([]))
}

pub fn top_players(store: Store, n: Int) -> List(String) {
  leaderboard(store)
  |> list.take(n)
  |> list.map(fn(pair) { pair.0 })
}

pub fn jousting_reset(store: Store) -> BracketState {
  let state = SignupPhase([])
  let _ = storail.write(storail.key(store.jousting_bracket, "state"), state)
  state
}

pub fn jousting_generate(store: Store) -> BracketState {
  case get_bracket_state(store) {
    SignupPhase(_) -> {
      let participants = top_players(store, 8)
      let bracket = generate_bracket(participants)
      let state = ActivePhase(bracket)
      let _ =
        storail.write(storail.key(store.jousting_bracket, "state"), state)
      state
    }
    active -> active
  }
}

pub fn jousting_record_result(
  store: Store,
  handle: String,
  won: Bool,
) -> BracketState {
  case get_bracket_state(store) {
    SignupPhase(_) as s -> s
    ActivePhase(rounds) -> {
      let new_rounds = apply_result(rounds, handle, won)
      let state = ActivePhase(new_rounds)
      let _ =
        storail.write(storail.key(store.jousting_bracket, "state"), state)
      state
    }
  }
}

fn apply_result(
  rounds: List(List(BracketMatch)),
  handle: String,
  won: Bool,
) -> List(List(BracketMatch)) {
  case find_active_match(rounds, handle) {
    Error(_) -> rounds
    Ok(#(round_idx, match_idx)) -> {
      let winner = case won {
        True -> Some(handle)
        False ->
          case get_match(rounds, round_idx, match_idx) {
            None -> None
            Some(m) ->
              case m.p1, m.p2 {
                Some(p1), _ if p1 != handle -> Some(p1)
                _, Some(p2) if p2 != handle -> Some(p2)
                _, _ -> None
              }
          }
      }
      rounds
      |> set_winner(round_idx, match_idx, winner)
      |> advance_winner(round_idx, match_idx, winner)
    }
  }
}

fn get_match(
  rounds: List(List(BracketMatch)),
  round_idx: Int,
  match_idx: Int,
) -> Option(BracketMatch) {
  rounds
  |> list.drop(round_idx)
  |> list.first
  |> result.try(fn(round) { list.drop(round, match_idx) |> list.first })
  |> option.from_result
}

fn find_active_match(
  rounds: List(List(BracketMatch)),
  handle: String,
) -> Result(#(Int, Int), Nil) {
  list.index_fold(rounds, Error(Nil), fn(acc, round, ri) {
    case acc {
      Ok(_) -> acc
      Error(_) ->
        list.index_fold(round, Error(Nil), fn(inner, m, mi) {
          case inner {
            Ok(_) -> inner
            Error(_) ->
              case m.winner {
                Some(_) -> Error(Nil)
                None ->
                  case m.p1 == Some(handle) || m.p2 == Some(handle) {
                    True -> Ok(#(ri, mi))
                    False -> Error(Nil)
                  }
              }
          }
        })
    }
  })
}

fn set_winner(
  rounds: List(List(BracketMatch)),
  round_idx: Int,
  match_idx: Int,
  winner: Option(String),
) -> List(List(BracketMatch)) {
  list.index_map(rounds, fn(round, ri) {
    case ri == round_idx {
      False -> round
      True ->
        list.index_map(round, fn(m, mi) {
          case mi == match_idx {
            False -> m
            True -> BracketMatch(..m, winner:)
          }
        })
    }
  })
}

fn advance_winner(
  rounds: List(List(BracketMatch)),
  round_idx: Int,
  match_idx: Int,
  winner: Option(String),
) -> List(List(BracketMatch)) {
  case winner {
    None -> rounds
    Some(_) -> {
      let next_round = round_idx + 1
      let next_match = match_idx / 2
      let is_p1_slot = match_idx % 2 == 0
      list.index_map(rounds, fn(round, ri) {
        case ri == next_round {
          False -> round
          True ->
            list.index_map(round, fn(m, mi) {
              case mi == next_match {
                False -> m
                True ->
                  case is_p1_slot {
                    True -> BracketMatch(..m, p1: winner)
                    False -> BracketMatch(..m, p2: winner)
                  }
              }
            })
        }
      })
    }
  }
}

// BRACKET GENERATION ----------------------------------------------------------

fn generate_bracket(participants: List(String)) -> List(List(BracketMatch)) {
  let shuffled =
    participants
    |> list.map(fn(p) { #(rand_float(), p) })
    |> list.sort(fn(a, b) { float.compare(a.0, b.0) })
    |> list.map(fn(pair) { pair.1 })

  let size = next_power_of_2(list.length(shuffled))
  let padded = pad_with_byes(shuffled, size)
  let round1 = make_round(padded) |> list.map(resolve_bye)
  let num_rounds = count_bits(size)
  let empty_rounds = make_empty_rounds(num_rounds - 1, size / 2)
  [round1, ..empty_rounds]
}

fn next_power_of_2(n: Int) -> Int {
  case n <= 1 {
    True -> 1
    False -> next_power_of_2_loop(1, n)
  }
}

fn next_power_of_2_loop(acc: Int, n: Int) -> Int {
  case acc >= n {
    True -> acc
    False -> next_power_of_2_loop(acc * 2, n)
  }
}

fn pad_with_byes(lst: List(String), size: Int) -> List(Option(String)) {
  let named = list.map(lst, Some)
  let needed = size - list.length(named)
  list.append(named, list.repeat(None, needed))
}

fn make_round(players: List(Option(String))) -> List(BracketMatch) {
  case players {
    [p1, p2, ..rest] ->
      [BracketMatch(p1:, p2:, winner: None), ..make_round(rest)]
    _ -> []
  }
}

fn resolve_bye(m: BracketMatch) -> BracketMatch {
  case m.p2 {
    None -> BracketMatch(..m, winner: m.p1)
    Some(_) -> m
  }
}

fn make_empty_rounds(count: Int, prev_size: Int) -> List(List(BracketMatch)) {
  case count <= 0 {
    True -> []
    False -> {
      let size = prev_size / 2
      let round = list.repeat(BracketMatch(p1: None, p2: None, winner: None), size)
      [round, ..make_empty_rounds(count - 1, prev_size / 2)]
    }
  }
}

fn count_bits(n: Int) -> Int {
  case n <= 1 {
    True -> 0
    False -> 1 + count_bits(n / 2)
  }
}

// LEADERBOARD -----------------------------------------------------------------

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

fn encode_bracket_state(state: BracketState) -> json.Json {
  case state {
    SignupPhase(participants) ->
      json.object([
        #("phase", json.string("signup")),
        #("participants", json.array(participants, json.string)),
      ])
    ActivePhase(rounds) ->
      json.object([
        #("phase", json.string("active")),
        #("rounds", json.array(rounds, fn(round) {
          json.array(round, encode_bracket_match)
        })),
      ])
  }
}

fn encode_bracket_match(m: BracketMatch) -> json.Json {
  json.object([
    #("p1", json.nullable(m.p1, json.string)),
    #("p2", json.nullable(m.p2, json.string)),
    #("winner", json.nullable(m.winner, json.string)),
  ])
}

pub fn encode_bracket_state_to_string(state: BracketState) -> String {
  encode_bracket_state(state) |> json.to_string
}

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

fn bracket_state_decoder() -> decode.Decoder(BracketState) {
  use phase <- decode.field("phase", decode.string)
  case phase {
    "active" -> {
      use rounds <- decode.field(
        "rounds",
        decode.list(decode.list(bracket_match_decoder())),
      )
      decode.success(ActivePhase(rounds))
    }
    _ -> {
      use participants <- decode.field("participants", decode.list(decode.string))
      decode.success(SignupPhase(participants))
    }
  }
}

fn bracket_match_decoder() -> decode.Decoder(BracketMatch) {
  use p1 <- decode.field("p1", decode.optional(decode.string))
  use p2 <- decode.field("p2", decode.optional(decode.string))
  use winner <- decode.field("winner", decode.optional(decode.string))
  decode.success(BracketMatch(p1:, p2:, winner:))
}

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
