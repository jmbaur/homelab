{ config, pkgs, ... }:
{
  programs.i3status-rust = {
    enable = true;
    bars.okra = {
      theme = "native";
      blocks = [
        { block = "disk_space"; path = "/"; alias = "/"; info_type = "available"; unit = "GB"; interval = 20; warning = 20.0; alert = 10.0; }
        { block = "memory"; display_type = "memory"; format_mem = "{mem_used_percents}"; }
        { block = "memory"; display_type = "swap"; format_swap = "{swap_used_percents}"; }
        { block = "cpu"; interval = 1; }
        { block = "load"; interval = 1; format = "{1m}"; }
        { block = "networkmanager"; }
        { block = "sound"; device_kind = "source"; format = "{output_name} {volume}"; mappings = { "alsa_input.usb-BLUE_MICROPHONE_Blue_Snowball_SUGA_2021_01_20_62712-00.mono-fallback" = "Blue Snowball"; }; }
        { block = "sound"; device_kind = "sink"; format = "{output_name} {volume}"; mappings = { "alsa_output.pci-0000_05_00.6.analog-stereo" = "Speakers"; "alsa_output.pci-0000_05_00.1.hdmi-stereo" = "Headphones"; }; }
        { block = "time"; interval = 1; format = "%F %T"; }
      ];
    };
    bars.beetroot = {
      theme = "native";
      blocks = [
        { block = "disk_space"; path = "/"; alias = "/"; info_type = "available"; unit = "GB"; interval = 20; warning = 20.0; alert = 10.0; }
        { block = "memory"; display_type = "memory"; format_mem = "{mem_used_percents}"; }
        { block = "memory"; display_type = "swap"; format_swap = "{swap_used_percents}"; }
        { block = "cpu"; interval = 1; }
        { block = "load"; interval = 1; format = "{1m}"; }
        { block = "networkmanager"; }
        { block = "battery"; }
        { block = "time"; interval = 1; format = "%F %T"; }
      ];
    };
  };

}
