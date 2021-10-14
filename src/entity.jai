Entity :: struct {
  entity_manager: *EntityManager;
  id: int;
  destroyed: bool = false;
}

add_component :: (
  using entity: *Entity,
  $ConcreteComponent: Type,
  data: ConcreteComponent.Data
) -> *ConcreteComponent {
  return add_component(
    entity_manager,
    entity,
    ConcreteComponent,
    data
  );
}
