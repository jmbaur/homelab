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


def create_menu(id, items=[]):
    menu = root.createElement("menu")
    menu.setAttribute("id", id)

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
    [
        create_menu_item("Web browser", create_execute_action("firefox")),
        create_menu_item("Terminal", create_execute_action("alacritty")),
        create_menu_item("Reconfigure", create_action("Reconfigure")),
        create_menu_item("Lock", create_execute_action("loginctl lock-session")),
        create_menu_item("Exit", create_action("Exit")),
    ],
)

labwc_menu = root.createElement("openbox_menu")
labwc_menu.appendChild(root_menu)

root.appendChild(labwc_menu)

# print(root.toprettyxml(indent="\t"))
print(root.toxml())
