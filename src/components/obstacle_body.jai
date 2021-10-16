ObstacleBody :: Component(
  struct {
    using aabb: AABB;
    edges: AABBEdges;
  }
);

update_obstacle_body_edges :: (using obstacle_body: *ObstacleBody, transform: *Transform) {
  current_aabb_edges_input: AABBEdgesInput;
  current_aabb_edges_input.position_absolute = transform.translation;
  current_aabb_edges_input.aabb = obstacle_body.aabb;

  if current_aabb_edges_input == obstacle_body.edges.aabb_edges_input {
    return;
  }

  {
    using edges;
    aabb_edges_input = current_aabb_edges_input;
    
    max_y := transform.translation.y + aabb.height / 2;
    max_x := transform.translation.x + aabb.width / 2;
    min_y := transform.translation.y - aabb.height / 2;
    min_x := transform.translation.x - aabb.width / 2;

    top_edge.y = max_y;
    top_edge.min_x = min_x;
    top_edge.max_x = max_x;

    right_edge.x = max_x;
    right_edge.min_y = min_y;
    right_edge.max_y = max_y;

    bottom_edge.y = min_y;
    bottom_edge.min_x = min_x;
    bottom_edge.max_x = max_x;

    left_edge.x = min_x;
    left_edge.min_y = min_y;
    left_edge.max_y = max_y;
  }
}
