import layout
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  layout.page("Welcome to the party!", [
    html.h2([], [html.text("Basics")]),
    html.p([], [html.text("2033 28 St SE Calgary")]),
    html.p([], [html.text("Event starts at 2 p.m.")]),
    html.p([attribute.class("dress-code")], [html.text("Dress up! Anything from the renaissance!")]),
    html.h2([], [html.text("Donations")]),
    html.p([], [
      html.text(
        "Send donations to maisonlaird@gmail.com. Funds will be used to pay for the supplies of the event and all the extras will be sent to ",
      ),
      html.a([attribute.href("https://www.huggabowl.com/")], [
        html.text("Huggabowl"),
      ]),
    ]),
    html.h2([], [html.text("Market")]),
    html.p([], [
      html.text("Bring an item (or many) to trade! Home made items are encouraged. Private trading with others is open till 5:30, then market opens where you can swap your item with any other. If you bring more than one item, then you can take more than one item."),
    ]),
    html.h2([], [html.text("Potluck & Food")]),
    html.p([], [
      html.text("Bring a small item of food if you want to participate in the potluck. The food will be available the whole event."),
    ]),
    html.h2([], [html.text("Performance Lineup")]),
    html.div([attribute.class("lineup-table-wrap")], [
      html.table([attribute.class("lineup-table")], [
        html.thead([], [
          html.tr([], [
            html.th([], [html.text("Time")]),
            html.th([], [html.text("Stage")]),
            html.th([], [html.text("Arcane Arts")]),
            html.th([], [html.text("World Events")]),
          ]),
        ]),
        html.tbody([], [
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("2:30 PM")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.attribute("rowspan", "3")], [html.text("Advice - Wesley")]),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("2:45 PM")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("3:00 PM")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("3:15 PM")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.attribute("rowspan", "3")], [html.text("Sword Fighting - Patrick")]),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("3:30 PM")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.attribute("rowspan", "3")], [html.text("Calligraphy - Olga")]),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("3:45 PM")]),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("4:00 PM")]),
            html.td([], [html.text("Jack & Haley")]),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("4:15 PM")]),
            html.td([], [html.text("Moe")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("4:30 PM")]),
            html.td([], [html.text("Izzy")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("4:45 PM")]),
            html.td([], [html.text("Arrol & Coco")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("5:00 PM")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.attribute("rowspan", "5")], [html.text("Obsidian Readings - John")]),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("5:15 PM")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.attribute("rowspan", "3")], [
              html.text("Sword Fighting - Patrick"),
              html.br([]),
              html.span([attribute.class("lineup-note")], [html.text("Market opens 5:30")]),
            ]),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("5:30 PM")]),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("5:45 PM")]),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("6:00 PM")]),
            html.td([], [html.text("Cass")]),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("6:15 PM")]),
            html.td([attribute.attribute("rowspan", "2")], [html.text("Jacob")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("6:30 PM")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("6:45 PM")]),
            html.td([], [html.text("Tess & Nicole")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("7:00 PM")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.attribute("rowspan", "3")], [html.text("Tarot Card Readings - Amelia")]),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("7:15 PM")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.attribute("rowspan", "3")], [html.text("King's Tourney Jousting")]),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("7:30 PM")]),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("7:45 PM")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("8:00 PM")]),
            html.td([], [html.text("Musique")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("8:15 PM")]),
            html.td([attribute.attribute("rowspan", "2")], [html.text("Alysse")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("8:30 PM")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.class("lineup-empty")], []),
          ]),
          html.tr([], [
            html.td([attribute.class("lineup-time")], [html.text("8:45 PM")]),
            html.td([], [html.text("Arrol & Coco")]),
            html.td([attribute.class("lineup-empty")], []),
            html.td([attribute.class("lineup-empty")], []),
          ]),
        ]),
      ]),
    ]),
  ])
}
