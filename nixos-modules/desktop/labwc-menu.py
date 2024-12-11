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


def create_menu(id, items=[], execute=None):
    menu = root.createElement("menu")
    menu.setAttribute("id", id)

    if execute is not None:
        menu.setAttribute("execute", execute)

    for item in items:
        menu.appendChild(item)

    return menu


def create_menu_item(label, action):
    menu_item = root.createElement("item")
    menu_item.setAttribute("label", label)
    menu_item.appendChild(action)
    return menu_item


root_menu = create_menu(
    "root-menu",
    items=[
        create_menu_item("Lock", create_execute_action("loginctl lock-session")),
        create_menu_item("Reboot", create_execute_action("systemctl reboot")),
        create_menu_item("Power Off", create_execute_action("systemctl poweroff")),
        create_menu_item("Exit", create_action("Exit")),
    ],
)

launcher_menu = create_menu(
    "launcher-menu", execute="xdgmenumaker --icons --format=openbox"
)

openbox_menu = root.createElement("openbox_menu")
openbox_menu.appendChild(root_menu)
openbox_menu.appendChild(launcher_menu)

root.appendChild(openbox_menu)

print(root.toprettyxml(indent="\t"))
# print(root.toxml())
