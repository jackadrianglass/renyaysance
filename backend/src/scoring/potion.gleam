import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

const points_per_correct = 10

const answers = [
  "polyjuice potion",
  "felix felicis",
  "veritaserum",
  "amortentia",
  "draught of living death",
  "wolfsbane potion",
  "skele-gro",
]

pub type PotionGuess {
  Correct
  Incorrect
}

pub fn check_answers(user_answers: List(String)) -> List(Option(PotionGuess)) {
  list.zip(answers, user_answers)
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

pub fn score(guesses: List(PotionGuess)) -> Int {
  list.fold(guesses, 0, fn(acc, guess) {
    case guess {
      Correct -> acc + points_per_correct
      Incorrect -> acc
    }
  })
}

pub fn encode_guess(guess: PotionGuess) -> json.Json {
  case guess {
    Correct -> json.string("correct")
    Incorrect -> json.string("incorrect")
  }
}

pub fn guess_decoder() -> decode.Decoder(PotionGuess) {
  use str <- decode.then(decode.string)
  case str {
    "correct" -> decode.success(Correct)
    _ -> decode.success(Incorrect)
  }
}
