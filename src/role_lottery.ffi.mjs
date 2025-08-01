// This code is taken from the Shoelace website. We completely handle the
// toasts in Javascript, because:
// - we can't call `.toast()` on the alert element from Lustre anyway
// - and if we create the alert element in Lustre, we run into errors because
//   `toast()` removes the element after the supplied `duration`
export function notify(message, variant, icon, duration) {
  const alert = Object.assign(document.createElement("sl-alert"), {
    variant,
    closable: true,
    duration: duration,
    innerHTML: `
        <sl-icon name="${icon}" slot="icon"></sl-icon>
        ${escapeHtml(message)}
      `,
  });

  document.body.append(alert);

  return alert.toast();
}
function escapeHtml(html) {
  const div = document.createElement("div");
  div.textContent = html;
  return div.innerHTML;
}

// The Shoelace rating component has this weird `getSymbol` API, where the
// property has to be set to a function that returns an HTML string used for
// the rating icon. It's not possible to do this is Lustre, but we do want
// Lustre to manage the element, so we extend the element and set the property
// here.
class SlotRating extends customElements.get("sl-rating") {
  constructor() {
    super();
    this.getSymbol = () => '<sl-icon name="person-circle"></sl-icon>';
  }
}
customElements.define("sl-slot-rating", SlotRating);
