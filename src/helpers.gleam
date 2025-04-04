import gleam/string
import lustre/effect.{type Effect}

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

// EXTERNALS -------------------------------------------------------------------

pub fn focus_element_by_id(id: String) -> Effect(msg) {
  effect.from(fn(_) {
    case do_focus_element_by_id(id) {
      Ok(Nil) -> Nil
      Error(e) -> {
        do_console_error(e)
      }
    }
  })
}

@external(javascript, "./role_lottery.ffi.mjs", "focusElementById")
fn do_focus_element_by_id(_id: String) -> Result(Nil, String) {
  Ok(Nil)
}

pub fn show_toast(id: String) -> Effect(msg) {
  effect.from(fn(_) {
    case do_show_toast(id) {
      Ok(Nil) -> Nil
      Error(e) -> {
        do_console_error(e)
      }
    }
  })
}

@external(javascript, "./role_lottery.ffi.mjs", "showToast")
fn do_show_toast(_id: String) -> Result(Nil, String) {
  Ok(Nil)
}

pub fn console_error(msg: String) -> Effect(msg) {
  effect.from(fn(_) { do_console_error(msg) })
}

@external(javascript, "./role_lottery.ffi.mjs", "consoleError")
fn do_console_error(_msg: String) -> Nil {
  Nil
}
