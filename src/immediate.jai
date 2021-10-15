immediate_circle :: (center: Vector2, radius: float, color: Vector4, detail := 12) {
  d_theta := TAU / detail;
  initial_x := radius + center.x;
  initiial_y := center.y;

  center_vector3 := make_vector3(center.x, center.y, 0);
  previous_point := make_vector3(initial_x, initiial_y, 0);
  for segment_index: 1..detail {

    current_theta := d_theta * segment_index;

    current_x := cos(current_theta) * radius + center.x;
    current_y := sin(current_theta) * radius + center.y;

    current_point := make_vector3(current_x, current_y, 0);

    first_vertex_index := segment_index * 3;
    Simp.immediate_triangle(
      previous_point, center_vector3, current_point,
      color, color, color
    );
    previous_point = current_point;
  }
}
