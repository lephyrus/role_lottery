import gleam/list
import helpers.{focus_element_by_id, get_initials, handle_enter, show_toast}
import lustre
import lustre/attribute.{class}
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
      let assignments = assign(model.roles, model.people)
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

fn assign(roles: List(Role), people: List(Person)) -> List(Assignment) {
  assign_all_roles(roles, people, [])
}

fn assign_all_roles(
  roles: List(Role),
  people: List(Person),
  assignments: List(Assignment),
) -> List(Assignment) {
  case roles {
    [] -> assignments
    _ -> {
      let remaining_roles = roles |> list.drop(list.length(people))
      assign_all_roles(
        remaining_roles,
        people,
        list.append(assignments, assign_people_once(roles, people, [])),
      )
    }
  }
}

fn assign_people_once(
  roles: List(Role),
  people: List(Person),
  assignments: List(Assignment),
) -> List(Assignment) {
  let people = list.shuffle(people)

  case roles, people {
    [], _ -> assignments
    _, [] -> assignments
    [role, ..remaining_roles], [person, ..remaining_people] -> {
      let assignment = Assignment(role, person)
      assign_people_once(remaining_roles, remaining_people, [
        assignment,
        ..assignments
      ])
    }
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  // io.debug(model)

  html.div([class("h-screen flex flex-col")], [
    html.main(
      [
        class(
          "w-full flex flex-row gap-6 justify-center flex-1 overflow-y-auto",
        ),
      ],
      [
        html.section([class("w-full max-w-md h-full flex flex-col items-end")], [
          html.aside([class("w-full mt-6 flex flex-row items-baseline gap-3")], [
            shoelace_ui.input(
              [
                class("w-full"),
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
            [class("w-full")],
            list.map(model.people, fn(person) {
              html.li([class("my-6 flex items-center gap-4")], [
                shoelace_ui.avatar([
                  attribute.attribute("initials", get_initials(person.name)),
                ]),
                html.h3([class("text-xl font-light")], [
                  element.text(person.name),
                ]),
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
        html.section(
          [class("w-full max-w-md h-full flex flex-col items-start")],
          [
            html.aside(
              [class("w-full mt-6 flex flex-row items-baseline gap-3")],
              [
                shoelace_ui.input(
                  [
                    class("w-full"),
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
              ],
            ),
            html.ul(
              [class("w-full")],
              list.map(model.roles, fn(role) {
                html.li([class("my-6 flex items-center gap-4")], [
                  shoelace_ui.card([class("w-full text-sm")], [
                    html.div(
                      [
                        class("flex justify-between"),
                        attribute.attribute("slot", "header"),
                      ],
                      [
                        html.h3([class("text-xl font-light")], [
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
                        html.span([class("flex items-center gap-2")], [
                          shoelace_ui.avatar([
                            attribute.attribute(
                              "initials",
                              get_initials(role.person.name),
                            ),
                            attribute.style([#("--size", "1.5rem")]),
                          ]),
                          element.text(role.person.name),
                        ])
                      _ ->
                        html.span([class("italic")], [element.text("Nobody")])
                    },
                  ]),
                ])
              }),
            ),
          ],
        ),
      ],
    ),
    html.footer([class("w-full my-6 flex gap-4 justify-center")], [
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
