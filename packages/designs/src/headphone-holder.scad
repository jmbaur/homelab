tolerance = 0.001;

screw_distance = 70;
screw_radius_tolerance = 0.5;
screw_radius = 5 /* m5 screw size */ / 2 + screw_radius_tolerance;

thickness = 5;

mount_plate_x = 100;
mount_plate_y = 40;

holder_plate_x = 50;
holder_plate_y = 70;
holder_plate_z_translate = holder_plate_y / 2 + thickness / 2;

holder_radius = 20;
holder_length = mount_plate_y;
holder_z_translate = holder_plate_z_translate + 10;

$fn = 100;

module hole(r, x, y, z) {
  translate([ x, y, z ])
      linear_extrude(2 * thickness + tolerance, center = true) circle(r = r);
}

difference() {
  minkowski() {
    cube([ mount_plate_x, mount_plate_y, thickness / 2 ], center = true);
    sphere(r = 2);
  }

  translate([ 0, -20 + thickness / 2, 20 + thickness / 2 ]) rotate([ 90, 0, 0 ])
      cube([ 40, 40, thickness ], center = true);

  hole(screw_radius, -screw_distance / 2, 0, 0);
  hole(screw_radius, screw_distance / 2, 0, 0);
}

minkowski() {
  translate([ 0, -mount_plate_y / 2 + thickness / 2, holder_plate_z_translate ])
      rotate([ 90, 0, 0 ]) cube(
          [ holder_plate_x, holder_plate_y, thickness / 2 ], center = true);
  sphere(r = 1);
}

hull() {
  translate([ 0, thickness / 2, holder_z_translate ]) rotate([ 90, 0, 0 ])
      linear_extrude(height = holder_length, center = true)
          circle(r = holder_radius);

  translate([ 0, holder_length / 2, holder_z_translate ])
      sphere(r = holder_radius);
}
