EntityManager :: struct {
  entities: [..]Entity;
  
  obstacle_bodies: [..]ObstacleBody;
  unique_obstacle_bodies_by_entity_id: Table(int, *ObstacleBody);

  transforms: [..]Transform;
  unique_transforms_by_entity_id: Table(int, *Transform);

  ball_bodies: [..]BallBody;
  unique_ball_bodies_by_entity_id: Table(int, *BallBody);
}

init :: (using entity_manager: *EntityManager) {
  remember_allocators(*entities);
  remember_allocators(*obstacle_bodies);
  remember_allocators(*transforms);

  init(*unique_obstacle_bodies_by_entity_id);
  init(*unique_transforms_by_entity_id);
}

deinit :: (using entity_manager: *EntityManager) {
  uninit(*unique_obstacle_bodies_by_entity_id);
  uninit(*unique_transforms_by_entity_id);
}

add_entity :: (using entity_manager: *EntityManager) -> *Entity {
  id := entities.count + 1;
  entity := array_add(*entities);
  entity.entity_manager = entity_manager;
  entity.id = id;
  return entity;
}

find_entity :: (using entity_manager: EntityManager, id: int) -> *Entity {
  return *entities[id];
}

add_component :: (
  using entity_manager: *EntityManager,
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
      case ObstacleBody;
        print_to_builder(
          *components_definition_string_builder,
          "*obstacle_bodies;\n"
        );
        print_to_builder(
          *unique_components_by_entity_id_definition_string_builder,
          "*unique_obstacle_bodies_by_entity_id;\n"
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

find_components_by_entity_id :: (
  using entity_manager: EntityManager,
  $ConcreteComponent: Type,
  entity_id: int
) -> []*ConcreteComponent {
  #if ConcreteComponent == Transform {
    transform, transform_found := table_find(
      unique_transforms_by_entity_id,
      entity_id
    );
    if transform_found {
      result: [1]*Transform;
      result[0] = transform;
      return result;
    } else {
      return.[];
    }
  } else #if ConcreteComponent == ObstacleBody {
    obstacle_body, obstacle_body_found := table_find(
      unique_obstacle_bodies_by_entity_id,
      entity_id
    );
    if obstacle_body_found {
      result: [1]*ObstacleBody;
      result[0] = obstacle_body;
      return result;
    } else {
      return.[];
    }
  } else #if ConcreteComponent == BallBody {
    ball_body, ball_body_found := table_find(
      unique_obstacle_bodies_by_entity_id,
      entity_id
    );
    if ball_body_found {
      result: [1]*BallBody;
      result[0] = ball_body;
      return result;
    } else {
      return.[];
    }
  } else {
    #assert false, tprint("find_components_by_entity_id called with invalid Component type: %", ConcreteComponent);
  }
}
