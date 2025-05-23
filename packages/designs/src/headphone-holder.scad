tolerance = 0.001;

screw_distance = 72;
screw_radius_tolerance = 0.5;
screw_radius = 6 /* m6 screw size */ / 2 + screw_radius_tolerance;

thickness = 3;

mount_plate_x = 90;
mount_plate_y = 40;

holder_plate_x = 40;
holder_plate_y = 100;
holder_plate_z_translate = holder_plate_y / 2;

holder_radius = holder_plate_x / 2 + 2;
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
    cylinder(h = thickness / 2, r = 2, center = true);
  }

  translate([ 0, -20 + thickness / 2, 20 + thickness / 2 ]) rotate([ 90, 0, 0 ])
      cube([ 40, 40, thickness ], center = true);

  hole(screw_radius, -screw_distance / 2, 0, 0);
  hole(screw_radius, screw_distance / 2, 0, 0);
}

translate([
  -mount_plate_x + holder_radius / 2 + holder_length / 2 - thickness * 1.5, 0, 0
]) rotate([ 0, 0, 90 ]) union() {
  difference() {
    minkowski() {
      translate(
          [ 0, -mount_plate_y / 2 + thickness / 4, holder_plate_z_translate ])
          rotate([ 90, 0, 0 ]) cube(
              [ holder_plate_x, holder_plate_y, thickness / 2 ], center = true);
      cylinder(h = thickness / 2, r = 2, center = true);
    }

    translate([ 0, -mount_plate_y / 2 + thickness / 4, holder_z_translate ])
        rotate([ 90, 0, 0 ])
            linear_extrude(height = 2 * thickness, center = true)
                circle(r = holder_radius);

    minkowski() {
      translate([
        0, -mount_plate_y / 2 + thickness / 4,
        holder_z_translate + holder_plate_y / 2
      ]) rotate([ 90, 0, 0 ])
          cube([ holder_plate_x, holder_plate_y, thickness / 2 ],
               center = true);
      cylinder(h = thickness / 2, r = 2 + tolerance, center = true);
    }
  }

  translate(
      [ 0, -mount_plate_y / 2 - 2 / 4, holder_z_translate / 2 - thickness / 4 ])
      rotate([ 90, 0, 0 ])
          cube([ holder_plate_x + 2 * 2, holder_z_translate, thickness ],
               center = true);

  hull() {
    translate([ 0, thickness / 2 - thickness / 2 - 2, holder_z_translate ])
        rotate([ 90, 0, 0 ])
            linear_extrude(height = holder_length, center = true)
                circle(r = holder_radius);

    translate([ 0, holder_length / 2 - thickness / 2 - 2, holder_z_translate ])
        sphere(r = holder_radius);
  }
}
