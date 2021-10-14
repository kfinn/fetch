Component :: struct(Data: Type) {
  entity_id: int;
  id: int;
  destroyed: bool;
  using data: Data;
}

init :: (
  using component: *$Component,
  entity: *Entity,
  component_id: int,
  component_data: Component.Data
) {
  entity_id = entity.id;
  id = component_id;
  data = component_data;
}
