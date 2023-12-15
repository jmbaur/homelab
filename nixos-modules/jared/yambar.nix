{ networkInterfaces ? [ ]
, batteries ? [ ]
}:
{
  bar = {
    height = 34;
    location = "top";
    background = "000000ff";
    font = "sans:pixelsize=16";
    spacing = 4;
    left = [{
      foreign-toplevel.content.map.conditions = {
        "~activated".empty = { };
        activated = [{ string = { text = "{app-id}: {title}"; max = 75; }; }];
      };
    }];
    center = [{
      clock = {
        time-format = "%H:%M %Z";
        content = [
          { string = { text = "{date}"; right-margin = 5; }; }
          { string = { text = "{time}"; }; }
        ];
      };
    }];
    # TODO(jared): yambar does not really have any auto-detection of hardware
    # and requires very explicit configuration of each module. We can get
    # around this by using the `script` module and making our own program to
    # do the auto-detection.
    right = (map
      (name: {
        network = {
          inherit name;
          content.map.conditions = {
            "~carrier".empty = { };
            carrier.string.text = "{name}: {state}";
          };
        };
      })
      networkInterfaces)
    ++ (map
      (name: {
        battery = {
          inherit name;
          content.string.text = "{name}: {state} {capacity}%";
        };
      })
      batteries)
    ++ [{
      mem = {
        poll-interval = 2500;
        content.string.text = "MEM: {percent_used}%";
      };
    }];
  };
}
