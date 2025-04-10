import lustre/attribute.{type Attribute}
import lustre/element.{type Element, element}

pub fn button(
  attrs: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  element(
    "sl-button",
    [
      attribute.attribute("variant", "default"),
      attribute.attribute("size", "medium"),
      ..attrs
    ],
    children,
  )
}

pub fn input(
  attrs: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  element(
    "sl-input",
    [attribute.type_("text"), attribute.attribute("size", "medium"), ..attrs],
    children,
  )
}

pub fn alert(
  attrs: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  element(
    "sl-alert",
    [
      attribute.attribute("closable", ""),
      attribute.attribute("duration", "5000"),
      ..attrs
    ],
    children,
  )
}

pub fn avatar(attrs: List(Attribute(msg))) -> Element(msg) {
  element(
    "sl-avatar",
    [
      attribute.attribute("label", "avatar"),
      attribute.attribute("shape", "circle"),
      ..attrs
    ],
    [],
  )
}

pub fn card(
  attrs: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  element("sl-card", attrs, children)
}

pub fn icon(name: String) -> fn(List(Attribute(msg))) -> Element(msg) {
  fn(attrs: List(Attribute(msg))) {
    element(
      "sl-icon",
      [
        attribute.attribute("name", name),
        attribute.attribute("library", "default"),
        ..attrs
      ],
      [],
    )
  }
}

pub fn slot_selector(attrs: List(Attribute(msg))) -> Element(msg) {
  element(
    "sl-slot-rating",
    [
      attribute.attribute("label", "Slots"),
      attribute.attribute("max", "3"),
      attribute.style("--symbol-color-active", "var(--sl-color-primary-300)"),
      ..attrs
    ],
    [],
  )
}

pub fn tooltip(
  attrs: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  element(
    "sl-tooltip",
    [attribute.attribute("distance", "12"), ..attrs],
    children,
  )
}
