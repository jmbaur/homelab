use std::{
    cell::{Ref, RefCell},
    rc::Rc,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
    time::Duration,
};

use anyhow::Context;
use chrono::{DateTime, Local};
use dbus::{arg::RefArg, blocking::LocalConnection, Message};
use serde::{Deserialize, Serialize};
use serde_json::json;
use signal_hook::{
    consts::{SIGUSR1, SIGUSR2},
    iterator::Signals,
};

mod networkd_manager {
    #![allow(non_upper_case_globals)]
    #![allow(non_camel_case_types)]
    #![allow(non_snake_case)]
    #![allow(unused)]
    include!(concat!(env!("OUT_DIR"), "/networkd_manager.rs"));
}

mod timedate {
    #![allow(non_upper_case_globals)]
    #![allow(non_camel_case_types)]
    #![allow(non_snake_case)]
    #![allow(unused)]
    include!(concat!(env!("OUT_DIR"), "/timedate.rs"));
}

mod upower_device {
    #![allow(non_upper_case_globals)]
    #![allow(non_camel_case_types)]
    #![allow(non_snake_case)]
    #![allow(unused)]
    include!(concat!(env!("OUT_DIR"), "/upower_device.rs"));
}

use networkd_manager::OrgFreedesktopNetwork1Manager;
use timedate::OrgFreedesktopTimedate1;
use upower_device::OrgFreedesktopUPowerDevice;

use crate::networkd_manager::OrgFreedesktopDBusPropertiesPropertiesChanged;

#[derive(Serialize, Deserialize)]
struct I3header {
    version: u8,
    stop_signal: i32,
    cont_signal: i32,
    click_events: bool,
}

#[derive(Serialize, Deserialize)]
struct Bar(Vec<Block>);

#[derive(Serialize, Deserialize)]
struct Block {
    full_text: String,
    urgent: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    instance: Option<String>,
}

struct TimedateState {
    timezone: String,
}

impl Default for TimedateState {
    fn default() -> Self {
        Self {
            timezone: "UTC".to_string(),
        }
    }
}

impl From<Ref<'_, TimedateState>> for Block {
    fn from(value: Ref<'_, TimedateState>) -> Self {
        let local: DateTime<Local> = Local::now();
        Block {
            full_text: format!("{} {}", local.format("%Y-%m-%d %H:%M:%S"), value.timezone),
            urgent: false,
            name: None,
            instance: None,
        }
    }
}

struct NetworkState {
    online_state: String,
}

impl Default for NetworkState {
    fn default() -> Self {
        Self {
            online_state: "offline".to_string(),
        }
    }
}

impl From<Ref<'_, NetworkState>> for Block {
    fn from(value: Ref<'_, NetworkState>) -> Self {
        Block {
            full_text: format!("network: {}", value.online_state),
            urgent: value.online_state == "offline",
            name: None,
            instance: None,
        }
    }
}

#[derive(Default, PartialEq, Eq)]
enum PowerStatus {
    #[default]
    Unknown,
    Charging,
    Discharging,
    Empty,
    FullyCharged,
    PendingCharge,
    PendingDischarge,
}

#[derive(Default)]
enum PowerDeviceType {
    #[default]
    Unknown,
    LinePower,
    Battery,
    Ups,
    Monitor,
    Mouse,
    Keyboard,
    Pda,
    Phone,
    MediaPlayer,
    Tablet,
    Computer,
    GamingInput,
    Pen,
    Touchpad,
    Modem,
    Network,
    Headset,
    Speakers,
    Headphones,
    Video,
    OtherAudio,
    RemoteControl,
    Printer,
    Scanner,
    Camera,
    Wearable,
    Toy,
    BluetoothGenreic,
}

