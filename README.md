pimatic AD2USB alarm adapter plugin
=======================

Plugin for interacting with devices from the [AD2*](http://www.alarmdecoder.com/catalog/index.php/cPath/1) family of Ademco/Honeywell alarm adapters. This plugin assumes you have
your adapter connected to the local network using a serial-to-IP bridge such as [ser2sock](https://github.com/nutechsoftware/ser2sock).

Example configuration:
----------------------

```json
{
  "plugin": "ad2usb",
  "devices": [
    {
      "id": "alarm",
      "name": "Alarm",
      "class": "AD2USBAdapter",
      "host": "192.168.5.199",
      "port": "4999",
      "code": "1234"
    },
    {
      "id": "front-door",
      "name": "Front Door",
      "class": "AD2USBWirelessZone",
      "alarmId": "alarm",
      "serial": "0123456",
      "loop": 2
    }
  ]
}
```