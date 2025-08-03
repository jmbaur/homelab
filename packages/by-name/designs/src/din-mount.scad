// Module to make din-rail mount for any board size, to be mounted on a pair of
// generic din rail adapters (DigiKey part #277-2296-ND).

tolerance = 0.001;

module hole(r, x, y, z) {
  translate([ x, y, -tolerance / 2 ])
      linear_extrude(z + 2 * tolerance, center = true) circle(r = r, $fn = 360);
}

module din_mount(board_screw_radius, x, y) {
  screw_radius_tolerance = 0.3;

  board_screw_radius = board_screw_radius + screw_radius_tolerance;

  // m3 screw (self-taps into din rail mount)
  mount_screw_radius = 1.5 + screw_radius_tolerance;

  z = 3;
  side_offset = 5; // offset from side

  mount_screw_distance = 25;

  $fn = 100;

  difference() {
    minkowski() {
      cube([ x + (2 * side_offset), y + 2 * side_offset, z / 2 ],
           center = true);
      cylinder(h = z / 2, r = 2, center = true);
    }

    // board screws
    hole(r = board_screw_radius, x = x / 2 - side_offset,
         y = y / 2 - side_offset, z);
    hole(r = board_screw_radius, x = -x / 2 + side_offset,
         y = y / 2 - side_offset, z);
    hole(r = board_screw_radius, x = x / 2 - side_offset,
         y = -y / 2 + side_offset, z);
    hole(r = board_screw_radius, x = -x / 2 + side_offset,
         y = -y / 2 + side_offset, z);

    // mount screws
    hole(r = mount_screw_radius, x = 0 - mount_screw_distance / 2, y = y / 4, z);
    hole(r = mount_screw_radius, x = 0 + mount_screw_distance / 2, y = y / 4, z);
    hole(r = mount_screw_radius, x = 0 - mount_screw_distance / 2, y = -y / 4, z);
    hole(r = mount_screw_radius, x = 0 + mount_screw_distance / 2, y = -y / 4, z);
  }
}
