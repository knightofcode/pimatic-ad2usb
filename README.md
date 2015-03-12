pimatic AD2USB alarm adapter plugin
=======================

Plugin for interacting with the [AD2USB](http://www.alarmdecoder.com/catalog/product_info.php/cPath/1/products_id/29) Ademco/Honeywell serial adapter. This plugin assumes you have
your adapter connected to the local network using a serial-to-ethernet bridge.

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