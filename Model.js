function deviceGlyph(dev) {
  if (!dev) return "󰓃";
  if (dev.kind === "source") {
    var sText = (dev.node_name + " " + dev.description + " " + dev.nick).toLowerCase();
    if (sText.indexOf("headset") !== -1) return "󰋋";
    if (sText.indexOf("bluetooth") !== -1 || dev.bus === "bluetooth") return "󰂯";
    if (sText.indexOf("webcam") !== -1 || sText.indexOf("camera") !== -1) return "󰄀";
    return "󰍬";
  }

  var text = (dev.node_name + " " + dev.description + " " + dev.nick + " " + dev.bus).toLowerCase();
  if (text.indexOf("headphone") !== -1 || text.indexOf("headset") !== -1 || text.indexOf("earbud") !== -1 || text.indexOf("earphone") !== -1)
    return "󰋋";
  if (text.indexOf("bluetooth") !== -1 || dev.bus === "bluetooth")
    return "󰂯";
  if (text.indexOf("hdmi") !== -1 || text.indexOf("display") !== -1)
    return "󰍹";
  return "󰓃";
}

if (typeof module !== "undefined") {
  module.exports = {
    deviceGlyph: deviceGlyph
  };
}
