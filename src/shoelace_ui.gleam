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
