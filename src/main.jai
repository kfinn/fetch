#import "Basic";
Window_Creation :: #import "Window_Creation";
Simp :: #import "Simp";
Input :: #import "Input";
#import "Hash_Table";

#load "entity_manager.jai";
#load "entity.jai";
#load "components/component.jai";
#load "components/obstacle_body.jai";
#load "components/transform.jai";

window_width :: 1280;
window_height :: 768;

main :: () {
  window := Window_Creation.create_window(window_name="Fetch", width=window_width, height=window_height);
  Simp.simp_init(window, window_width, window_height, window_width, window_height);

  entity_manager: EntityManager;
  init(*entity_manager);
  defer deinit(*entity_manager);

  camera := add_entity(*entity_manager);
  camera_transform := add_component(
    camera,
    Transform,
    .{window_width / 2, window_height / 2}
  );

  west_wall := add_entity(*entity_manager);
  west_wall_transform := add_component(
    west_wall,
    Transform,
    .{-505, 0}
  );
  west_wall_obstacle_body := add_component(
    west_wall,
    ObstacleBody,
    .{10, 500}
  );

  floor := add_entity(*entity_manager);
  floor_transform := add_component(
    floor,
    Transform,
    .{0, -245}
  );
  floor_obstacle_body := add_component(
    floor,
    ObstacleBody,
    .{1000, 10}
  );


  east_wall := add_entity(*entity_manager);
  east_wall_transform := add_component(
    east_wall,
    Transform,
    .{505, 0}
  );
  east_wall_obstacle_body := add_component(
    east_wall,
    ObstacleBody,
    .{10, 500}
  );

  should_quit_game := false;
  while !should_quit_game {
    Simp.update_window(window, window_width, window_height, window_width, window_height);
    Input.update_window_events();

    render(window, entity_manager, camera);

    for event: Input.events_this_frame {
      if event.type == .QUIT {
          should_quit_game = true;
          break;
      }
    }

    sleep_milliseconds(10);
    reset_temporary_storage();
  }
}

render :: (window: $Window, entity_manager: EntityManager, camera: *Entity) {
  camera_transform := find_components_by_entity_id(entity_manager, Transform, camera.id)[0];
  Simp.clear_render_target(.2, .3, .3, 1);
  
  Simp.set_shader_for_color();
  for obstacle_body: entity_manager.obstacle_bodies {
    transform := find_components_by_entity_id(entity_manager, Transform, obstacle_body.entity_id)[0];
    Simp.immediate_quad(
      camera_transform.x + transform.x - obstacle_body.width / 2,
      camera_transform.y + transform.y - obstacle_body.height / 2,
      camera_transform.x + transform.x + obstacle_body.width / 2,
      camera_transform.y + transform.y + obstacle_body.height / 2,
      .{0, 1, 0, 1}
    );
  }

  Simp.swap_buffers(window);
}
