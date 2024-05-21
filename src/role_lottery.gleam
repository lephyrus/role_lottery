import gleam/io
import gleam/list
import gleam/string
import helpers.{cls, focus_element_by_id, handle_enter, show_toast}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shoelace_ui

// MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}

// MODEL -----------------------------------------------------------------------

type Model {
  Model(
    people: List(Person),
    new_person: String,
    roles: List(Role),
    new_role: String,
    assignments: List(Assignment),
  )
}

type Person {
  Person(name: String)
}

type Role {
  Role(name: String)
}

type Assignment {
  Assignment(role: Role, person: Person)
}

const empty_model = Model(
  people: [],
  new_person: "",
  roles: [],
  new_role: "",
  assignments: [],
)

fn init(_flags) -> #(Model, Effect(Msg)) {
  #(empty_model, effect.none())
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
  UserRemovedPerson(Person)
  UserRemovedRole(Role)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())
    UserAddedPerson -> {
      case model.new_person {
        "" -> #(model, effect.none())
        _ -> {
          let person = Person(model.new_person)
          #(
            Model(
              ..model,
              people: model.people
                |> list.append([person])
                |> list.unique,
              new_person: "",
            ),
            effect.batch([
              focus_element_by_id("new-person"),
              case list.contains(model.people, person) {
                True -> show_toast("duplicate-person-alert")
                False -> effect.none()
              },
            ]),
          )
        }
      }
    }
    UserEditedNewPerson(value) -> #(
      Model(..model, new_person: value),
      effect.none(),
    )
    UserAddedRole -> {
      case model.new_role {
        "" -> #(model, effect.none())
        _ -> {
          let role = Role(model.new_role)
          #(
            Model(
              ..model,
              roles: model.roles
                |> list.append([role]),
              new_role: "",
            ),
            focus_element_by_id("new-role"),
          )
        }
      }
    }
    UserEditedNewRole(value) -> #(
      Model(..model, new_role: value),
      effect.none(),
    )
    UserRequestedAssignment -> {
      let assignments = assign(model.roles, model.people, [])
      #(Model(..model, assignments: assignments), effect.none())
    }
    UserRequestedClear -> #(empty_model, effect.none())
    UserRemovedPerson(person) -> {
      let people =
        model.people
        |> list.filter(fn(p) { p != person })
      #(Model(..model, people: people), effect.none())
    }
    UserRemovedRole(role) -> {
      let roles =
        model.roles
        |> list.filter(fn(r) { r != role })
      #(Model(..model, roles: roles), effect.none())
    }
  }
}

