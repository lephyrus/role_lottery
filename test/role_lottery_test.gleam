import birdie
import gleam/int
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import helpers
import model
import prng/seed
import trellis
import trellis/column
import trellis/style

pub fn main() {
  gleeunit.main()
}

pub fn assign_nobody_to_nothing_test() {
  helpers.assign([], [], seed.new(0))
  |> should.equal([])
}

pub fn assign_people_to_nothing_test() {
  helpers.assign([], [model.Person("Alice"), model.Person("Bob")], seed.new(0))
  |> should.equal([])
}

pub fn assign_nobody_to_roles_test() {
  helpers.assign(
    [model.Role("Admin", 1), model.Role("User", 2)],
    [],
    seed.new(0),
  )
  |> should.equal([])
}

pub fn assign_one_person_to_single_slot_roles_test() {
  let people = ["Susan"] |> list.map(fn(name) { model.Person(name) })
  let roles = [model.Role("Developer", 1), model.Role("Product Owner", 1)]
  let assignments = helpers.assign(roles, people, seed.new(0))

  pretty_print(people, roles, assignments)
  |> birdie.snap(
    "With one person and multiple single-slot roles, the person should be assigned to all roles.",
  )
}

pub fn assign_people_to_one_single_slot_role_test() {
  let people =
    ["Mark", "Helly", "Dylan", "Irving"]
    |> list.map(fn(name) { model.Person(name) })
  let roles = [model.Role("Team Leader", 1)]
  let assignments = helpers.assign(roles, people, seed.new(0))

  pretty_print(people, roles, assignments)
  |> birdie.snap(
    "With multiple people and one single-slot role, one person should be assigned to the role.",
  )
}

pub fn assign_people_to_single_slot_roles_test() {
  let people =
    ["Picard", "Riker", "Crusher", "Troi"]
    |> list.map(fn(name) { model.Person(name) })
  let roles = [
    model.Role("Captain", 1),
    model.Role("First Officer", 1),
    model.Role("Ship Counselor", 1),
    model.Role("Chief Medical Officer", 1),
  ]

  let assignments = helpers.assign(roles, people, seed.new(0))
  pretty_print(people, roles, assignments)
  |> birdie.snap(
    "With multiple people and the same number of single-slot roles, each person should be assigned to one role.",
  )
}

pub fn assign_more_people_to_single_slot_roles_test() {
  let people =
    ["Picard", "Riker", "Crusher", "Troi", "Data", "Worf"]
    |> list.map(fn(name) { model.Person(name) })
  let roles = [
    model.Role("Number One", 1),
    model.Role("Captain", 1),
    model.Role("Counselor", 1),
  ]

  let assignments = helpers.assign(roles, people, seed.new(0))
  pretty_print(people, roles, assignments)
  |> birdie.snap(
    "With more people than single-slot roles, some people should not be assigned a role.",
  )
}

pub fn assign_people_to_more_single_slot_roles_test() {
  let people =
    ["Laura", "Sean"]
    |> list.map(fn(name) { model.Person(name) })
  let roles = [
    model.Role("Teacher", 1),
    model.Role("Nurse", 1),
    model.Role("Farmer", 1),
    model.Role("Mechanic", 1),
    model.Role("Librarian", 1),
    model.Role("Barber", 1),
    model.Role("Mayor", 1),
  ]

  let assignments = helpers.assign(roles, people, seed.new(0))
  pretty_print(people, roles, assignments)
  |> birdie.snap(
    "With 2 people and 7 roles, one person should be assigned to 4 roles, and one person to 3 roles.",
  )
}

pub fn assign_n_people_to_multiple_roles_with_n_slots_each_test() {
  let people =
    ["Pawn", "Bishop", "Knight", "Rook", "Queen", "King"]
    |> list.map(fn(name) { model.Person(name) })
  let roles = [model.Role("White", 6), model.Role("Black", 6)]

  let assignments = helpers.assign(roles, people, seed.new(0))
  pretty_print(people, roles, assignments)
  |> birdie.snap(
    "With N people and roles that have N slots, each person should be assigned to all roles.",
  )
}

pub fn assign_n_people_to_multiple_roles_with_more_than_n_slots_each_test() {
  let people =
    ["Pawn", "Bishop", "Knight"]
    |> list.map(fn(name) { model.Person(name) })
  let roles = [model.Role("White", 5), model.Role("Black", 4)]

  let assignments = helpers.assign(roles, people, seed.new(0))
  pretty_print(people, roles, assignments)
  |> birdie.snap(
    "With N people and roles that have more than N slots, each person should be assigned to all roles, and the \"remaining slots\" should not be filled.",
  )
}

pub fn assign_n_people_to_multiple_roles_with_n_slots_overall_test() {
  let people =
    ["Pawn", "Bishop", "Knight", "Rook", "Queen", "King"]
    |> list.map(fn(name) { model.Person(name) })
  let roles = [model.Role("White", 2), model.Role("Black", 4)]

  let assignments = helpers.assign(roles, people, seed.new(0))
  pretty_print(people, roles, assignments)
  |> birdie.snap(
    "With N people and 2 roles that together have N slots, each person should be assigned one role.",
  )
}

pub fn assign_n_people_to_multiple_roles_with_less_than_n_slots_overall_test() {
  let people =
    ["Hewey", "Dewey", "Louie", "Donald", "Daisy"]
    |> list.map(fn(name) { model.Person(name) })
  let roles = [model.Role("Dishes", 3), model.Role("Laundry", 1)]

  let assignments = helpers.assign(roles, people, seed.new(0))
  pretty_print(people, roles, assignments)
  |> birdie.snap(
    "With 5 people and 2 roles that together have 4 slots, only 4 people should be assigned one role.",
  )
}

pub fn assign_randomly_test() {
  let people =
    ["A", "B", "C"]
    |> list.map(fn(name) { model.Person(name) })
  let roles = [model.Role("X", 1), model.Role("Y", 2)]

  let output =
    pretty_print(people, roles, helpers.assign(roles, people, seed.new(0)))
    <> "\n"
    <> pretty_print(people, roles, helpers.assign(roles, people, seed.new(1)))
    <> "\n"
    <> pretty_print(people, roles, helpers.assign(roles, people, seed.new(6)))

  output
  |> birdie.snap(
    "Assigning roles randomly should yield different results for different seeds.",
  )
}

type Row {
  Row(person: model.Person, roles: List(model.Role))
}

fn pretty_print(
  people: List(model.Person),
  roles: List(model.Role),
  assignments: List(model.Assignment),
) -> String {
  let rows =
    people
    |> list.map(fn(person) {
      let assigned_roles =
        assignments
        |> list.filter(fn(a) { a.person == person })
        |> list.map(fn(a) { a.role })
      Row(person, assigned_roles)
    })

  let first_col =
    trellis.table(rows)
    |> trellis.style(style.Round)
    |> trellis.with(
      column.new("")
      |> column.align(column.Left)
      |> column.render({
        use Row(person:, roles: _) <- trellis.param
        person.name
      }),
    )

  roles
  |> list.fold(from: first_col, with: fn(table, role) {
    table
    |> trellis.with(
      column.new(role.name <> " (" <> role.slots |> int.to_string <> ")")
      |> column.render({
        use Row(_, roles:) <- trellis.param
        case roles |> list.count(fn(r) { r == role }) {
          0 -> ""
          c -> "✓" |> string.repeat(c)
        }
      }),
    )
  })
  |> trellis.to_string
}
