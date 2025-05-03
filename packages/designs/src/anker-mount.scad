// Din rail mount for the Anker 7-port USB hub (with standoffs, not included) to
// be mounted on a pair of generic din rail adapters, DigiKey part #277-2296-ND.

tolerance = 0.5;

x = 111;
y = 45;
z = 24;

thickness = 3;

mount_screw_radius =
    3 /* m3 screw (self-taps into din rail mount) */ / 2 + tolerance;

off = 5; // offset from side

mount_screw_distance = 25;

mount1_1_x = 0;
mount1_1_y = 1 * (y / 4);
mount1_2_x = mount1_1_x + mount_screw_distance;
mount1_2_y = mount1_1_y;

mount2_1_x = 0;
mount2_1_y = 3 * (y / 4);
mount2_2_x = mount2_1_x + mount_screw_distance;
mount2_2_y = mount2_1_y;

module hole(r, x, y) {
  translate([ x, y, -tolerance ]) linear_extrude(z + 2 * tolerance)
      circle(r = r, $fn = 360);
}

difference() {
  // outer
  cube([
    x + thickness + tolerance,
    y + thickness + tolerance,
    z + thickness + tolerance,
  ]);

  // inner
  translate([ -tolerance, thickness, thickness ]) cube([
    x + tolerance,
    y - thickness + tolerance,
    z + thickness,
  ]);

  // mount screws
  hole(r = mount_screw_radius, x = mount1_1_x + 2 * off, y = mount1_1_y + off);
  hole(r = mount_screw_radius, x = mount1_2_x + 2 * off, y = mount1_2_y + off);
  hole(r = mount_screw_radius, x = mount2_1_x + 2 * off, y = mount2_1_y);
  hole(r = mount_screw_radius, x = mount2_2_x + 2 * off, y = mount2_2_y);
};

wing_length = 4;

// top wings
difference() {
  translate([ 0, 0, z + thickness + tolerance ]) cube([
    x + thickness + tolerance,
    y + thickness + tolerance,
    thickness,
  ]);

  translate([ -tolerance, thickness * 2, z + thickness ]) cube([
    x + tolerance - thickness,
    y - 3 * thickness + tolerance,
    thickness + (2*tolerance),
  ]);
};
