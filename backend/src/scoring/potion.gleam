import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

const points_per_correct = 10

const answer_map = [
  #("Coloured stripes", "paprika"),
  #("Purple", "lavender"),
  #("Cherry Bottle", "balsamic vinegar"),
  #("Yellow Flowers", "coffee"),
  #("Pink Flowers", "nutmeg"),
  #("Orange circles", "ginger"),
  #("Blue Mountains", "yeast"),
  #("Vines", "thyme"),
  #("Blue waves, red dots", "sesame oil"),
]

pub type PotionGuess {
  Correct
  Incorrect
}

pub fn check_answers(
  user_answers: List(#(String, String)),
) -> List(Option(PotionGuess)) {
  list.map(user_answers, fn(pair) {
    let #(name, user_answer) = pair
    case string.trim(user_answer) {
      "" -> None
      _ ->
        case find_correct(name) {
          None -> Some(Incorrect)
          Some(correct) ->
            case is_close_enough(user_answer, correct) {
              True -> Some(Correct)
              False -> Some(Incorrect)
            }
        }
    }
  })
}

fn find_correct(name: String) -> Option(String) {
  let key = string.lowercase(string.trim(name))
  list.find_map(answer_map, fn(pair) {
    let #(n, a) = pair
    case string.lowercase(n) == key {
      True -> Ok(a)
      False -> Error(Nil)
    }
  })
  |> option.from_result
}

// Accepts an answer if it matches exactly, if the correct answer appears as a
// substring of the user's input (e.g. "orange juice" for "orange"), if the
// user typed a meaningful prefix/substring of the answer (>= 4 chars), or if
// the edit distance is within a length-scaled threshold.
fn is_close_enough(user_answer: String, correct_answer: String) -> Bool {
  let user = string.lowercase(string.trim(user_answer))
  let correct = string.lowercase(string.trim(correct_answer))
  let threshold = int.max(2, string.length(correct) / 5)

  user == correct
  || string.contains(user, correct)
  || { string.length(user) >= 4 && string.contains(correct, user) }
  || levenshtein(user, correct) <= threshold
}

fn levenshtein(a: String, b: String) -> Int {
  let a_chars = string.to_graphemes(a)
  let b_chars = string.to_graphemes(b)
  let b_len = list.length(b_chars)

  // Build initial row [0, 1, 2, ..., b_len]
  let init = list.index_map(list.repeat(0, b_len + 1), fn(_, i) { i })

  let final_row =
    list.fold(
      list.index_map(a_chars, fn(c, i) { #(c, i + 1) }),
      init,
      fn(prev_row, pair) {
        let #(a_char, i) = pair
        // Pair each b_char with (prev_row[j-1], prev_row[j]) — diagonal and above
        let b_with_prev =
          list.zip(b_chars, list.zip(prev_row, list.drop(prev_row, 1)))
        let #(_, new_row_rev) =
          list.fold(b_with_prev, #(i, [i]), fn(state, entry) {
            let #(left, partial) = state
            let #(b_char, #(diag, above)) = entry
            let cost = case a_char == b_char { True -> 0 False -> 1 }
            let v = int.min(diag + cost, int.min(above + 1, left + 1))
            #(v, [v, ..partial])
          })
        list.reverse(new_row_rev)
      },
    )

  list.last(final_row) |> result.unwrap(list.length(a_chars))
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
