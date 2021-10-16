AABB :: struct {
  width: float;
  height: float;
}

AABBEdges :: struct {
  aabb_edges_input: AABBEdgesInput;

  top_edge: HorizontalEdge;
  bottom_edge: HorizontalEdge;

  left_edge: VerticalEdge;
  right_edge: VerticalEdge;
}

AABBEdgesInput :: struct {
  position_absolute: Vector2;
  aabb: AABB;
}

HorizontalEdge :: struct {
  y: float;
  min_x: float;
  max_x: float;
}

VerticalEdge :: struct {
  x: float;
  min_y: float;
  max_y: float;
}

operator == :: (lhs: AABBEdgesInput, rhs: AABBEdgesInput) -> bool {
  return lhs.position_absolute == rhs.position_absolute && lhs.aabb == rhs.aabb;
}

operator == :: (lhs: AABB, rhs: AABB) -> bool {
  return lhs.width == rhs.width && lhs.height == rhs.height;
}
