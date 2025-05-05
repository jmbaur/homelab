// Din rail mount for the OrangePi 5 (with standside_offsets, not included) to
// be mounted on a pair of generic din rail adapters, DigiKey part #277-2296-ND.

tolerance = 0.001;

// m2 screw
board_screw_radius = 1;

// m3 screw (self-taps into din rail mount)
mount_screw_radius = 1.5;

x = 100;
y = 60;
z = 3;
side_offset = 5; // offset from side

mount_screw_distance = 25;

module hole(r, x, y) {
  translate([ x, y, -tolerance / 2 ])
      linear_extrude(z + 2 * tolerance, center = true) circle(r = r, $fn = 360);
}

difference() {
  cube([ x + (2 * side_offset), y + 2 * side_offset, z ], center = true);

  // board screws
  hole(r = board_screw_radius, x = x / 2 - side_offset,
       y = y / 2 - side_offset);
  hole(r = board_screw_radius, x = -x / 2 + side_offset,
       y = y / 2 - side_offset);
  hole(r = board_screw_radius, x = x / 2 - side_offset,
       y = -y / 2 + side_offset);
  hole(r = board_screw_radius, x = -x / 2 + side_offset,
       y = -y / 2 + side_offset);

  // mount screws
  hole(r = mount_screw_radius, x = 0 - mount_screw_distance / 2, y = y / 4);
  hole(r = mount_screw_radius, x = 0 + mount_screw_distance / 2, y = y / 4);
  hole(r = mount_screw_radius, x = 0 - mount_screw_distance / 2, y = -y / 4);
  hole(r = mount_screw_radius, x = 0 + mount_screw_distance / 2, y = -y / 4);
}
