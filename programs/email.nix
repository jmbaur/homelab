{ config, pkgs, ... }: {
  home-manager.users.jared.services.mbsync.enable = true;

  home-manager.users.jared.home.packages = [ pkgs.neomutt ];

  home-manager.users.jared.home.file.".config/neomutt/neomuttrc".text = ''
    macro index 'c' '<change-folder>?<change-dir><home>^K=<enter>'

    bind index,pager \Cp sidebar-prev
    bind index,pager \Cn sidebar-next
    bind index,pager \Co sidebar-open
    bind index,pager B sidebar-toggle-visible

    source ${pkgs.neomutt}/share/doc/neomutt/vim-keys/vim-keys.rc
    source ${pkgs.neomutt}/share/doc/neomutt/samples/colors.linux
    set mailcap_path = ~/.config/neomutt/mailcap
    auto_view text/html

    set fast_reply=yes
    set include=yes

    source ~/.config/neomutt/fastmail
    folder-hook "fastmail" 'source ~/.config/neomutt/fastmail'
    source ~/.config/neomutt/gmail
    folder-hook "gmail" 'source ~/.config/neomutt/gmail'
    source ~/.config/neomutt/prenda
    folder-hook "prenda" 'source ~/.config/neomutt/prenda'
  '';

  home-manager.users.jared.home.file.".config/neomutt/mailcap".text = ''
    text/html; w3m -I %{charset} -T text/html; copiousoutput;
    application/pdf; zathura %s; x-neomutt-keep
    image/*; sxiv %s; x-neomutt-keep
    video/*; mpv %s > /dev/null
  '';
  home-manager.users.jared.home.file.".config/neomutt/fastmail".text = ''
    set folder=~/Maildir/fastmail
    set spoolfile=+Inbox
    set postponed=+Drafts
    set record=+Sent
    unmailboxes *
    mailboxes +Inbox +Archive +Drafts +Inbox +Notes +Sent +Spam +Trash
  '';
  home-manager.users.jared.home.file.".config/neomutt/gmail".text = ''
    set folder=~/Maildir/gmail
    set spoolfile=+Inbox
    set postponed=+Drafts
    unset record
    unmailboxes *
    mailboxes +Inbox +Trash +Important +Sent\ Mail +Drafts +All\ Mail +Starred +Spam
  '';
  home-manager.users.jared.home.file.".config/neomutt/prenda".text = ''
    set folder=~/Maildir/prenda
    set spoolfile=+Inbox
    set postponed=+Drafts
    unset record
    unmailboxes *
    mailboxes +Inbox +Trash +Important +Sent\ Mail +Drafts +All\ Mail +Starred +Spam
  '';

  home-manager.users.jared.programs.mbsync.enable = true;
  home-manager.users.jared.programs.msmtp.enable = true;

  home-manager.users.jared.accounts.email.accounts = {
    fastmail = {
      primary = true;
      flavor = "plain";
      address = "jaredbaur@fastmail.com";
      userName = "jaredbaur@fastmail.com";
      realName = "Jared Baur";
      signature = {
        showSignature = "append";
        text = ''
          Jared Baur
          (925) 813-2611
          jaredbaur@fastmail.com
        '';
      };
      imap = {
        host = "imap.fastmail.com";
        port = 993;
        tls.enable = true;
      };
      mbsync = {
        enable = true;
        create = "maildir";
        expunge = "both";
      };
      smtp = {
        host = "smtp.fastmail.com";
        port = 465;
        tls.enable = true;
      };
      msmtp.enable = true;
    };
    gmail = {
      primary = false;
      flavor = "gmail.com";
      address = "baur.jaredmichael@gmail.com";
      userName = "baur.jaredmichael@gmail.com";
      realName = "Jared Baur";
      signature = {
        showSignature = "append";
        text = ''
          Jared Baur
          (925) 813-2611
          baur.jaredmichael@gmail.com
        '';
      };
      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };
      mbsync = {
        enable = true;
        create = "maildir";
        expunge = "both";
        groups.gmail = {
          channels.inbox = {
            farPattern = "INBOX";
            nearPattern = "Inbox";
            extraConfig.Create = "both";
          };
          channels.allmail = {
            farPattern = "[Gmail]/All Mail";
            nearPattern = "All Mail";
            extraConfig.Create = "both";
          };
          channels.drafts = {
            farPattern = "[Gmail]/Drafts";
            nearPattern = "Drafts";
            extraConfig.Create = "both";
          };
          channels.important = {
            farPattern = "[Gmail]/Important";
            nearPattern = "Important";
            extraConfig.Create = "both";
          };
          channels.sentmail = {
            farPattern = "[Gmail]/Sent Mail";
            nearPattern = "Sent Mail";
            extraConfig.Create = "both";
          };
          channels.spam = {
            farPattern = "[Gmail]/Spam";
            nearPattern = "Spam";
            extraConfig.Create = "both";
          };
          channels.starred = {
            farPattern = "[Gmail]/Starred";
            nearPattern = "Starred";
            extraConfig.Create = "both";
          };
          channels.trash = {
            farPattern = "[Gmail]/Trash";
            nearPattern = "Trash";
            extraConfig.Create = "both";
          };
        };
      };
      smtp = {
        host = "smtp.gmail.com";
        port = 465;
        tls.enable = true;
      };
      msmtp.enable = true;
    };
    prenda = {
      primary = false;
      flavor = "gmail.com";
      address = "jared@prenda.co";
      userName = "jared@prenda.co";
      realName = "Jared Baur";
      signature = {
        showSignature = "append";
        text = ''
          Jared Baur
          Software Engineer
          jared@prenda.co
        '';
      };
      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };
      mbsync = {
        enable = true;
        create = "maildir";
        expunge = "both";
        groups.gmail = {
          channels.inbox = {
            farPattern = "INBOX";
            nearPattern = "Inbox";
            extraConfig.Create = "both";
          };
          channels.allmail = {
            farPattern = "[Gmail]/All Mail";
            nearPattern = "All Mail";
            extraConfig.Create = "both";
          };
          channels.drafts = {
            farPattern = "[Gmail]/Drafts";
            nearPattern = "Drafts";
            extraConfig.Create = "both";
          };
          channels.important = {
            farPattern = "[Gmail]/Important";
            nearPattern = "Important";
            extraConfig.Create = "both";
          };
          channels.sentmail = {
            farPattern = "[Gmail]/Sent Mail";
            nearPattern = "Sent Mail";
            extraConfig.Create = "both";
          };
          channels.spam = {
            farPattern = "[Gmail]/Spam";
            nearPattern = "Spam";
            extraConfig.Create = "both";
          };
          channels.starred = {
            farPattern = "[Gmail]/Starred";
            nearPattern = "Starred";
            extraConfig.Create = "both";
          };
          channels.trash = {
            farPattern = "[Gmail]/Trash";
            nearPattern = "Trash";
            extraConfig.Create = "both";
          };
        };
      };
      smtp = {
        host = "smtp.gmail.com";
        port = 465;
        tls.enable = true;
      };
      msmtp.enable = true;
    };
  };
}
