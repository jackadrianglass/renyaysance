import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

// POINT VALUES — adjust these to change scoring --------------------------------

const potion_points_per_correct = 10

const axe_throwing_missed_points = 0

const axe_throwing_outer_ring_points = 3

const axe_throwing_inner_ring_points = 7

const axe_throwing_bullseye_points = 10

const jousting_points_per_win = 10

const jousting_win_cap = 6

const hobby_horse_points_per_win = 10

// Indexed by rank: index 0 = 1st place, index 1 = 2nd place, etc.
const voting_rank_points = [25, 15, 10, 5, 1]

// TYPES -----------------------------------------------------------------------

pub type PotionGuess {
  Correct
  Incorrect
}

pub type AxeThrowingShot {
  AxeMissed
  AxeOuterRing
  AxeInnerRing
  AxeBullseye
}

pub type JoustingRound {
  Win
  Loss
}

pub type Bout {
  BoutWon
  BoutLost
}

pub type RawInput {
  PotionRaw(List(PotionGuess))
  ArcheryRaw(List(List(Int)))
  JoustingRaw(List(JoustingRound))
  VotingRaw(voters: List(String))
  AxeThrowingRaw(List(AxeThrowingShot))
  HobbyHorseRaw(List(Bout))
}

pub type Event {
  Event(id: String, label: String)
}

// POTION ANSWERS --------------------------------------------------------------

const potion_answers = [
  "polyjuice potion",
  "felix felicis",
  "veritaserum",
  "amortentia",
  "draught of living death",
  "wolfsbane potion",
  "skele-gro",
]

pub fn check_potion_answers(user_answers: List(String)) -> List(Option(PotionGuess)) {
  list.zip(potion_answers, user_answers)
  |> list.map(fn(pair) {
    let #(answer, user_answer) = pair
    case string.trim(user_answer) {
      "" -> None
      trimmed ->
        case string.lowercase(trimmed) == answer {
          True -> Some(Correct)
          False -> Some(Incorrect)
        }
    }
  })
}

// EVENTS ----------------------------------------------------------------------

pub fn events() -> List(Event) {
  [
    Event("potion", "Potion Guessing"),
    Event("archery", "Archery"),
    Event("axe-throwing", "Axe Throwing"),
    Event("jousting", "Jousting"),
    Event("hobby-horse", "Hobby Horse Races"),
    Event("voting", "Voting"),
  ]
}

// SCORING ---------------------------------------------------------------------

pub fn score(raw: RawInput) -> Int {
  case raw {
    PotionRaw(guesses) -> score_potion(guesses)
    ArcheryRaw(shots) -> score_archery(shots)
    AxeThrowingRaw(shots) -> score_axe_throwing(shots)
    JoustingRaw(rounds) -> score_jousting(rounds)
    HobbyHorseRaw(bouts) -> score_bouts(bouts, hobby_horse_points_per_win)
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

fn score_archery(shots: List(List(Int))) -> Int {
  list.fold(shots, 0, fn(acc, shot) {
    acc + list.fold(shot, 0, fn(inner, pin) { inner + pin })
  })
}

fn score_axe_throwing(shots: List(AxeThrowingShot)) -> Int {
  list.fold(shots, 0, fn(acc, shot) {
    acc
    + case shot {
      AxeMissed -> axe_throwing_missed_points
      AxeOuterRing -> axe_throwing_outer_ring_points
      AxeInnerRing -> axe_throwing_inner_ring_points
      AxeBullseye -> axe_throwing_bullseye_points
    }
  })
}

fn score_bouts(bouts: List(Bout), points_per_win: Int) -> Int {
  list.fold(bouts, 0, fn(acc, bout) {
    case bout {
      BoutWon -> acc + points_per_win
      BoutLost -> acc
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
        #("shots", json.array(shots, fn(shot) { json.array(shot, json.int) })),
      ])
    AxeThrowingRaw(shots) ->
      json.object([
        #("type", json.string("axe_throwing")),
        #("shots", json.array(shots, encode_axe_throwing_shot)),
      ])
    JoustingRaw(rounds) ->
      json.object([
        #("type", json.string("jousting")),
        #("rounds", json.array(rounds, encode_jousting_round)),
      ])
    HobbyHorseRaw(bouts) ->
      json.object([
        #("type", json.string("hobby_horse")),
        #("races", json.array(bouts, encode_bout)),
      ])
    VotingRaw(voters) ->
      json.object([
        #("type", json.string("voting")),
        #("voters", json.array(voters, json.string)),
      ])
  }
}

fn encode_bout(bout: Bout) -> json.Json {
  case bout {
    BoutWon -> json.string("won")
    BoutLost -> json.string("lost")
  }
}

fn encode_potion_guess(guess: PotionGuess) -> json.Json {
  case guess {
    Correct -> json.string("correct")
    Incorrect -> json.string("incorrect")
  }
}

fn encode_axe_throwing_shot(shot: AxeThrowingShot) -> json.Json {
  case shot {
    AxeMissed -> json.string("missed")
    AxeOuterRing -> json.string("outer_ring")
    AxeInnerRing -> json.string("inner_ring")
    AxeBullseye -> json.string("bullseye")
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
      use shots <- decode.field(
        "shots",
        decode.list(decode.list(decode.int)),
      )
      decode.success(ArcheryRaw(shots))
    }
    "axe_throwing" -> {
      use shots <- decode.field(
        "shots",
        decode.list(axe_throwing_shot_decoder()),
      )
      decode.success(AxeThrowingRaw(shots))
    }
    "jousting" -> {
      use rounds <- decode.field(
        "rounds",
        decode.list(jousting_round_decoder()),
      )
      decode.success(JoustingRaw(rounds))
    }
    "hobby_horse" -> {
      use races <- decode.field("races", decode.list(bout_decoder()))
      decode.success(HobbyHorseRaw(races))
    }
    "voting" -> {
      use voters <- decode.field("voters", decode.list(decode.string))
      decode.success(VotingRaw(voters))
    }
    _ -> decode.failure(PotionRaw([]), "RawInput")
  }
}

fn bout_decoder() -> decode.Decoder(Bout) {
  use str <- decode.then(decode.string)
  case str {
    "won" -> decode.success(BoutWon)
    _ -> decode.success(BoutLost)
  }
}

fn potion_guess_decoder() -> decode.Decoder(PotionGuess) {
  use str <- decode.then(decode.string)
  case str {
    "correct" -> decode.success(Correct)
    _ -> decode.success(Incorrect)
  }
}

fn axe_throwing_shot_decoder() -> decode.Decoder(AxeThrowingShot) {
  use str <- decode.then(decode.string)
  case str {
    "outer_ring" -> decode.success(AxeOuterRing)
    "inner_ring" -> decode.success(AxeInnerRing)
    "bullseye" -> decode.success(AxeBullseye)
    _ -> decode.success(AxeMissed)
  }
}

fn jousting_round_decoder() -> decode.Decoder(JoustingRound) {
  use str <- decode.then(decode.string)
  case str {
    "win" -> decode.success(Win)
    _ -> decode.success(Loss)
  }
}
