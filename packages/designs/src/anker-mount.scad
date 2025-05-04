// Din rail mount for the Anker 7-port USB hub (with standoffs, not included) to
// be mounted on a pair of generic din rail adapters, DigiKey part #277-2296-ND.

tolerance = 0.5;

mount_screw_radius =
    (3 /* m3 screw (self-taps into din rail mount) */ / 2) + tolerance;

thickness = 3;

mount_screw_distance = 25;

x = mount_screw_radius * 4;
y = 45;
z = 24;

overhang_length = 4;

module hole(r, x, y) {
  translate([ x, y, -((z + thickness + (2 * tolerance)) / 2) ])
      linear_extrude(thickness + tolerance, center = true)
          circle(r = r, $fn = 360);
}

difference() {
  // outer
  cube(
      [
        x, y + (2 * (thickness + tolerance)), z + (2 * (thickness + tolerance))
      ],
      center = true);

  // bottom inner
  cube(
      [
        x + (2 * tolerance),
        y + (2 * tolerance),
        z + (2 * tolerance),
      ],
      center = true);

  // top inner
  translate([ 0, 0, (z + thickness + (2 * tolerance)) / 2 ]) cube(
        [
          x + (2 * tolerance),
          y - (2 * overhang_length),
          thickness + tolerance,
        ],
        center = true);

  // mount screws
  hole(r = mount_screw_radius, x = 0, y = mount_screw_distance / 2);
  hole(r = mount_screw_radius, x = 0, y = -(mount_screw_distance / 2));
}
