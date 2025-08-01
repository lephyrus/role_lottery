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

  customElements.whenDefined("sl-alert").then(() => alert.toast());
}
function escapeHtml(html) {
  const div = document.createElement("div");
  div.textContent = html;
  return div.innerHTML;
}
