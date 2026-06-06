import gleam/dynamic/decode
import gleam/json
import scoring/archery
import scoring/axe_throwing
import scoring/hobby_horse
import scoring/jousting
import scoring/potion
import scoring/voting

// TYPES -----------------------------------------------------------------------

pub type RawInput {
  PotionRaw(List(potion.PotionGuess))
  ArcheryRaw(List(List(Int)))
  AxeThrowingRaw(List(axe_throwing.AxeThrowingShot))
  JoustingRaw(List(jousting.JoustingRound))
  HobbyHorseRaw(List(Int))
  ScavengerHuntRaw(List(Bool))
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
    Event("axe-throwing", "Axe Throwing"),
    Event("jousting", "Jousting"),
    Event("hobby-horse", "Hobby Horse Races"),
    Event("scavenger-hunt", "Scavenger Hunt"),
    Event("voting", "Voting"),
  ]
}

// SCORING ---------------------------------------------------------------------

pub fn score(raw: RawInput) -> Int {
  case raw {
    PotionRaw(guesses) -> potion.score(guesses)
    ArcheryRaw(shots) -> archery.score(shots)
    AxeThrowingRaw(shots) -> axe_throwing.score(shots)
    JoustingRaw(rounds) -> jousting.score(rounds)
    HobbyHorseRaw(times) -> hobby_horse.score(times)
    ScavengerHuntRaw(_) -> 0
    VotingRaw(_) -> 0
  }
}

pub fn score_voting_rank(rank: Int) -> Int {
  voting.score_rank(rank)
}

// JSON ENCODING ---------------------------------------------------------------

pub fn encode_raw_input(raw: RawInput) -> json.Json {
  case raw {
    PotionRaw(guesses) ->
      json.object([
        #("type", json.string("potion")),
        #("attempts", json.array(guesses, potion.encode_guess)),
      ])
    ArcheryRaw(shots) ->
      json.object([
        #("type", json.string("archery")),
        #("shots", archery.encode_shots(shots)),
      ])
    AxeThrowingRaw(shots) ->
      json.object([
        #("type", json.string("axe_throwing")),
        #("shots", json.array(shots, axe_throwing.encode_shot)),
      ])
    JoustingRaw(rounds) ->
      json.object([
        #("type", json.string("jousting")),
        #("rounds", json.array(rounds, jousting.encode_round)),
      ])
    HobbyHorseRaw(times) ->
      json.object([
        #("type", json.string("hobby_horse")),
        #("races", json.array(times, json.int)),
      ])
    ScavengerHuntRaw(items) ->
      json.object([
        #("type", json.string("scavenger_hunt")),
        #("items", json.array(items, json.bool)),
      ])
    VotingRaw(voters) ->
      json.object([
        #("type", json.string("voting")),
        #("voters", json.array(voters, json.string)),
      ])
  }
}

// JSON DECODING ---------------------------------------------------------------

pub fn raw_input_decoder() -> decode.Decoder(RawInput) {
  use type_tag <- decode.field("type", decode.string)
  case type_tag {
    "potion" -> {
      use attempts <- decode.field(
        "attempts",
        decode.list(potion.guess_decoder()),
      )
      decode.success(PotionRaw(attempts))
    }
    "archery" -> {
      use shots <- decode.field("shots", archery.shots_decoder())
      decode.success(ArcheryRaw(shots))
    }
    "axe_throwing" -> {
      use shots <- decode.field(
        "shots",
        decode.list(axe_throwing.shot_decoder()),
      )
      decode.success(AxeThrowingRaw(shots))
    }
    "jousting" -> {
      use rounds <- decode.field(
        "rounds",
        decode.list(jousting.round_decoder()),
      )
      decode.success(JoustingRaw(rounds))
    }
    "hobby_horse" -> {
      use races <- decode.field("races", decode.list(decode.int))
      decode.success(HobbyHorseRaw(races))
    }
    "scavenger_hunt" -> {
      use items <- decode.field("items", decode.list(decode.bool))
      decode.success(ScavengerHuntRaw(items))
    }
    "voting" -> {
      use voters <- decode.field("voters", decode.list(decode.string))
      decode.success(VotingRaw(voters))
    }
    _ -> decode.failure(PotionRaw([]), "RawInput")
  }
}
