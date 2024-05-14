import { Ok, Error } from "./gleam.mjs";

export function focusElementById(id) {
  const element = document.getElementById(id);

  if (element) {
    element.focus();
    return new Ok();
  } else {
    return new Error(`Could not focus element with id ${id}: not found`);
  }
}

export function showToast(id) {
  const element = document.getElementById(id);

  if (element) {
    element.toast();
    return new Ok();
  } else {
    return new Error(`Could not show toast with id ${id}: not found`);
  }
}

export function consoleError(msg) {
  console.error(msg);
}
