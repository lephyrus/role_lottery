import gleam/io
import gleam/list
import gleam/option
import gleam/uri
import helpers
import lustre
import lustre/attribute.{class}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import model
import modem
import shoelace_ui

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}

// MODEL -----------------------------------------------------------------------

const empty_model = model.Model(
  people: [],
  new_person: "",
  roles: [],
  new_role: "",
  assignments: [],
  decode_error: "",
  clipboard_write_success: False,
)

fn init(_flags) -> #(model.Model, Effect(Msg)) {
  #(
    empty_model,
    effect.from(fn(dispatch) {
      case modem.initial_uri() {
        Ok(initial_uri) ->
          dispatch(
            OnRouteChange(case uri.path_segments(initial_uri.path) {
              [] -> ""
              [first, ..] -> first
            }),
          )
        _ -> dispatch(NoOp)
      }
    }),
  )
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  NoOp
  UserAddedPerson
  UserEditedNewPerson(String)
  UserAddedRole
  UserEditedNewRole(String)
  UserRequestedAssignment
  UserRequestedClear
  UserRemovedPerson(model.Person)
  UserRemovedRole(model.Role)
  UserSharedUrl
  BrowserWroteClipboardWithSuccess
  BrowserWroteClipboardWithError
  OnRouteChange(String)
}

fn update(model: model.Model, msg: Msg) -> #(model.Model, Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())
    UserAddedPerson -> {
      case model.new_person {
        "" -> #(model, effect.none())
        _ -> {
          let person = model.Person(model.new_person)
          let people = model.people |> list.append([person]) |> list.unique
          let new_model = model.Model(..model, people:, new_person: "")
          #(
            new_model,
            effect.batch([
              reflect_state_in_url(new_model),
              helpers.focus_element_by_id("new-person"),
              case list.contains(model.people, person) {
                True -> helpers.show_toast("duplicate-person-alert")
                False -> effect.none()
              },
            ]),
          )
        }
      }
    }
    UserEditedNewPerson(value) -> #(
      model.Model(..model, new_person: value),
      effect.none(),
    )
    UserAddedRole -> {
      case model.new_role {
        "" -> #(model, effect.none())
        _ -> {
          let roles = model.roles |> list.append([model.Role(model.new_role)])
          let new_model = model.Model(..model, roles:, new_role: "")
          #(
            new_model,
            effect.batch([
              reflect_state_in_url(new_model),
              helpers.focus_element_by_id("new-role"),
            ]),
          )
        }
      }
    }
    UserEditedNewRole(value) -> #(
      model.Model(..model, new_role: value),
      effect.none(),
    )
    UserRequestedAssignment -> {
      let assignments = helpers.assign(model.roles, model.people)
      let new_model = model.Model(..model, assignments:)
      #(new_model, reflect_state_in_url(new_model))
    }
    UserRequestedClear -> #(empty_model, reflect_state_in_url(empty_model))
    UserRemovedPerson(person) -> {
      let people =
        model.people
        |> list.filter(fn(p) { p != person })
      let assignments =
        model.assignments
        |> list.filter(fn(a) { a.person != person })
      let new_model = model.Model(..model, people:, assignments:)
      #(new_model, reflect_state_in_url(new_model))
    }
    UserRemovedRole(role) -> {
      let roles =
        model.roles
        |> list.filter(fn(r) { r != role })
      let new_model = model.Model(..model, roles:)
      #(new_model, reflect_state_in_url(new_model))
    }
    OnRouteChange(encoded_state) -> {
      case encoded_state {
        "" -> #(model, effect.none())
        encoded_state -> {
          case helpers.decode_state(encoded_state) {
            Ok(#(people, roles, assignments)) -> #(
              model.Model(
                ..model,
                people:,
                roles:,
                assignments:,
                decode_error: "",
              ),
              effect.none(),
            )
            Error(message) -> {
              io.print_error(message)
              #(
                model.Model(
                  ..model,
                  decode_error: "Could not decode state:\n" <> message,
                ),
                helpers.show_toast("decode-error-alert"),
              )
            }
          }
        }
      }
    }
    UserSharedUrl -> #(
      model,
      helpers.copy_url_to_clipboard(
        BrowserWroteClipboardWithSuccess,
        BrowserWroteClipboardWithError,
      ),
    )
    BrowserWroteClipboardWithSuccess -> #(
      model.Model(..model, clipboard_write_success: True),
      helpers.show_toast("clipboard-alert"),
    )
    BrowserWroteClipboardWithError -> #(
      model.Model(..model, clipboard_write_success: False),
      helpers.show_toast("clipboard-alert"),
    )
  }
}

fn reflect_state_in_url(model: model.Model) -> Effect(Msg) {
  let encoded =
    helpers.encode_state(model.people, model.roles, model.assignments)

  modem.replace(
    case encoded {
      "" -> "/"
      _ -> encoded
    },
    option.None,
    option.None,
  )
}

// VIEW ------------------------------------------------------------------------

