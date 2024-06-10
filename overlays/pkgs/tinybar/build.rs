use std::io::Write;

fn code_for_dbus_xml(xml: impl AsRef<std::path::Path>) -> String {
    dbus_codegen::generate(
        &std::fs::read_to_string(xml).unwrap(),
        &dbus_codegen::GenOpts {
            methodtype: None,
            connectiontype: dbus_codegen::ConnectionType::Blocking,
            ..Default::default()
        },
    )
    .unwrap()
}

fn main() {
    let out_path = std::path::PathBuf::from(std::env::var("OUT_DIR").unwrap());

    let systemd_dbus_interface_dir = std::env::var("SYSTEMD_DBUS_INTERFACE_DIR").unwrap();
    let systemd_dbus_interface_dir = std::path::Path::new(systemd_dbus_interface_dir.as_str());

    let networkd_manager_code =
        code_for_dbus_xml(systemd_dbus_interface_dir.join("org.freedesktop.network1.Manager.xml"));
    let mut file = std::fs::File::create(out_path.join("networkd_manager.rs")).unwrap();
    file.write_all(networkd_manager_code.as_bytes()).unwrap();

    let timedate_code =
        code_for_dbus_xml(systemd_dbus_interface_dir.join("org.freedesktop.timedate1.xml"));
    let mut file = std::fs::File::create(out_path.join("timedate.rs")).unwrap();
    file.write_all(timedate_code.as_bytes()).unwrap();

    let upower_dbus_interface_dir = std::env::var("UPOWER_DBUS_INTERFACE_DIR").unwrap();
    let upower_dbus_interface_dir = std::path::Path::new(upower_dbus_interface_dir.as_str());

    let upower_device_code =
        code_for_dbus_xml(upower_dbus_interface_dir.join("org.freedesktop.UPower.Device.xml"));
    let mut file = std::fs::File::create(out_path.join("upower_device.rs")).unwrap();
    file.write_all(upower_device_code.as_bytes()).unwrap();
}
