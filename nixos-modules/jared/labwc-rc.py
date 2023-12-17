#!/usr/bin/env python3

from xml.dom import minidom

root = minidom.Document()


def create_action(name):
    action = root.createElement("action")
    action.setAttribute("name", name)
    return action


def create_show_menu_action(menu_name):
    action = create_action("ShowMenu")
    action.setAttribute("menu", menu_name)
    return action


def create_snap_action(direction):
    action = create_action("SnapToEdge")
    action.setAttribute("direction", direction)
    return action


def create_move_action(direction):
    action = create_action("MoveToEdge")
    action.setAttribute("direction", direction)
    return action


def create_execute_action(command):
    action = create_action("Execute")
    action.setAttribute("command", command)
    return action


def create_desktop_action(name, to):
    to_node = root.createElement("to")
    to_node.appendChild(root.createTextNode(to))
    action = create_action(name)
    action.appendChild(to_node)
    return action


def create_goto_desktop_action(to):
    return create_desktop_action("GoToDesktop", to)


def create_sendto_desktop_action(to):
    return create_desktop_action("SendToDesktop", to)


def create_keybinding(key_binding, action):
    keybind = root.createElement("keybind")
    keybind.setAttribute("key", key_binding)
    keybind.appendChild(action)
    return keybind


keyboard = root.createElement("keyboard")
keyboard.setAttribute("repeatRate", "50")
keyboard.setAttribute("repeatDelay", "300")
keyboard.appendChild(create_keybinding("A-Tab", create_action("NextWindow")))
keyboard.appendChild(create_keybinding("Mod4-a", create_action("ToggleMaximize")))
keyboard.appendChild(create_keybinding("A-Left", create_move_action("left")))
keyboard.appendChild(create_keybinding("A-Right", create_move_action("right")))
keyboard.appendChild(create_keybinding("A-Up", create_move_action("up")))
keyboard.appendChild(create_keybinding("A-Down", create_move_action("down")))
keyboard.appendChild(create_keybinding("Mod4-Left", create_snap_action("left")))
keyboard.appendChild(create_keybinding("Mod4-Right", create_snap_action("right")))
keyboard.appendChild(create_keybinding("Mod4-Up", create_snap_action("up")))
keyboard.appendChild(create_keybinding("Mod4-Down", create_snap_action("down")))
keyboard.appendChild(create_keybinding("Mod4-1", create_goto_desktop_action("1")))
keyboard.appendChild(create_keybinding("Mod4-2", create_goto_desktop_action("2")))
keyboard.appendChild(create_keybinding("Mod4-F12", create_action("ToggleKeybinds")))
keyboard.appendChild(create_keybinding("Mod4-S-1", create_sendto_desktop_action("1")))
keyboard.appendChild(create_keybinding("Mod4-S-2", create_sendto_desktop_action("2")))
keyboard.appendChild(create_keybinding("Mod4-S-q", create_action("Close")))
keyboard.appendChild(create_keybinding("Mod4-S-s", create_action("ToggleOmnipresent")))
keyboard.appendChild(create_keybinding("Mod4-Tab", create_goto_desktop_action("right")))
keyboard.appendChild(create_keybinding("Mod4-j", create_action("NextWindow")))
keyboard.appendChild(create_keybinding("Mod4-k", create_action("PreviousWindow")))
keyboard.appendChild(create_keybinding("Mod4-m", create_show_menu_action("root-menu")))
keyboard.appendChild(
    create_keybinding("Mod4-Return", create_execute_action("alacritty"))
)
keyboard.appendChild(
    create_keybinding("A-Space", create_show_menu_action("client-menu"))
)
keyboard.appendChild(
    create_keybinding("Mod4-p", create_execute_action("rofi -show drun -show-icons"))
)
keyboard.appendChild(
    create_keybinding("Mod4-l", create_execute_action("loginctl lock-session"))
)
keyboard.appendChild(
    create_keybinding("Mod4-c", create_execute_action("rofi-cliphist-copy"))
)
keyboard.appendChild(
    create_keybinding("Mod4-S-c", create_execute_action("hyprpicker --autocopy"))
)
keyboard.appendChild(
    create_keybinding("Mod4-S-Print", create_execute_action("shotman --capture region"))
)
keyboard.appendChild(
    create_keybinding("Mod4-Print", create_execute_action("shotman --capture window"))
)
keyboard.appendChild(
    create_keybinding("Print", create_execute_action("shotman --capture output"))
)
keyboard.appendChild(
    create_keybinding(
        "XF86_MonBrightnessUp", create_execute_action("brightnessctl set +10%")
    )
)
keyboard.appendChild(
    create_keybinding(
        "XF86_MonBrightnessDown", create_execute_action("brightnessctl set 10%-")
    )
)
keyboard.appendChild(
    create_keybinding(
        "XF86_AudioLowerVolume", create_execute_action("pamixer --decrease 5")
    )
)
keyboard.appendChild(
    create_keybinding(
        "XF86_AudioRaiseVolume", create_execute_action("pamixer --increase 5")
    )
)
keyboard.appendChild(
    create_keybinding("XF86_AudioMute", create_execute_action("pamixer --toggle-mute"))
)
keyboard.appendChild(
    create_keybinding(
        "XF86_AudioMicMute",
        create_execute_action("pamixer --default-source --toggle-mute"),
    )
)

font = root.createElement("font")
font.setAttribute("name", "sans")
font.setAttribute("size", "12")

gtk_theme = root.createElement("name")
gtk_theme.appendChild(root.createTextNode("GTK"))

theme = root.createElement("theme")
theme.appendChild(font)
theme.appendChild(gtk_theme)

natural_scroll_enabled = root.createElement("naturalScroll")
natural_scroll_enabled.appendChild(root.createTextNode("yes"))
disable_while_typing_enabled = root.createElement("disableWhileTyping")
disable_while_typing_enabled.appendChild(root.createTextNode("yes"))

touchpad_devices = root.createElement("device")
touchpad_devices.setAttribute("category", "touchpad")
touchpad_devices.appendChild(natural_scroll_enabled)
touchpad_devices.appendChild(disable_while_typing_enabled)

libinput = root.createElement("libinput")
libinput.appendChild(touchpad_devices)

desktops = root.createElement("desktops")
desktops.setAttribute("number", "2")

labwc_config = root.createElement("labwc_config")
labwc_config.appendChild(keyboard)
labwc_config.appendChild(libinput)
labwc_config.appendChild(theme)
labwc_config.appendChild(desktops)

root.appendChild(labwc_config)

# print(root.toprettyxml(indent="\t"))
print(root.toxml())