fn view(model: model.Model) -> Element(Msg) {
  html.div([class("h-screen flex flex-col")], [
    decode_error_alert(model.decode_error),
    clipboard_alert(model.clipboard_write_success),
    html.main(
      [
        class(
          "w-full flex flex-row gap-6 justify-center flex-1 overflow-y-auto",
        ),
      ],
      [
        html.section([class("w-full max-w-md h-full flex flex-col items-end")], [
          html.aside(
            [class("w-full mt-10 flex flex-row items-baseline gap-3")],
            [
              shoelace_ui.input(
                [
                  class("w-full"),
                  attribute.id("new-person"),
                  attribute.value(model.new_person),
                  attribute.placeholder("New Person"),
                  event.on_input(UserEditedNewPerson),
                  event.on_keydown(helpers.handle_enter(
                    _,
                    UserAddedPerson,
                    NoOp,
                  )),
                ],
                [],
              ),
              shoelace_ui.button(
                [
                  attribute.disabled(model.new_person == ""),
                  event.on_click(UserAddedPerson),
                ],
                [
                  shoelace_ui.icon("plus-lg")([
                    attribute.attribute("slot", "prefix"),
                  ]),
                  element.text("Add"),
                ],
              ),
              shoelace_ui.alert(
                [
                  attribute.id("duplicate-person-alert"),
                  attribute.attribute("variant", "warning"),
                ],
                [element.text("People must be unique.")],
              ),
            ],
          ),
          html.ul([class("w-full")], list.map(model.people, person_card)),
        ]),
        html.section(
          [class("w-full max-w-md h-full flex flex-col items-start")],
          [
            html.aside(
              [class("w-full mt-10 flex flex-row items-baseline gap-3")],
              [
                shoelace_ui.input(
                  [
                    class("w-full"),
                    attribute.id("new-role"),
                    attribute.value(model.new_role),
                    attribute.placeholder("New Role"),
                    event.on_input(UserEditedNewRole),
                    event.on_keydown(helpers.handle_enter(
                      _,
                      UserAddedRole,
                      NoOp,
                    )),
                  ],
                  [],
                ),
                shoelace_ui.button(
                  [
                    attribute.disabled(model.new_role == ""),
                    event.on_click(UserAddedRole),
                  ],
                  [
                    shoelace_ui.icon("plus-lg")([
                      attribute.attribute("slot", "prefix"),
                    ]),
                    element.text("Add"),
                  ],
                ),
              ],
            ),
            html.ul(
              [class("w-full")],
              list.map(model.roles, role_card(model.assignments, _)),
            ),
          ],
        ),
      ],
    ),
    html.footer([class("w-full mt-6 mb-10 flex gap-4 justify-center")], [
      shoelace_ui.button(
        [
          attribute.disabled(
            list.is_empty(model.people) && list.is_empty(model.roles),
          ),
          event.on_click(UserSharedUrl),
        ],
        [
          shoelace_ui.icon("share")([attribute.attribute("slot", "prefix")]),
          element.text("Share"),
        ],
      ),
      shoelace_ui.button(
        [
          event.on_click(UserRequestedClear),
          attribute.disabled(
            list.is_empty(model.people) && list.is_empty(model.roles),
          ),
        ],
        [
          shoelace_ui.icon("trash")([attribute.attribute("slot", "prefix")]),
          element.text("Clear"),
        ],
      ),
      shoelace_ui.button(
        [
          attribute.attribute("variant", "primary"),
          attribute.disabled(
            list.is_empty(model.people) || list.is_empty(model.roles),
          ),
          event.on_click(UserRequestedAssignment),
        ],
        [
          shoelace_ui.icon("shuffle")([attribute.attribute("slot", "prefix")]),
          element.text("Assign"),
        ],
      ),
    ]),
  ])
}

fn person_card(person: model.Person) -> Element(Msg) {
  html.li([class("my-6 flex items-center gap-4")], [
    shoelace_ui.avatar([
      attribute.attribute("initials", helpers.get_initials(person.name)),
    ]),
    html.h3([class("text-xl font-light")], [element.text(person.name)]),
    shoelace_ui.button(
      [
        attribute.attribute("size", "small"),
        attribute.attribute("circle", "true"),
        attribute.attribute("label", "Remove Person"),
        event.on_click(UserRemovedPerson(person)),
      ],
      [shoelace_ui.icon("x-lg")([])],
    ),
  ])
}

fn role_card(
  assignments: List(model.Assignment),
  role: model.Role,
) -> Element(Msg) {
  html.li([class("my-6 flex items-center gap-4")], [
    shoelace_ui.card([class("w-full text-sm")], [
      html.div(
        [class("flex justify-between"), attribute.attribute("slot", "header")],
        [
          html.h3([class("text-xl font-light")], [element.text(role.name)]),
          shoelace_ui.button(
            [
              attribute.attribute("size", "small"),
              attribute.attribute("circle", "true"),
              attribute.attribute("label", "Remove Role"),
              event.on_click(UserRemovedRole(role)),
            ],
            [shoelace_ui.icon("x-lg")([])],
          ),
        ],
      ),
      case
        assignments
        |> list.find(fn(assignment) { assignment.role == role })
      {
        Ok(role) ->
          html.span([class("flex items-center gap-2")], [
            shoelace_ui.avatar([
              attribute.attribute(
                "initials",
                helpers.get_initials(role.person.name),
              ),
              attribute.style([#("--size", "1.5rem")]),
            ]),
            element.text(role.person.name),
          ])
        _ -> html.span([class("italic leading-6")], [element.text("Nobody")])
      },
    ]),
  ])
}

fn decode_error_alert(error: String) {
  shoelace_ui.alert(
    [
      attribute.id("decode-error-alert"),
      attribute.attribute("variant", "danger"),
    ],
    [element.text(error)],
  )
}

fn clipboard_alert(success: Bool) {
  shoelace_ui.alert(
    [
      attribute.id("clipboard-alert"),
      attribute.attribute("variant", case success {
        True -> "success"
        False -> "danger"
      }),
    ],
    [
      shoelace_ui.icon("check-lg")([attribute.attribute("slot", "prefix")]),
      case success {
        True -> element.text("Link copied to clipboard!")
        False -> element.text("Failed to copy link to clipboard.")
      },
    ],
  )
}
