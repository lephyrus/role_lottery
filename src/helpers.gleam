import gleam/bit_array
import gleam/bool
import gleam/int
import gleam/javascript/promise
import gleam/list
import gleam/result
import gleam/string
import lustre/effect.{type Effect}
import model
import plinth/browser/clipboard
import plinth/browser/document
import plinth/browser/element
import plinth/browser/window
import plinth/javascript/console

// MISC ------------------------------------------------------------------------

pub fn handle_enter(event: String, enter_msg: msg, other_msg: msg) -> msg {
  case event {
    "Enter" -> enter_msg
    _ -> other_msg
  }
}

pub fn get_initials(name: String) -> String {
  name
  |> string.slice(0, 2)
}

pub fn focus_element_by_id(id: String) -> Effect(msg) {
  effect.from(fn(_) {
    document.get_element_by_id(id)
    |> result.map(element.focus)
    |> result.unwrap_both()
  })
}

pub fn copy_url_to_clipboard(success_msg: msg, error_msg: msg) -> Effect(msg) {
  use dispatch <- effect.from
  {
    use result <- promise.map(window.location() |> clipboard.write_text())
    case result {
      Ok(_) -> {
        dispatch(success_msg)
      }
      Error(_) -> {
        dispatch(error_msg)
      }
    }
  }
  Nil
}

// ROLE ASSIGNMENT -------------------------------------------------------------

pub fn assign(
  roles: List(model.Role),
  people: List(model.Person),
) -> List(model.Assignment) {
  assign_all_roles(roles, people, [])
}

fn assign_all_roles(
  roles: List(model.Role),
  people: List(model.Person),
  assignments: List(model.Assignment),
) -> List(model.Assignment) {
  case roles {
    [] -> assignments
    _ -> {
      let new_assignments = assign_people_once(roles, people, [])
      let remaining_roles = roles |> list.drop(list.length(people))

      assign_all_roles(
        remaining_roles,
        people,
        list.append(assignments, new_assignments),
      )
    }
  }
}

fn assign_people_once(
  roles: List(model.Role),
  people: List(model.Person),
  assignments: List(model.Assignment),
) -> List(model.Assignment) {
  let people = list.shuffle(people)

  case roles, people {
    [], _ -> assignments
    _, [] -> assignments
    [role, ..remaining_roles], [person, ..remaining_people] -> {
      let assignment = model.Assignment(role, person)
      assign_people_once(remaining_roles, remaining_people, [
        assignment,
        ..assignments
      ])
    }
  }
}

// ENCODE / DECODE STATE -------------------------------------------------------

const level_1_separator = "‖"

const level_2_separator = "¦"

const level_3_separator = "‧"

