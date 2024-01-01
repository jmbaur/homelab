- Add a way to add trusted user on first boot for immutable images, see:
  https://github.com/systemd/systemd/blob/main/units/systemd-homed-firstboot.service
- Fix issue with mutableNixStore enabled on image based system:
  `'lastModified' attribute mismatch in input`
- Polkit issues with image based system:
```console
$ systemctl status
Failed to read server status: Access denied
```
