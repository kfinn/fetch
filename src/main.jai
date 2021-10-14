#import "Basic";
Window_Creation :: #import "Window_Creation";
Simp :: #import "Simp";
Input :: #import "Input";
#import "Hash_Table";
#import "Math";

#load "entity_manager.jai";
#load "entity.jai";
#load "components/component.jai";
#load "components/obstacle_body.jai";
#load "components/transform.jai";
#load "components/ball_body.jai";
#load "immediate.jai";

window_width :: 1280;
window_height :: 768;

TICK_DURATION :: 1.0 / 60.0;
GRAVITY :: 1000;

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
    .{.{window_width / 2, window_height / 2}}
  );

  west_wall := add_entity(*entity_manager);
  west_wall_transform := add_component(
    west_wall,
    Transform,
    .{.{-505, 0}}
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
    .{.{0, -245}}
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
    .{.{505, 0}}
  );
  east_wall_obstacle_body := add_component(
    east_wall,
    ObstacleBody,
    .{10, 500}
  );

  ball := add_entity(*entity_manager);
  ball_transform := add_component(
    ball,
    Transform,
    .{}
  );
  ball_ball_body := add_component(
    ball,
    BallBody,
    .{}
  );

  last_clock_tick := get_time();
  should_quit_game := false;
  mouse_is_down := false;
  while !should_quit_game {
    current_time := get_time();
    if last_clock_tick + TICK_DURATION > current_time {
      continue;
    } else {
      last_clock_tick += TICK_DURATION;
      while last_clock_tick + TICK_DURATION <= current_time {
        last_clock_tick += TICK_DURATION;
      }
    }

    Input.update_window_events();

    for event: Input.events_this_frame {
      if event.type == {
        case .QUIT;
          should_quit_game = true;
        case .KEYBOARD;
          if event.key_code == .MOUSE_BUTTON_LEFT {
            mouse_is_down = xx event.key_pressed;
          }
      }
    }

    if mouse_is_down {
      mouse_position_x, mouse_position_y := Window_Creation.get_mouse_pointer_position(window, true);

      gamespace_mouse_position_x := -camera_transform.translation.x + mouse_position_x;
      gamespace_mouse_position_y := -camera_transform.translation.y + mouse_position_y;

      ball_ball_body.velocity.x = 0.5 * (gamespace_mouse_position_x - ball_transform.translation.x) / TICK_DURATION;
      ball_ball_body.velocity.y = 0.5 * (gamespace_mouse_position_y - ball_transform.translation.y) / TICK_DURATION;

      ball_transform.translation.x = gamespace_mouse_position_x;
      ball_transform.translation.y = gamespace_mouse_position_y;
    } else {
      frame_start_velocity_y := ball_ball_body.velocity.y;
      frame_end_velocity_y := frame_start_velocity_y - TICK_DURATION * GRAVITY;

      effective_velocity_y := (frame_start_velocity_y + frame_end_velocity_y) / 2.0;

      ball_transform.translation.x += TICK_DURATION * ball_ball_body.velocity.x;
      ball_transform.translation.y += TICK_DURATION * effective_velocity_y;

      ball_ball_body.velocity.y = frame_end_velocity_y;
    }

    render(window, entity_manager, camera);
    reset_temporary_storage();
  }
}

render :: (window: $Window, entity_manager: EntityManager, camera: *Entity) {
  Simp.update_window(window, window_width, window_height, window_width, window_height);
  camera_transform := find_components_by_entity_id(entity_manager, Transform, camera.id)[0];
  Simp.clear_render_target(.2, .3, .3, 1);
  
  Simp.set_shader_for_color();
  for obstacle_body: entity_manager.obstacle_bodies {
    transform := find_components_by_entity_id(entity_manager, Transform, obstacle_body.entity_id)[0];
    Simp.immediate_quad(
      camera_transform.translation.x + transform.translation.x - obstacle_body.width / 2,
      camera_transform.translation.y + transform.translation.y - obstacle_body.height / 2,
      camera_transform.translation.x + transform.translation.x + obstacle_body.width / 2,
      camera_transform.translation.y + transform.translation.y + obstacle_body.height / 2,
      .{0, 1, 0, 1}
    );
  }
  for ball_body: entity_manager.ball_bodies {
    transform := find_components_by_entity_id(entity_manager, Transform, ball_body.entity_id)[0];
    immediate_circle(transform.translation + camera_transform.translation, 10, .{1, 1, 1, 1}, 7);
  }

  Simp.swap_buffers(window);
}