pub fn encode_state(
  people: List(model.Person),
  roles: List(model.Role),
  assignments: List(model.Assignment),
) -> String {
  let indexed_people = people |> list.index_map(fn(p, i) { #(p, i) })
  let indexed_roles = roles |> list.index_map(fn(r, i) { #(r, i) })
  let encoded_people = encode_people(indexed_people)
  let encoded_roles = encode_roles(indexed_roles)
  let encoded_assignments =
    encode_assignments(assignments, indexed_people, indexed_roles)

  case encoded_people, encoded_roles, encoded_assignments {
    "", "", "" -> ""
    p, r, a ->
      [p, r, a]
      |> string.join(level_1_separator)
      |> echo
      |> bit_array.from_string
      |> bit_array.base64_url_encode(True)
  }
}

pub fn decode_state(
  encoded: String,
) -> Result(
  #(List(model.Person), List(model.Role), List(model.Assignment)),
  String,
) {
  use <- bool.guard(encoded |> string.is_empty, Ok(#([], [], [])))
  use state_bits <- result.try(
    encoded
    |> bit_array.base64_url_decode
    |> result.replace_error(
      "Could not decode base64 URL encoded state: " <> encoded,
    ),
  )
  use state_string <- result.try(
    state_bits
    |> bit_array.to_string
    |> result.replace_error(
      "Could not decode base64 URL encoded state: " <> encoded,
    ),
  )

  case string.split(state_string, level_1_separator) {
    [encoded_people, encoded_roles, encoded_assignments] -> {
      use indexed_people <- result.try(decode_people(encoded_people))
      use indexed_roles <- result.try(decode_roles(encoded_roles))
      use assignments <- result.try(decode_assignments(
        encoded_assignments,
        indexed_people,
        indexed_roles,
      ))

      let people = indexed_people |> list.map(fn(p) { p.0 })
      let roles = indexed_roles |> list.map(fn(r) { r.0 })

      Ok(#(people, roles, assignments))
    }
    _ -> Error("Could not parse encoded state: " <> state_string)
  }
}

pub fn encode_people(indexed_people: List(#(model.Person, Int))) -> String {
  indexed_people
  |> list.map(fn(p) {
    let #(person, index) = p
    person.name <> level_3_separator <> int.to_string(index)
  })
  |> string.join(level_2_separator)
}

fn decode_people(encoded: String) -> Result(List(#(model.Person, Int)), String) {
  encoded
  |> string.split(level_2_separator)
  |> list.filter(fn(s) { !string.is_empty(s) })
  |> list.map(string.split(_, level_3_separator))
  |> list.map(fn(p) {
    case p {
      [name, index_str] -> {
        int.parse(index_str)
        |> result.map(fn(index) { #(model.Person(name), index) })
        |> result.map_error(fn(_) {
          "Could not parse person index: " <> index_str
        })
      }
      _ -> Error("Could not parse encoded person: " <> string.join(p, ", "))
    }
  })
  |> result.all
}

fn encode_roles(indexed_roles: List(#(model.Role, Int))) -> String {
  indexed_roles
  |> list.map(fn(r) {
    let #(role, index) = r
    role.name <> level_3_separator <> int.to_string(index)
  })
  |> string.join(level_2_separator)
}

fn decode_roles(encoded: String) -> Result(List(#(model.Role, Int)), String) {
  encoded
  |> string.split(level_2_separator)
  |> list.filter(fn(s) { !string.is_empty(s) })
  |> list.map(string.split(_, level_3_separator))
  |> list.map(fn(r) {
    case r {
      [name, index_str] -> {
        int.parse(index_str)
        |> result.map(fn(index) { #(model.Role(name), index) })
        |> result.map_error(fn(_) {
          "Could not parse role index: " <> index_str
        })
      }
      _ -> Error("Could not parse encoded role: " <> string.join(r, ", "))
    }
  })
  |> result.all
}

fn encode_assignments(
  assignments: List(model.Assignment),
  indexed_people: List(#(model.Person, Int)),
  indexed_roles: List(#(model.Role, Int)),
) -> String {
  assignments
  |> list.map(fn(assignment) {
    let person_index =
      indexed_people
      |> list.find(fn(p) { p.0 == assignment.person })
      |> result.map(fn(p) { int.to_string(p.1) })
    let role_index =
      indexed_roles
      |> list.find(fn(r) { r.0 == assignment.role })
      |> result.map(fn(r) { int.to_string(r.1) })

    case person_index, role_index {
      Ok(person_index), Ok(role_index) ->
        person_index <> level_3_separator <> role_index
      _, _ -> ""
    }
  })
  |> list.filter(fn(a) { a != "" })
  |> string.join(level_2_separator)
}

fn decode_assignments(
  encoded: String,
  indexed_people: List(#(model.Person, Int)),
  indexed_roles: List(#(model.Role, Int)),
) -> Result(List(model.Assignment), String) {
  encoded
  |> string.split(level_2_separator)
  |> list.filter(fn(s) { !string.is_empty(s) })
  |> list.map(string.split(_, level_3_separator))
  |> list.map(fn(a) {
    case a {
      [person_index, role_index] -> {
        use p_idx <- result.try(
          person_index
          |> int.parse
          |> result.replace_error(
            "Could not parse assignment person index: " <> person_index,
          ),
        )
        use r_idx <- result.try(
          role_index
          |> int.parse
          |> result.replace_error(
            "Could not parse assignment role index: " <> role_index,
          ),
        )
        use person <- result.try(
          indexed_people
          |> list.find(fn(p) { p.1 == p_idx })
          |> result.replace_error(
            "Could not find person with index: " <> int.to_string(p_idx),
          ),
        )
        use role <- result.try(
          indexed_roles
          |> list.find(fn(r) { r.1 == r_idx })
          |> result.replace_error(
            "Could not find role with index: " <> int.to_string(r_idx),
          ),
        )

        Ok(model.Assignment(role.0, person.0))
      }
      _ ->
        Error(
          "Could not parse encoded assignment: "
          <> string.join(a, level_3_separator),
        )
    }
  })
  |> result.all
}

// EXTERNALS -------------------------------------------------------------------

pub fn show_toast(id: String) -> Effect(msg) {
  effect.from(fn(_) {
    {
      // if the toast is immediately triggered (i.e. on a decode error),
      // the alert element has not been rendered yet: let's wait one
      // animation frame
      use _ <- window.request_animation_frame
      case document.get_element_by_id(id) |> result.map(do_show_toast) {
        Error(e) -> {
          console.error(e)
        }
        _ -> Nil
      }
    }
    Nil
  })
}

@external(javascript, "./role_lottery.ffi.mjs", "showToast")
fn do_show_toast(element: element.Element) -> Result(Nil, String)
