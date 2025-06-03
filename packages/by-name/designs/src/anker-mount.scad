// Din rail mount for the Anker 7-port USB hub (with standoffs, not included) to
// be mounted on a pair of generic din rail adapters, DigiKey part #277-2296-ND.

tolerance = 0.001;

inside_tolerance = 0.5;

screw_radius_tolerance = 0.3;

mount_screw_radius = (3 /* m3 screw (self-taps into din rail mount) */ / 2) +
                     screw_radius_tolerance;

thickness = 3;

mount_screw_distance = 25;

x = 15;
y_bottom = 45.5 + inside_tolerance;
y_top = 44.1 + inside_tolerance;
z = 23;

overhang_length = 4;

module hole(r, x, y_bottom) {
  translate([ x, y_bottom, -((z + thickness) / 2) ])
      linear_extrude(thickness + tolerance, center = true)
          circle(r = r, $fn = 360);
}

// https://github.com/openscad/MCAD/blob/master/triangles.scad
module triangle(o_len, a_len, depth, center = false) {
  centroid = center ? [ -a_len / 3, -o_len / 3, -depth / 2 ] : [ 0, 0, 0 ];
  translate(centroid) linear_extrude(height = depth) {
    polygon(points = [ [ 0, 0 ], [ a_len, 0 ], [ 0, o_len ] ],
            paths = [[ 0, 1, 2 ]]);
  }
}

union() {
  difference() {
    // outer
    cube([ x, y_bottom + (2 * thickness), z + (2 * thickness) ], center = true);

    // bottom inner
    cube(
        [
          x + tolerance,
          y_bottom,
          z + (2 * tolerance),
        ],
        center = true);

    // top inner
    translate([ 0, 0, (z + thickness) / 2 ]) cube(
        [
          x + tolerance,
          y_bottom - (2 * overhang_length),
          thickness + tolerance,
        ],
        center = true);

    // mount screws
    hole(r = mount_screw_radius, x = 0, y_bottom = mount_screw_distance / 2);
    hole(r = mount_screw_radius, x = 0, y_bottom = -(mount_screw_distance / 2));
  }

  // Handle the slight difference in width of the top vs. bottom of the hub.
  // TODO(jared): These translations are nasty, just some magic numbers that we
  // should figure out how to parametrize properly.
  translate([ 0, ((y_bottom - 0.47) / 2), 3.84 ]) rotate([ 180, 90, 0 ])
      triangle((y_bottom - y_top) / 2, z, x, center = true);

  translate([ 0, -((y_bottom - 0.47) / 2), 3.84 ]) rotate([ 0, 90, 0 ])
      triangle((y_bottom - y_top) / 2, z, x, center = true);
}
