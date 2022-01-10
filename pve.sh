#!/usr/bin/env bash

ansible-playbook ./playbooks/pve.yml -i ./inventory.ini --diff --user root --ask-pass --ask-become-pass