fn assign(
  roles: List(Role),
  people: List(Person),
  assignments: List(Assignment),
) -> List(Assignment) {
  let people = case people {
    // use full list of people again if all have been assigned a role
    [] ->
      assignments
      |> list.map(fn(a) { a.person })
      |> list.shuffle()
    _ ->
      people
      |> list.shuffle()
  }
  case list.shuffle(roles) {
    [] -> assignments

    [role, ..remaining_roles] -> {
      case people {
        [] -> assignments
        [person, ..remaining_people] -> {
          let assignment = Assignment(role, person)
          assign(remaining_roles, remaining_people, [assignment, ..assignments])
        }
      }
    }
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  // io.debug(model)

  html.div([cls("h-screen flex flex-col")], [
    html.main(
      [cls("w-full flex flex-row gap-6 justify-center flex-1 overflow-y-auto")],
      [
        html.section([cls("w-full max-w-md h-full flex flex-col items-end")], [
          html.aside([cls("w-full mt-6 flex flex-row items-baseline gap-3")], [
            shoelace_ui.input(
              [
                cls("w-full"),
                attribute.id("new-person"),
                attribute.value(model.new_person),
                attribute.placeholder("New Person"),
                event.on_input(UserEditedNewPerson),
                event.on_keydown(handle_enter(_, UserAddedPerson, NoOp)),
              ],
              [],
            ),
            shoelace_ui.button(
              [
                attribute.disabled(model.new_person == ""),
                event.on_click(UserAddedPerson),
              ],
              [element.text("Add")],
            ),
            shoelace_ui.alert(
              [
                attribute.id("duplicate-person-alert"),
                attribute.attribute("variant", "warning"),
              ],
              [element.text("People must be unique.")],
            ),
          ]),
          html.ul(
            [cls("w-full")],
            list.map(model.people, fn(person) {
              html.li([cls("my-6 flex items-center gap-4")], [
                shoelace_ui.avatar([
                  attribute.attribute(
                    "initials",
                    string.slice(from: person.name, at_index: 0, length: 2),
                  ),
                ]),
                html.h3([cls("text-xl font-light")], [element.text(person.name)]),
                shoelace_ui.button(
                  [
                    attribute.attribute("size", "small"),
                    attribute.attribute("circle", "true"),
                    attribute.attribute("label", "Remove Person"),
                    event.on_click(UserRemovedPerson(person)),
                  ],
                  [shoelace_ui.icon("x-lg")],
                ),
              ])
            }),
          ),
        ]),
        html.section([cls("w-full max-w-md h-full flex flex-col items-start")], [
          html.aside([cls("w-full mt-6 flex flex-row items-baseline gap-3")], [
            shoelace_ui.input(
              [
                cls("w-full"),
                attribute.id("new-role"),
                attribute.value(model.new_role),
                attribute.placeholder("New Role"),
                event.on_input(UserEditedNewRole),
                event.on_keydown(handle_enter(_, UserAddedRole, NoOp)),
              ],
              [],
            ),
            shoelace_ui.button(
              [
                attribute.disabled(model.new_role == ""),
                event.on_click(UserAddedRole),
              ],
              [element.text("Add")],
            ),
          ]),
          html.ul(
            [cls("w-full")],
            list.map(model.roles, fn(role) {
              html.li([cls("my-6 flex items-center gap-4")], [
                shoelace_ui.card([cls("w-full text-sm")], [
                  html.div(
                    [
                      cls("flex justify-between"),
                      attribute.attribute("slot", "header"),
                    ],
                    [
                      html.h3([cls("text-xl font-light")], [
                        element.text(role.name),
                      ]),
                      shoelace_ui.button(
                        [
                          attribute.attribute("size", "small"),
                          attribute.attribute("circle", "true"),
                          attribute.attribute("label", "Remove Role"),
                          event.on_click(UserRemovedRole(role)),
                        ],
                        [shoelace_ui.icon("x-lg")],
                      ),
                    ],
                  ),
                  case
                    model.assignments
                    |> list.find(fn(assignment) { assignment.role == role })
                  {
                    Ok(role) ->
                      html.span([cls("flex items-center gap-2")], [
                        shoelace_ui.avatar([
                          attribute.attribute(
                            "initials",
                            string.slice(
                              from: role.person.name,
                              at_index: 0,
                              length: 2,
                            ),
                          ),
                          attribute.style([#("--size", "1.5rem")]),
                        ]),
                        element.text(role.person.name),
                      ])
                    _ -> html.span([cls("italic")], [element.text("Nobody")])
                  },
                ]),
              ])
            }),
          ),
        ]),
      ],
    ),
    html.footer([cls("w-full my-6 flex gap-4 justify-center")], [
      shoelace_ui.button(
        [
          event.on_click(UserRequestedClear),
          attribute.disabled(
            list.is_empty(model.people) && list.is_empty(model.roles),
          ),
        ],
        [element.text("Clear")],
      ),
      shoelace_ui.button(
        [
          attribute.attribute("variant", "primary"),
          attribute.disabled(
            list.is_empty(model.people) || list.is_empty(model.roles),
          ),
          event.on_click(UserRequestedAssignment),
        ],
        [element.text("Assign")],
      ),
    ]),
  ])
}
