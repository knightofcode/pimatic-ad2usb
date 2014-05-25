$(document).on( "templateinit", (event) ->
  console.log("Loaded AlarmDeviceItem")

  class AlarmDeviceItem extends pimatic.DeviceItem

    state: ko.observable()

    constructor: (data) ->
      super(data)
      state = @getAttribute('state')
      @state(state.value())
      state.value.subscribe( (value) =>
        console.log(value)
        @state(value)
      )

    armStay: ->
      console.log("stay")
      $.ajax(
        url:"/api/device/#{@deviceId}/stay"
      ).fail(ajaxAlertFail)

    armAway: ->
      console.log("away")
      $.ajax(
        url:"/api/device/#{@deviceId}/away"
      ).fail(ajaxAlertFail)

    disarm: ->
      console.log("disarm")
      $.ajax(
        url:"/api/device/#{@deviceId}/disarm"
      ).fail(ajaxAlertFail)

  pimatic.templateClasses['AlarmDeviceItem'] = AlarmDeviceItem
)