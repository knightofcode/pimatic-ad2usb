$(document).on( "templateinit", (event) ->
  console.log("Loaded AlarmDeviceItem")

  class AlarmDeviceItem extends pimatic.DeviceItem
    constructor: (data) ->
      console.log(data)
      super(data)

  pimatic.templateClasses['AlarmDeviceItem'] = AlarmDeviceItem
)