import gleam/int
import gleam/io
import gleam/list
import scoring
import scoring/axe_throwing
import scoring/potion
import store

pub fn main() {
  let s = store.setup()

  let users = [
    "Arthur", "Lancelot", "Guinevere", "Galahad", "Merlin", "Percival",
    "Gawain", "Tristan", "Morgan", "Mordred",
  ]
  list.each(users, store.upsert_user(s, _))

  // Potion quiz (10 pts per correct, 7 questions max = 70 pts)
  let c = potion.Correct
  let x = potion.Incorrect
  seed(s, "Arthur", scoring.PotionRaw([c, c, c, c, c, x, x]))
  seed(s, "Lancelot", scoring.PotionRaw([c, c, c, c, c, c, x]))
  seed(s, "Guinevere", scoring.PotionRaw([c, c, c, c, x, x, x]))
  seed(s, "Galahad", scoring.PotionRaw([c, c, c, x, x, x, x]))
  seed(s, "Merlin", scoring.PotionRaw([c, c, c, c, c, c, c]))
  seed(s, "Percival", scoring.PotionRaw([c, c, x, x, x, x, x]))
  seed(s, "Gawain", scoring.PotionRaw([c, c, c, x, x, x, x]))
  seed(s, "Tristan", scoring.PotionRaw([c, x, x, x, x, x, x]))
  seed(s, "Morgan", scoring.PotionRaw([c, c, x, x, x, x, x]))
  seed(s, "Mordred", scoring.PotionRaw([x, x, x, x, x, x, x]))

  // Archery (sum of all pin values)
  seed(s, "Arthur", scoring.ArcheryRaw([[9, 8], [7, 10]]))
  seed(s, "Lancelot", scoring.ArcheryRaw([[8, 7], [9, 6]]))
  seed(s, "Guinevere", scoring.ArcheryRaw([[7, 8], [5, 7]]))
  seed(s, "Galahad", scoring.ArcheryRaw([[10, 10], [8, 8]]))
  seed(s, "Merlin", scoring.ArcheryRaw([[5, 5]]))
  seed(s, "Percival", scoring.ArcheryRaw([[6, 5], [4, 7]]))
  seed(s, "Gawain", scoring.ArcheryRaw([[7, 6]]))
  seed(s, "Tristan", scoring.ArcheryRaw([[4, 3], [2, 5]]))
  seed(s, "Morgan", scoring.ArcheryRaw([[3, 3]]))
  seed(s, "Mordred", scoring.ArcheryRaw([[1, 1]]))

  // Axe throwing (bullseye=10, inner=7, outer=3, missed=0)
  let bull = axe_throwing.AxeBullseye
  let inner = axe_throwing.AxeInnerRing
  let outer = axe_throwing.AxeOuterRing
  let miss = axe_throwing.AxeMissed
  seed(s, "Arthur", scoring.AxeThrowingRaw([bull, inner, bull, outer]))
  seed(s, "Lancelot", scoring.AxeThrowingRaw([bull, bull, outer]))
  seed(s, "Guinevere", scoring.AxeThrowingRaw([inner, bull, outer]))
  seed(s, "Galahad", scoring.AxeThrowingRaw([bull, bull]))
  seed(s, "Merlin", scoring.AxeThrowingRaw([miss, outer]))
  seed(s, "Percival", scoring.AxeThrowingRaw([outer, outer, miss]))
  seed(s, "Gawain", scoring.AxeThrowingRaw([inner, outer]))
  seed(s, "Tristan", scoring.AxeThrowingRaw([miss, miss, outer]))
  seed(s, "Morgan", scoring.AxeThrowingRaw([outer, miss]))
  seed(s, "Mordred", scoring.AxeThrowingRaw([miss]))

  // Hobby horse races (points by finish time — see scoring/hobby_horse.gleam)
  seed(s, "Arthur", scoring.HobbyHorseRaw([22, 28, 35, 78]))
  seed(s, "Lancelot", scoring.HobbyHorseRaw([30, 42, 55]))
  seed(s, "Guinevere", scoring.HobbyHorseRaw([38, 47]))
  seed(s, "Galahad", scoring.HobbyHorseRaw([20, 25, 33]))
  seed(s, "Merlin", scoring.HobbyHorseRaw([62]))
  seed(s, "Percival", scoring.HobbyHorseRaw([41]))
  seed(s, "Gawain", scoring.HobbyHorseRaw([70, 80]))
  seed(s, "Tristan", scoring.HobbyHorseRaw([95]))
  seed(s, "Morgan", scoring.HobbyHorseRaw([88, 50]))
  seed(s, "Mordred", scoring.HobbyHorseRaw([110, 100, 92]))

  // Costume votes — Arthur wins, then Lancelot, Guinevere, Merlin
  store.upsert_vote(s, store.Vote(voter: "Guinevere", votee: "Arthur"))
  store.upsert_vote(s, store.Vote(voter: "Merlin", votee: "Arthur"))
  store.upsert_vote(s, store.Vote(voter: "Mordred", votee: "Arthur"))
  store.upsert_vote(s, store.Vote(voter: "Lancelot", votee: "Arthur"))
  store.upsert_vote(s, store.Vote(voter: "Galahad", votee: "Lancelot"))
  store.upsert_vote(s, store.Vote(voter: "Gawain", votee: "Lancelot"))
  store.upsert_vote(s, store.Vote(voter: "Percival", votee: "Lancelot"))
  store.upsert_vote(s, store.Vote(voter: "Tristan", votee: "Guinevere"))
  store.upsert_vote(s, store.Vote(voter: "Morgan", votee: "Guinevere"))
  store.upsert_vote(s, store.Vote(voter: "Arthur", votee: "Merlin"))
  store.recompute_voting_results(s, users)

  io.println("Seeded 10 users. Top 8 by score (jousting entrants):")
  store.leaderboard(s)
  |> list.take(8)
  |> list.each(fn(entry) {
    io.println("  " <> entry.0 <> " — " <> int.to_string(entry.1) <> " pts")
  })
}

fn seed(s: store.Store, handle: String, raw: scoring.RawInput) -> Nil {
  store.upsert_result(
    s,
    store.EventResult(
      handle:,
      event_id: event_id_of(raw),
      raw:,
      points: scoring.score(raw),
    ),
  )
}

fn event_id_of(raw: scoring.RawInput) -> String {
  case raw {
    scoring.PotionRaw(_) -> "potion"
    scoring.ArcheryRaw(_) -> "archery"
    scoring.AxeThrowingRaw(_) -> "axe-throwing"
    scoring.JoustingRaw(_) -> "jousting"
    scoring.HobbyHorseRaw(_) -> "hobby-horse"
    scoring.ScavengerHuntRaw(_) -> "scavenger-hunt"
    scoring.VotingRaw(_) -> "voting"
  }
}
