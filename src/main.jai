#import "Basic";
Window_Creation :: #import "Window_Creation";
Simp :: #import "Simp";
Input :: #import "Input";
#import "Hash_Table";
#import "Math";

#load "state.jai";
#load "entity.jai";
#load "components/component.jai";
#load "components/collision_body.jai";
#load "components/transform.jai";
#load "components/ball_body.jai";
#load "components/game_input.jai";
#load "immediate.jai";
#load "collision.jai";
#load "physics.jai";

window_width :: 1280;
window_height :: 768;

TICK_DURATION :: 1.0 / 120.0;
GRAVITY :: 1000;

main :: () {
  window := Window_Creation.create_window(window_name="Fetch", width=window_width, height=window_height);
  Simp.simp_init(window, window_width, window_height, window_width, window_height);

  state: State;
  init(*state);
  defer deinit(*state);

  state.camera_transform.translation.x = window_width / 2;
  state.camera_transform.translation.y = window_height / 2;

  left_wall := add_entity(*state);
  left_wall_transform := add_component(
    *state,
    left_wall,
    Transform,
    .{.{-505, 0}}
  );
  left_wall_obstacle_body := add_component(
    *state,
    left_wall,
    CollisionBody,
    .{.{10, 500}, .{}}
  );

  floor := add_entity(*state);
  floor_transform := add_component(
    *state,
    floor,
    Transform,
    .{.{0, -245}}
  );
  floor_obstacle_body := add_component(
    *state,
    floor,
    CollisionBody,
    .{.{1000, 10}, .{}}
  );


  right_wall := add_entity(*state);
  right_wall_transform := add_component(
    *state,
    right_wall,
    Transform,
    .{.{505, 0}}
  );
  right_wall_obstacle_body := add_component(
    *state,
    right_wall,
    CollisionBody,
    .{.{10, 500}, .{}}
  );

  ball := add_entity(*state);
  ball_transform := add_component(
    *state,
    ball,
    Transform,
    .{}
  );
  ball_collision_body := add_component(
    *state,
    ball,
    CollisionBody,
    .{aabb=.{20, 20}}
  );
  ball_ball_body := add_component(
    *state,
    ball,
    BallBody,
    .{}
  );

  last_clock_tick := get_time();
  while !state.game_input.should_quit_game {
    current_time := get_time();
    current_tick_duration := TICK_DURATION;
    if last_clock_tick + current_tick_duration > current_time {
      continue;
    } else {
      current_tick_duration += TICK_DURATION;
      while last_clock_tick + current_tick_duration <= current_time {
        current_tick_duration += TICK_DURATION;
      }
      last_clock_tick += current_tick_duration;
    }

    input(window, *state);
    simulate(*state, current_tick_duration);
    render(window, state);
    reset_temporary_storage();
  }
}

input :: (window: $Window, using state: *State) {
  {
    Input.update_window_events();
    for event: Input.events_this_frame {
      if event.type == {
        case .QUIT;
          game_input.should_quit_game = true;
        case .KEYBOARD;
          if event.key_code == .MOUSE_BUTTON_LEFT {
            game_input.mouse_is_down = xx event.key_pressed;
          }
      }
    }
    mouse_position_x, mouse_position_y := Window_Creation.get_mouse_pointer_position(window, true);
    gamespace_mouse_position_x := -camera_transform.translation.x + mouse_position_x; 
    gamespace_mouse_position_y := -camera_transform.translation.y + mouse_position_y;
    game_input.mouse_position = make_vector2(gamespace_mouse_position_x, gamespace_mouse_position_y);
  }
}

simulate :: (state: *State, dt: float) {
  for * collision_body: state.collision_bodies {
    transform := find_transform_by_entity_id(<<state, collision_body.entity_id);
    update_collision_body_edges(collision_body, transform);
  }
  
  for * ball_body : state.ball_bodies {
    ball_transform := find_transform_by_entity_id(<<state, ball_body.entity_id);
    ball_collision_body := find_collision_body_by_entity_id(<<state, ball_body.entity_id);

    if state.game_input.mouse_is_down {
      ball_body.velocity.x = 0.5 * (state.game_input.mouse_position.x - ball_transform.translation.x) / TICK_DURATION;
      ball_body.velocity.y = 0.5 * (state.game_input.mouse_position.y - ball_transform.translation.y) / TICK_DURATION;

      ball_transform.translation.x = state.game_input.mouse_position.x;
      ball_transform.translation.y = state.game_input.mouse_position.y;
    } else {
      update_ball_body_translation_after_freefall(
        ball_body,
        ball_transform,
        ball_collision_body,
        dt
      );
      update_ball_body_collisions(
        ball_body,
        ball_transform,
        ball_collision_body,
        state.collision_bodies
      );
      update_nearest_collision(ball_body);
      update_transform_due_to_physics(ball_body, ball_transform);
    }
  }
}

render :: (window: $Window, using state: State) {
  Simp.update_window(window, window_width, window_height, window_width, window_height);
  Simp.clear_render_target(.2, .3, .3, 1);
  
  Simp.set_shader_for_color();
  for collision_body: collision_bodies {
    ball_body := find_ball_body_by_entity_id(state, collision_body.entity_id);
    if ball_body then continue;

    transform := find_transform_by_entity_id(state, collision_body.entity_id);
    Simp.immediate_quad(
      camera_transform.translation.x + transform.translation.x - collision_body.aabb.width / 2,
      camera_transform.translation.y + transform.translation.y - collision_body.aabb.height / 2,
      camera_transform.translation.x + transform.translation.x + collision_body.aabb.width / 2,
      camera_transform.translation.y + transform.translation.y + collision_body.aabb.height / 2,
      .{0, 1, 0, 1}
    );
  }
  for ball_body: ball_bodies {
    transform := find_transform_by_entity_id(state, ball_body.entity_id);
    immediate_circle(transform.translation + camera_transform.translation, 10, .{1, 1, 1, 1}, 7);
  }

  Simp.swap_buffers(window);
}
