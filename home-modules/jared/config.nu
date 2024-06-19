$env.config = {
    show_banner: false

    cursor_shape: {
        emacs: block
    }

    history: {
        file_format: "sqlite"
        isolation: true
    }

    edit_mode: emacs

    keybindings: [
        {
            name: insert_last_token
            modifier: alt
            keycode: char_.
            mode: emacs
            event: [
                { edit: InsertString, value: "!$" }
                { send: Enter }
            ]
        }
    ]

    shell_integration: {
        # osc2 abbreviates the path if in the home_dir, sets the tab/window title, shows the running command in the tab/window title
        osc2: true
        # osc7 is a way to communicate the path to the terminal, this is helpful for spawning new tabs in the same directory
        osc7: true
        # osc8 is also implemented as the deprecated setting ls.show_clickable_links, it shows clickable links in ls output if your terminal supports it. show_clickable_links is deprecated in favor of osc8
        osc8: true
        # osc9_9 is from ConEmu and is starting to get wider support. It's similar to osc7 in that it communicates the path to the terminal
        osc9_9: false
        # osc133 is several escapes invented by Final Term which include the supported ones below.
        # 133;A - Mark prompt start
        # 133;B - Mark prompt end
        # 133;C - Mark pre-execution
        # 133;D;exit - Mark execution finished with exit code
        # This is used to enable terminals to know where the prompt is, the command is, where the command finishes, and where the output of the command is
        osc133: true
        # osc633 is closely related to osc133 but only exists in visual studio code (vscode) and supports their shell integration features
        # 633;A - Mark prompt start
        # 633;B - Mark prompt end
        # 633;C - Mark pre-execution
        # 633;D;exit - Mark execution finished with exit code
        # 633;E - NOT IMPLEMENTED - Explicitly set the command line with an optional nonce
        # 633;P;Cwd=<path> - Mark the current working directory and communicate it to the terminal
        # and also helps with the run recent menu in vscode
        osc633: true
        # reset_application_mode is escape \x1b[?1l and was added to help ssh work better
        reset_application_mode: true
    }
}

# SSH control master paths become invalid if the link goes down for an active
# connection.
def remove_ssh_connections [] {
    ls $env.XDG_RUNTIME_DIR | where name =~ "ssh-[a-f0-9]{40}" | each { rm --verbose $in.name }
}

alias j = tmux-jump