impl From<u32> for PowerDeviceType {
    fn from(value: u32) -> Self {
        use PowerDeviceType::*;
        match value {
            1 => LinePower,
            2 => Battery,
            3 => Ups,
            4 => Monitor,
            5 => Mouse,
            6 => Keyboard,
            7 => Pda,
            8 => Phone,
            9 => MediaPlayer,
            10 => Tablet,
            11 => Computer,
            12 => GamingInput,
            13 => Pen,
            14 => Touchpad,
            15 => Modem,
            16 => Network,
            17 => Headset,
            18 => Speakers,
            19 => Headphones,
            20 => Video,
            21 => OtherAudio,
            22 => RemoteControl,
            23 => Printer,
            24 => Scanner,
            25 => Camera,
            26 => Wearable,
            27 => Toy,
            28 => BluetoothGenreic,
            _ => Unknown,
        }
    }
}

impl std::fmt::Display for PowerDeviceType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        use PowerDeviceType::*;
        write!(
            f,
            "{}",
            match self {
                Unknown => "unknown",
                LinePower => "line power",
                Battery => "battery",
                Ups => "ups",
                Monitor => "monitor",
                Mouse => "mouse",
                Keyboard => "keyboard",
                Pda => "pda",
                Phone => "phone",
                MediaPlayer => "media player",
                Tablet => "tablet",
                Computer => "computer",
                GamingInput => "gaming input",
                Pen => "pen",
                Touchpad => "touchpad",
                Modem => "modem",
                Network => "network",
                Headset => "headset",
                Speakers => "speakers",
                Headphones => "headphones",
                Video => "video",
                OtherAudio => "otheraudio",
                RemoteControl => "remote control",
                Printer => "printer",
                Scanner => "scanner",
                Camera => "camera",
                Wearable => "wearable",
                Toy => "toy",
                BluetoothGenreic => "bluetooth genreic",
            }
        )
    }
}

#[derive(Default, PartialEq, Eq)]
enum PowerWarningLevel {
    #[default]
    Unknown,
    None,
    Discharging,
    Low,
    Critical,
    Action,
}

impl From<u32> for PowerWarningLevel {
    fn from(value: u32) -> Self {
        use PowerWarningLevel::*;
        match value {
            1 => None,
            2 => Discharging,
            3 => Low,
            4 => Critical,
            5 => Action,
            _ => Unknown,
        }
    }
}

#[derive(Default)]
struct PowerState {
    battery_percentage: f64,
    warning_level: PowerWarningLevel,
    status: PowerStatus,
    device_type: PowerDeviceType,
}

impl From<u32> for PowerStatus {
    fn from(value: u32) -> Self {
        use PowerStatus::*;
        match value {
            1 => Charging,
            2 => Discharging,
            3 => Empty,
            4 => FullyCharged,
            5 => PendingCharge,
            6 => PendingDischarge,
            _ => Unknown,
        }
    }
}

impl std::fmt::Display for PowerStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        use PowerStatus::*;
        write!(
            f,
            "{}",
            match self {
                Unknown => "unknown",
                Charging => "charging",
                Discharging => "discharging",
                Empty => "empty",
                FullyCharged => "full",
                PendingCharge | PendingDischarge => "pending",
            }
        )
    }
}

impl From<Ref<'_, PowerState>> for Block {
    fn from(value: Ref<'_, PowerState>) -> Self {
        Block {
            full_text: if matches!(
                value.status,
                PowerStatus::Charging | PowerStatus::Discharging
            ) {
                format!(
                    "{}: {} {}%",
                    value.device_type, value.status, value.battery_percentage
                )
            } else {
                format!("{}: {}%", value.device_type, value.battery_percentage)
            },
            urgent: matches!(
                value.warning_level,
                PowerWarningLevel::Critical | PowerWarningLevel::Action
            ),
            name: None,
            instance: None,
        }
    }
}

