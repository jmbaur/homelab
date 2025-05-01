// Din rail mount for the orange pi 5 (with standoffs, not included) to be
// mounted on a pair of generic din rail adapters, DigiKey part #277-2296-ND.

tolerance = 0.5;

board_screw_radius = 1 /* m2 screw */ + tolerance;

mount_screw_radius = 3 /* m3 screw (self-taps into din rail mount) */ / 2 + tolerance;

x = 100;
y = 60;
z = 4;
off = 5;

mount_screw_distance = 25;

mount1_1_x = 0;
mount1_1_y = 1*(y / 4);
mount1_2_x = mount1_1_x + mount_screw_distance;
mount1_2_y = mount1_1_y;

mount2_1_x = 0;
mount2_1_y = 3*(y / 4);
mount2_2_x = mount2_1_x + mount_screw_distance;
mount2_2_y = mount2_1_y;

module hole(r, x, y) {
	translate([x, y, -tolerance]) linear_extrude(z+2*tolerance) circle(r=r, $fn=360);
}

difference() {
	cube([x + off, y + off, z]);

	// board screws
	hole(r=board_screw_radius, x=x, y=y);
	hole(r=board_screw_radius, x=off, y=y);
	hole(r=board_screw_radius, x=x, y=off);
	hole(r=board_screw_radius, x=off, y=off);

	// mount screws
	hole(r=mount_screw_radius, x=mount1_1_x + 2*off, y=mount1_1_y+off);
	hole(r=mount_screw_radius, x=mount1_2_x + 2*off, y=mount1_2_y+off);
	hole(r=mount_screw_radius, x=mount2_1_x + 2*off, y=mount2_1_y);
	hole(r=mount_screw_radius, x=mount2_2_x + 2*off, y=mount2_2_y);
}
