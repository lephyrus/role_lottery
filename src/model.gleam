pub type Model {
  Model(
    people: List(Person),
    new_person: String,
    roles: List(Role),
    new_role: String,
    assignments: List(Assignment),
  )
}

pub type Person {
  Person(name: String)
}

pub type Role {
  Role(name: String)
}

pub type Assignment {
  Assignment(role: Role, person: Person)
}
