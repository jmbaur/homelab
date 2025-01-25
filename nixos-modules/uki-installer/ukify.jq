(."custom.ukify.v1".stub) as $stub
| (."custom.ukify.v1".uname) as $uname
| (."custom.ukify.v1".efiArch) as $efiArch
| (."custom.ukify.v1".osRelease) as $osRelease
| (."custom.ukify.v1".devicetree) as $devicetree
| (."org.nixos.bootspec.v1".kernel) as $linux
| (."org.nixos.bootspec.v1".initrd) as $initrd
| (."org.nixos.bootspec.v1".kernelParams | join(" ")) as $otherParams
| (."org.nixos.bootspec.v1".init) as $init
| [ "--efi-arch=\($efiArch)", "--uname=\($uname)", "--stub=\($stub)", "--initrd=\($initrd)", "--linux=\($linux)", "--cmdline=init=\($init) \($otherParams)" ] + (if $devicetree then [ "--devicetree=\($devicetree)" ] else [ ] end) | join("\n")
