BallBody :: Component(
  struct {
    velocity: Vector2;
    translation_after_freefall: Vector2;
    collisions: []Collision;
    nearest_collision: *Collision;
  }
);

update_ball_body_translation_after_freefall :: (
  using ball_body: *BallBody,
  transform: *Transform,
  collision_body: *CollisionBody,
  dt: float
) {
  frame_start_velocity_y := ball_body.velocity.y;
  frame_end_velocity_y := frame_start_velocity_y - dt * GRAVITY;

  effective_velocity_y := (frame_start_velocity_y + frame_end_velocity_y) / 2.0;

  translation_after_freefall.x = transform.translation.x + dt * ball_body.velocity.x;
  translation_after_freefall.y = transform.translation.y + dt * effective_velocity_y;

  ball_body.velocity.y = frame_end_velocity_y;
}

update_ball_body_collisions :: (
  using ball_body: *BallBody,
  transform: *Transform,
  collision_body: *CollisionBody,
  all_collision_bodies: []CollisionBody
) {
  using collision_body.edges;

  updated_collisions: [..]Collision;
  updated_collisions.allocator = __temporary_allocator;
  updated_collisions.allocator_data = null;

  for * other_collision_body: all_collision_bodies {
    if other_collision_body == collision_body then continue;

    x_distance := translation_after_freefall.x - transform.translation.x;
    y_distance := translation_after_freefall.y - transform.translation.y;
    total_distance := sqrt(x_distance * x_distance + y_distance * y_distance);

    if velocity.y > 0 {
      if
        top_edge.y <= other_collision_body.edges.bottom_edge.y &&
        top_edge.y + y_distance >= other_collision_body.edges.bottom_edge.y &&
        top_edge.min_x < other_collision_body.edges.bottom_edge.max_x &&
        top_edge.max_x > other_collision_body.edges.bottom_edge.min_x
      {
        collision := array_add(*updated_collisions);

        y_distance_traveled := other_collision_body.edges.bottom_edge.y - top_edge.y;
        proportional_distance_traveled := y_distance_traveled / y_distance;

        collision.normal = .DOWN;
        collision.distance_traveled = total_distance * proportional_distance_traveled;
      }
    } else if velocity.y < 0 {
      if
        bottom_edge.y >= other_collision_body.edges.top_edge.y &&
        bottom_edge.y + y_distance <= other_collision_body.edges.top_edge.y &&
        bottom_edge.min_x < other_collision_body.edges.top_edge.max_x &&
        bottom_edge.max_x > other_collision_body.edges.top_edge.min_x
      {
        collision := array_add(*updated_collisions);

        y_distance_traveled := other_collision_body.edges.top_edge.y - bottom_edge.y;
        proportional_distance_traveled := y_distance_traveled / y_distance;

        collision.normal = .UP;
        collision.distance_traveled = total_distance * proportional_distance_traveled;
      }
    }

    if velocity.x > 0 {
      if
        right_edge.x <= other_collision_body.edges.left_edge.x &&
        right_edge.x + x_distance >= other_collision_body.edges.left_edge.x &&
        right_edge.min_y < other_collision_body.edges.left_edge.max_y &&
        right_edge.max_y > other_collision_body.edges.left_edge.min_y
      {
        collision := array_add(*updated_collisions);

        x_distance_traveled := other_collision_body.edges.left_edge.x - right_edge.x;
        proportional_distance_traveled := x_distance_traveled / x_distance;

        collision.normal = .LEFT;
        collision.distance_traveled = total_distance * proportional_distance_traveled;
      }
    } else if velocity.x < 0 {
      if
        left_edge.x >= other_collision_body.edges.right_edge.x &&
        left_edge.x + x_distance <= other_collision_body.edges.right_edge.x &&
        left_edge.min_y < other_collision_body.edges.right_edge.max_y &&
        left_edge.max_y > other_collision_body.edges.right_edge.min_y
      {
        collision := array_add(*updated_collisions);

        x_distance_traveled := other_collision_body.edges.right_edge.x - left_edge.x;
        proportional_distance_traveled := x_distance_traveled / x_distance;

        collision.normal = .RIGHT;
        collision.distance_traveled = total_distance * proportional_distance_traveled;
      }
    }

    collisions = updated_collisions;
  }
}

update_nearest_collision :: (using ball_body: *BallBody) {
  ball_body.nearest_collision = null;
  for * collision: ball_body.collisions {
    if
      !ball_body.nearest_collision ||
      collision.distance_traveled < ball_body.nearest_collision.distance_traveled
    {
      ball_body.nearest_collision = collision;
    }
  }
}

update_transform_due_to_physics :: (using ball_body: *BallBody, transform: *Transform) {
  if ball_body.nearest_collision {
    freefall_dx := ball_body.translation_after_freefall.x - transform.translation.x;
    freefall_dy := ball_body.translation_after_freefall.y - transform.translation.y;

    freefall_distance_traveled := sqrt(
      ball_body.translation_after_freefall.x * ball_body.translation_after_freefall.x +
      ball_body.translation_after_freefall.y * ball_body.translation_after_freefall.y
    );


    proportional_distance_traveled := ball_body.nearest_collision.distance_traveled / freefall_distance_traveled;
    if #complete ball_body.nearest_collision.normal == {
      case .UP; case .DOWN;
        ball_body.velocity.y = 0;
        
        transform.translation.x = ball_body.translation_after_freefall.x;

        actual_dy := proportional_distance_traveled * freefall_dy;
        transform.translation.y += actual_dy;
      case .LEFT; case .RIGHT;
        ball_body.velocity.x = 0;
        
        actual_dx := proportional_distance_traveled * freefall_dx;
        transform.translation.x += actual_dx;

        transform.translation.y = ball_body.translation_after_freefall.y;
    }
  } else {
    transform.translation = ball_body.translation_after_freefall;
  }
}
