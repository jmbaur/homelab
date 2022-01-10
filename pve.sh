#!/usr/bin/env bash

ansible-playbook ./playbooks/pve.yml -i ./inventory.ini --user root --ask-pass --ask-become-pass
