$(document).on("templateinit", (event) ->
  console.log("Loaded AlarmDeviceItem")

  class AlarmDeviceItem extends pimatic.DeviceItem



    constructor: (data) ->
      super(data)
      @state = ko.observable()
      @isArmedStay = ko.computed(=> @state() == 'armed stay')
      @isArmedAway = ko.computed(=> @state() == 'armed away')
      @isDisarmed = ko.computed(=> @state() == 'disarmed')

      @state(@getAttribute('state').value())

      @getAttribute('state').value.subscribe((value) =>
        console.log(value)
        @state(value)
      )

    armStay: ->
      console.log("stay")
      $.ajax(
        url: "/api/device/#{@deviceId}/stay"
      ).fail(ajaxAlertFail)

    armAway: ->
      console.log("away")
      $.ajax(
        url: "/api/device/#{@deviceId}/away"
      ).fail(ajaxAlertFail)

    disarm: ->
      console.log("disarm")
      $.ajax(
        url: "/api/device/#{@deviceId}/disarm"
      ).fail(ajaxAlertFail)

  pimatic.templateClasses['AlarmDeviceItem'] = AlarmDeviceItem
)