fn main() -> anyhow::Result<()> {
    let header = I3header {
        version: 1,
        stop_signal: SIGUSR1,
        cont_signal: SIGUSR2,
        click_events: false,
    };

    let stop = Arc::new(AtomicBool::new(false));
    _ = signal_hook::flag::register(SIGUSR1, Arc::clone(&stop));

    let mut cont = Signals::new([SIGUSR2]).context("Failed to make signals iterator")?;
    let mut cont_iter = cont.forever();

    let conn = LocalConnection::new_system().context("Failed to open dbus connection")?;

    let network_state = Rc::new(RefCell::new(NetworkState::default()));

    let networkd = conn.with_proxy(
        "org.freedesktop.network1",
        "/org/freedesktop/network1",
        Duration::from_millis(5000),
    );

    network_state.borrow_mut().online_state = networkd
        .online_state()
        .context("Failed to get OnlineState")?;

    let _network_state = network_state.clone();
    _ = networkd
        .match_signal(
            move |mut signal: OrgFreedesktopDBusPropertiesPropertiesChanged,
                  _: &LocalConnection,
                  _: &Message| {
                if let Some(Some(online_state)) = signal
                    .changed_properties
                    .remove("OnlineState")
                    .map(|variant| variant.as_str().map(|s| s.to_string()))
                {
                    _network_state.borrow_mut().online_state = online_state;
                }
                true
            },
        )
        .context("Failed to add signal match on networkd properties changed")?;

    let timedate_state = Rc::new(RefCell::new(TimedateState::default()));

    let timedated = conn.with_proxy(
        "org.freedesktop.timedate1",
        "/org/freedesktop/timedate1",
        Duration::from_millis(5000),
    );

    timedate_state.borrow_mut().timezone =
        timedated.timezone().context("Failed to get timezone")?;
    let _timedate_state = timedate_state.clone();
    _ = timedated
        .match_signal(
            move |mut signal: OrgFreedesktopDBusPropertiesPropertiesChanged,
                  _: &LocalConnection,
                  _: &Message| {
                if let Some(Some(timezone)) = signal
                    .changed_properties
                    .remove("Timezone")
                    .map(|variant| variant.as_str().map(|s| s.to_string()))
                {
                    _timedate_state.borrow_mut().timezone = timezone;
                }
                true
            },
        )
        .context("Failed to add signal match on timedated properties changed")?;

    let upower_display_device = conn.with_proxy(
        "org.freedesktop.UPower",
        "/org/freedesktop/UPower/devices/DisplayDevice",
        Duration::from_millis(5000),
    );

    let power_state = Rc::new(RefCell::new(PowerState::default()));

    power_state.borrow_mut().device_type = upower_display_device
        .type_()
        .context("Failed to get display device type")?
        .into();
    power_state.borrow_mut().battery_percentage = upower_display_device
        .percentage()
        .context("Failed to get display device percentage")?;
    power_state.borrow_mut().warning_level = upower_display_device
        .warning_level()
        .context("Failed to get display device warning level")?
        .into();

    power_state.borrow_mut().status = upower_display_device
        .state()
        .context("Failed to get display device power state")?
        .into();

    let _power_state = power_state.clone();
    _ = upower_display_device.match_signal(
        move |mut signal: OrgFreedesktopDBusPropertiesPropertiesChanged,
              _: &LocalConnection,
              _: &Message| {
            if let Some(Some(percentage)) = signal
                .changed_properties
                .remove("Percentage")
                .map(|variant| variant.as_f64())
            {
                _power_state.borrow_mut().battery_percentage = percentage;
            }

            if let Some(Some(Ok(warning_level))) = signal
                .changed_properties
                .remove("WarningLevel")
                .map(|variant| variant.as_u64().map(u32::try_from))
            {
                _power_state.borrow_mut().warning_level = warning_level.into();
            }

            if let Some(Some(Ok(state))) = signal
                .changed_properties
                .remove("State")
                .map(|variant| variant.as_u64().map(u32::try_from))
            {
                _power_state.borrow_mut().status = state.into();
            }

            true
        },
    );

    println!("{}", json!(header));
    println!("[");
    loop {
        if stop.load(Ordering::Relaxed) {
            // Block until we receive the indication we should continue.
            _ = cont_iter.next().context("Failed to receive next signal")?;
            stop.store(false, Ordering::SeqCst);
        }

        _ = conn
            .process(Duration::from_millis(1000))
            .context("Failed to process dbus messsages")?;

        let mut blocks = Vec::new();
        blocks.push(power_state.borrow().into());
        blocks.push(network_state.borrow().into());
        blocks.push(timedate_state.borrow().into());

        println!("{},", json!(Bar(blocks)));
    }
}
