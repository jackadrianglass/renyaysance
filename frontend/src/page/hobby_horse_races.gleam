import gleam/int
import gleam/json
import gleam/list
import layout
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import rsvp

// MODEL -----------------------------------------------------------------------

pub type Race {
  NotRecorded
  Timed(Int)
}

pub type Model {
  Model(races: List(Race), saved: Bool)
}

pub fn init() -> Model {
  Model(races: [], saved: False)
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  AddRace
  SetTime(Int, String)
  RemoveRace(Int)
  Saved(Bool)
}

pub fn update(model: Model, msg: Msg, handle: String) -> #(Model, Effect(Msg)) {
  case msg {
    AddRace -> {
      let new_races = list.append(model.races, [NotRecorded])
      #(Model(races: new_races, saved: False), do_submit(handle, new_races))
    }
    SetTime(index, val) -> {
      let race = case int.parse(val) {
        Ok(s) if s >= 0 -> Timed(s)
        _ -> NotRecorded
      }
      let new_races = set_at(model.races, index, race)
      #(Model(races: new_races, saved: False), do_submit(handle, new_races))
    }
    RemoveRace(index) -> {
      let new_races = remove_at(model.races, index)
      #(Model(races: new_races, saved: False), do_submit(handle, new_races))
    }
    Saved(ok) -> #(Model(..model, saved: ok), effect.none())
  }
}

fn set_at(lst: List(a), target: Int, value: a) -> List(a) {
  list.index_map(lst, fn(item, i) {
    case i == target {
      True -> value
      False -> item
    }
  })
}

fn remove_at(lst: List(a), index: Int) -> List(a) {
  list.flatten([list.take(lst, index), list.drop(lst, index + 1)])
}

fn do_submit(handle: String, races: List(Race)) -> Effect(Msg) {
  let times =
    list.filter_map(races, fn(r) {
      case r {
        NotRecorded -> Error(Nil)
        Timed(s) -> Ok(s)
      }
    })
  let body =
    json.object([
      #("handle", json.string(handle)),
      #(
        "raw",
        json.object([
          #("type", json.string("hobby_horse")),
          #("races", json.array(times, json.int)),
        ]),
      ),
    ])
  rsvp.post(
    "/api/events/hobby-horse/result",
    body,
    rsvp.expect_ok_response(fn(result) { Saved(result_is_ok(result)) }),
  )
}

fn result_is_ok(r: Result(a, b)) -> Bool {
  case r {
    Ok(_) -> True
    Error(_) -> False
  }
}

// VIEW ------------------------------------------------------------------------

pub fn view(model: Model) -> Element(Msg) {
  layout.page("Hobby Horse Races", [
    html.p([], [html.text("Mount up. The track awaits.")]),
    html.div(
      [attribute.class("attempts")],
      list.index_map(model.races, view_row),
    ),
    html.button([attribute.class("attempt-add"), event.on_click(AddRace)], [
      html.text("+"),
    ]),
    html.p([], [
      html.text(
        "Recorded: "
        <> int.to_string(count_recorded(model.races))
        <> " / "
        <> int.to_string(list.length(model.races))
        <> " races",
      ),
    ]),
    case model.saved {
      True ->
        html.p([attribute.class("saved-message")], [html.text("Score saved!")])
      False -> html.text("")
    },
  ])
}

fn view_row(race: Race, index: Int) -> Element(Msg) {
  let row_cls = case race {
    NotRecorded -> "attempt-row"
    Timed(_) -> "attempt-row attempt-row--bullseye"
  }
  html.div([attribute.class(row_cls)], [
    html.span([attribute.class("attempt-num")], [
      html.text("Race " <> int.to_string(index + 1)),
    ]),
    html.input([
      attribute.class("attempt-time"),
      attribute.type_("number"),
      attribute.placeholder("seconds"),
      attribute.attribute("min", "0"),
      attribute.value(case race {
        NotRecorded -> ""
        Timed(s) -> int.to_string(s)
      }),
      event.on_input(fn(val) { SetTime(index, val) }),
    ]),
    html.button(
      [attribute.class("attempt-remove"), event.on_click(RemoveRace(index))],
      [html.text("✕")],
    ),
  ])
}

fn count_recorded(races: List(Race)) -> Int {
  list.fold(races, 0, fn(acc, race) {
    acc + case race {
      Timed(_) -> 1
      NotRecorded -> 0
    }
  })
}
