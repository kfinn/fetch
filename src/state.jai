State :: struct {
  entities: [..]Entity;
  
  collision_bodies: [..]CollisionBody;
  unique_collision_bodies_by_entity_id: Table(int, *CollisionBody);

  transforms: [..]Transform;
  unique_transforms_by_entity_id: Table(int, *Transform);

  ball_bodies: [..]BallBody;
  unique_ball_bodies_by_entity_id: Table(int, *BallBody);

  game_input: GameInput;
  camera_transform: Transform;
}

init :: (using state: *State) {
  remember_allocators(*entities);
  remember_allocators(*collision_bodies);
  remember_allocators(*transforms);

  init(*unique_collision_bodies_by_entity_id);
  init(*unique_transforms_by_entity_id);
}

deinit :: (using state: *State) {
  uninit(*unique_collision_bodies_by_entity_id);
  uninit(*unique_transforms_by_entity_id);
}

add_entity :: (using state: *State) -> *Entity {
  id := entities.count + 1;
  entity := array_add(*entities);
  entity.id = id;
  return entity;
}

find_entity :: (using state: State, id: int) -> *Entity {
  return *entities[id];
}

add_component :: (
  using state: *State,
  entity: *Entity,
  $ConcreteComponent: Type,
  data: ConcreteComponent.Data
) -> *ConcreteComponent {
  #insert #run () -> string {
    components_definition_string_builder: String_Builder;
    defer free_buffers(*components_definition_string_builder);

    unique_components_by_entity_id_definition_string_builder: String_Builder;
    defer free_buffers(*unique_components_by_entity_id_definition_string_builder);

    has_unique_components_by_entity_id_definition_string_builder: String_Builder;
    defer free_buffers(*has_unique_components_by_entity_id_definition_string_builder);

    print_to_builder(
      *components_definition_string_builder,
      "components := "
    );
    print_to_builder(
      *unique_components_by_entity_id_definition_string_builder,
      "unique_components_by_entity_id := "
    );
    print_to_builder(
      *has_unique_components_by_entity_id_definition_string_builder,
      "has_unique_components_by_entity_id :: "
    );
    if ConcreteComponent == {
      case Transform;
        print_to_builder(
          *components_definition_string_builder,
          "*transforms;\n"
        );
        print_to_builder(
          *unique_components_by_entity_id_definition_string_builder,
          "*unique_transforms_by_entity_id;\n"
        );
        print_to_builder(
          *has_unique_components_by_entity_id_definition_string_builder,
          "true;\n"
        );
      case CollisionBody;
        print_to_builder(
          *components_definition_string_builder,
          "*collision_bodies;\n"
        );
        print_to_builder(
          *unique_components_by_entity_id_definition_string_builder,
          "*unique_collision_bodies_by_entity_id;\n"
        );
        print_to_builder(
          *has_unique_components_by_entity_id_definition_string_builder,
          "true;\n"
        );
      case BallBody;
        print_to_builder(
          *components_definition_string_builder,
          "*ball_bodies;\n"
        );
        print_to_builder(
          *unique_components_by_entity_id_definition_string_builder,
          "*unique_ball_bodies_by_entity_id;\n"
        );
        print_to_builder(
          *has_unique_components_by_entity_id_definition_string_builder,
          "true;\n"
        );
      case;
        assert(false, "add_component called with invalid Component type: %", ConcreteComponent);
    }

    string_builder: String_Builder;
    defer free_buffers(*string_builder);
    print_to_builder(*string_builder, builder_to_string(*components_definition_string_builder));
    print_to_builder(*string_builder, builder_to_string(*unique_components_by_entity_id_definition_string_builder));
    print_to_builder(*string_builder, builder_to_string(*has_unique_components_by_entity_id_definition_string_builder));
    return builder_to_string(*string_builder);
  }();
  id := components.count + 1;
  component := array_add(components);
  init(component, entity, id, data);
  #if has_unique_components_by_entity_id { 
    assert(!table_find_pointer(<<unique_components_by_entity_id, entity.id), "attempting to add duplicate % for entity %", ConcreteComponent, <<entity);
    table_add(unique_components_by_entity_id, entity.id, component);
  }
  return component;
}

find_transform_by_entity_id :: #bake_arguments find_component_by_entity_id(ConcreteComponent=Transform, index_name="unique_transforms_by_entity_id");
find_collision_body_by_entity_id :: #bake_arguments find_component_by_entity_id(ConcreteComponent=CollisionBody, index_name="unique_collision_bodies_by_entity_id");
find_ball_body_by_entity_id :: #bake_arguments find_component_by_entity_id(ConcreteComponent=BallBody, index_name="unique_ball_bodies_by_entity_id");

#scope_file

find_component_by_entity_id :: (
  using state: State,
  entity_id: int,
  $ConcreteComponent: Type,
  $index_name: string
) -> *ConcreteComponent {
  #insert #run sprint("components_by_entity_id := %;\n", index_name);
  component, component_found := table_find(
    components_by_entity_id,
    entity_id
  );
  if component_found then return component; else return null;
}
