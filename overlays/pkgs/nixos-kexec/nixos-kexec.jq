(."org.nixos.bootspec.v1".kernel) as $linux
| (."org.nixos.bootspec.v1".initrd) as $initrd
| (."org.nixos.bootspec.v1".kernelParams | join(" ")) as $otherParams
| (."org.nixos.bootspec.v1".init) as $init
| "kexec -l \($linux) --initrd=\($initrd) --command-line=\"init=\($init) \($otherParams)\($append)\""
