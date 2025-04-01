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

export async function showToast(id) {
  try {
    // if the toast is immediately triggered (i.e. on a decode error),
    // the alert element has not been rendered yet: let's wait one
    // animation frame
    await new Promise(requestAnimationFrame);
    const element = document.getElementById(id);
    element.toast();
    return new Ok();
  } catch (err) {
    return new Error(String(err));
  }
}

export function consoleError(msg) {
  console.error(msg);
}
