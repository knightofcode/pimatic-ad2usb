module.exports = {
  title: "pimatic-ad2usb device config schemas"
  AD2USBAlarm: {
    title: "AD2USBAlarm config options"
    type: "object"
    properties:
      host:
        description: "the host where the serial-to-IP bridge is running"
        type: "string"
      port:
        description: "the port where the serial-to-IP bridge is running"
        type: "number"
      code:
        description: "the code to arm and disarm the system"
        type: "number"
  }
  AD2USBWirelessSensor: {
    title: "AD2USBWirelessSensor config options"
    type: "object"
    properties:
      alarmId:
        description: "the id of the alarm that monitors the sensor"
        type: "string"
      serial:
        description: "the serial number of the sensor"
        type: "string"
      loop:
        description: "the loop of the sensor"
        type: "number"
  }
}