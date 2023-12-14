{}:
{
  bar = {
    height = 30;
    location = "top";
    background = "000000ff";
    font = "sans:pixelsize=14";
    left = [{
      foreign-toplevel.content.map.conditions = {
        "~activated".empty = { };
        activated = [
          { string = { text = "{app-id}"; foreground = "ffa0a0ff"; }; }
          { string = { text = ": {title}"; }; }
        ];
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
    right = [{
      network = {
        name = "eno1";
        content.map.conditions = {
          "~carrier".empty = { };
          carrier.map = {
            default.string = { text = "down"; foreground = "ffffff66"; };
            conditions."state == up && ipv4 != \" \"".string.text = "up";
          };
        };
      };
    }];
  };
}
