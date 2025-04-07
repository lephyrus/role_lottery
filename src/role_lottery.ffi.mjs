import { Ok, Error } from "./gleam.mjs";

export async function showToast(element) {
  try {
    element.toast();
    return new Ok();
  } catch (err) {
    return new Error(String(err));
  }
}
