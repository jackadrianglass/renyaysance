import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/result

// POINT VALUES — adjust these to change scoring --------------------------------

const potion_points_per_correct = 10

const archery_missed_points = 0

const archery_outer_ring_points = 3

const archery_inner_ring_points = 7

const archery_bullseye_points = 10

const jousting_points_per_win = 10

const jousting_win_cap = 6

// Indexed by rank: index 0 = 1st place, index 1 = 2nd place, etc.
const voting_rank_points = [25, 15, 10, 5, 1]

// TYPES -----------------------------------------------------------------------

pub type PotionGuess {
  Correct
  Incorrect
}

pub type ArcheryShot {
  Missed
  OuterRing
  InnerRing
  Bullseye
}

pub type JoustingRound {
  Win
  Loss
}

pub type RawInput {
  PotionRaw(List(PotionGuess))
  ArcheryRaw(List(ArcheryShot))
  JoustingRaw(List(JoustingRound))
  VotingRaw(voters: List(String))
}

pub type Event {
  Event(id: String, label: String)
}

// EVENTS ----------------------------------------------------------------------

pub fn events() -> List(Event) {
  [
    Event("potion", "Potion Guessing"),
    Event("archery", "Archery"),
    Event("jousting", "Jousting"),
    Event("voting", "Voting"),
  ]
}

// SCORING ---------------------------------------------------------------------

pub fn score(raw: RawInput) -> Int {
  case raw {
    PotionRaw(guesses) -> score_potion(guesses)
    ArcheryRaw(shots) -> score_archery(shots)
    JoustingRaw(rounds) -> score_jousting(rounds)
    VotingRaw(_) -> 0
  }
}

pub fn score_voting_rank(rank: Int) -> Int {
  list.drop(voting_rank_points, rank - 1)
  |> list.first
  |> result.unwrap(0)
}

fn score_potion(guesses: List(PotionGuess)) -> Int {
  list.fold(guesses, 0, fn(acc, guess) {
    case guess {
      Correct -> acc + potion_points_per_correct
      Incorrect -> acc
    }
  })
}

fn score_archery(shots: List(ArcheryShot)) -> Int {
  list.fold(shots, 0, fn(acc, shot) {
    acc
    + case shot {
      Missed -> archery_missed_points
      OuterRing -> archery_outer_ring_points
      InnerRing -> archery_inner_ring_points
      Bullseye -> archery_bullseye_points
    }
  })
}

fn score_jousting(rounds: List(JoustingRound)) -> Int {
  let wins =
    list.fold(rounds, 0, fn(acc, round) {
      case round {
        Win -> acc + 1
        Loss -> acc
      }
    })
  int.min(wins, jousting_win_cap) * jousting_points_per_win
}

// JSON ENCODING ---------------------------------------------------------------

pub fn encode_raw_input(raw: RawInput) -> json.Json {
  case raw {
    PotionRaw(guesses) ->
      json.object([
        #("type", json.string("potion")),
        #("attempts", json.array(guesses, encode_potion_guess)),
      ])
    ArcheryRaw(shots) ->
      json.object([
        #("type", json.string("archery")),
        #("shots", json.array(shots, encode_archery_shot)),
      ])
    JoustingRaw(rounds) ->
      json.object([
        #("type", json.string("jousting")),
        #("rounds", json.array(rounds, encode_jousting_round)),
      ])
    VotingRaw(voters) ->
      json.object([
        #("type", json.string("voting")),
        #("voters", json.array(voters, json.string)),
      ])
  }
}

fn encode_potion_guess(guess: PotionGuess) -> json.Json {
  case guess {
    Correct -> json.string("correct")
    Incorrect -> json.string("incorrect")
  }
}

fn encode_archery_shot(shot: ArcheryShot) -> json.Json {
  case shot {
    Missed -> json.string("missed")
    OuterRing -> json.string("outer_ring")
    InnerRing -> json.string("inner_ring")
    Bullseye -> json.string("bullseye")
  }
}

fn encode_jousting_round(round: JoustingRound) -> json.Json {
  case round {
    Win -> json.string("win")
    Loss -> json.string("loss")
  }
}

// JSON DECODING ---------------------------------------------------------------

pub fn raw_input_decoder() -> decode.Decoder(RawInput) {
  use type_tag <- decode.field("type", decode.string)
  case type_tag {
    "potion" -> {
      use attempts <- decode.field(
        "attempts",
        decode.list(potion_guess_decoder()),
      )
      decode.success(PotionRaw(attempts))
    }
    "archery" -> {
      use shots <- decode.field("shots", decode.list(archery_shot_decoder()))
      decode.success(ArcheryRaw(shots))
    }
    "jousting" -> {
      use rounds <- decode.field(
        "rounds",
        decode.list(jousting_round_decoder()),
      )
      decode.success(JoustingRaw(rounds))
    }
    "voting" -> {
      use voters <- decode.field("voters", decode.list(decode.string))
      decode.success(VotingRaw(voters))
    }
    _ -> decode.failure(PotionRaw([]), "RawInput")
  }
}

fn potion_guess_decoder() -> decode.Decoder(PotionGuess) {
  use str <- decode.then(decode.string)
  case str {
    "correct" -> decode.success(Correct)
    _ -> decode.success(Incorrect)
  }
}

fn archery_shot_decoder() -> decode.Decoder(ArcheryShot) {
  use str <- decode.then(decode.string)
  case str {
    "outer_ring" -> decode.success(OuterRing)
    "inner_ring" -> decode.success(InnerRing)
    "bullseye" -> decode.success(Bullseye)
    _ -> decode.success(Missed)
  }
}

fn jousting_round_decoder() -> decode.Decoder(JoustingRound) {
  use str <- decode.then(decode.string)
  case str {
    "win" -> decode.success(Win)
    _ -> decode.success(Loss)
  }
}
