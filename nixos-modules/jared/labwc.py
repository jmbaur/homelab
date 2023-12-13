#!/usr/bin/env python3

from xml.dom import minidom

root = minidom.Document()


def create_action(name):
    action = root.createElement("action")
    action.setAttribute("name", name)
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


root_menu = root.createElement("menu")
root_menu.appendChild(root.createTextNode("root-menu"))
show_menu_action = create_action("ShowMenu")
show_menu_action.appendChild(root_menu)

keyboard = root.createElement("keyboard")
keyboard.setAttribute("repeatRate", "50")
keyboard.setAttribute("repeatDelay", "300")
keyboard.appendChild(root.createElement("default"))
keyboard.appendChild(create_keybinding("W-m", show_menu_action))
keyboard.appendChild(create_keybinding("W-j", create_action("NextWindow")))
keyboard.appendChild(create_keybinding("W-k", create_action("PreviousWindow")))
keyboard.appendChild(create_keybinding("W-Return", create_execute_action("foot")))
keyboard.appendChild(create_keybinding("W-p", create_execute_action("rofi -show drun")))
keyboard.appendChild(create_keybinding("W-Tab", create_goto_desktop_action("right")))
keyboard.appendChild(create_keybinding("W-1", create_goto_desktop_action("1")))
keyboard.appendChild(create_keybinding("W-2", create_goto_desktop_action("2")))
keyboard.appendChild(create_keybinding("W-3", create_goto_desktop_action("3")))
keyboard.appendChild(create_keybinding("W-4", create_goto_desktop_action("4")))
keyboard.appendChild(create_keybinding("W-S-1", create_sendto_desktop_action("1")))
keyboard.appendChild(create_keybinding("W-S-2", create_sendto_desktop_action("2")))
keyboard.appendChild(create_keybinding("W-S-3", create_sendto_desktop_action("3")))
keyboard.appendChild(create_keybinding("W-S-4", create_sendto_desktop_action("4")))

font = root.createElement("font")
font.setAttribute("name", "sans")
font.setAttribute("size", "12")

theme = root.createElement("theme")
theme.appendChild(font)

natural_scroll = root.createElement("naturalScroll")
natural_scroll.appendChild(root.createTextNode("yes"))
disable_while_typing = root.createElement("disableWhileTyping")
disable_while_typing.appendChild(root.createTextNode("yes"))

touchpad = root.createElement("device")
touchpad.setAttribute("category", "non-touch")
touchpad.appendChild(natural_scroll)
touchpad.appendChild(disable_while_typing)

libinput = root.createElement("libinput")
libinput.appendChild(touchpad)

desktops = root.createElement("desktops")
desktops.setAttribute("number", "4")

labwc_config = root.createElement("labwc_config")
labwc_config.appendChild(keyboard)
labwc_config.appendChild(libinput)
labwc_config.appendChild(theme)
labwc_config.appendChild(desktops)

root.appendChild(labwc_config)

# print(root.toprettyxml(indent="\t"))
print(root.toxml())
