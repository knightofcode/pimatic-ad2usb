module.exports = {
  title: "pimatic-ad2usb device config schemas"
  AD2USBAdapter: {
    title: "AD2USBAdapter config options"
    type: "object"
    properties:
      host:
        description: "the host where ser2sock is running"
        type: "string"
      port:
        description: "the port where ser2sock is running"
        type: "number"
      code:
        description: "the code to arm and disarm the system"
        type: "number"
  }
  AD2USBWirelessZone: {
    title: "AD2USBWirelessZone config options"
    type: "object"
    properties:
      alarmId:
        description: "the id of the alarm"
        type: "string"
      serial:
        description: "the serial number of the sensor"
        type: "string"
      loop:
        description: "the loop of the sensor"
        type: "number"
  }
}