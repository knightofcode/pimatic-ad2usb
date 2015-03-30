tc = pimatic.tryCatch

$(document).on("pagecreate", '#alarm-keypad', tc (event) ->

  class AD2USBAlarmKeypadViewModel

    constructor: ->
      @alarm = ko.observable(null)
      @messageLine1 = ko.computed => @alarm()?.getAttribute('messageLine1').value()
      @messageLine2 = ko.computed => @alarm()?.getAttribute('messageLine2').value()
      @backlightClass = ko.computed =>
        enabled = @alarm()?.getAttribute('backlight').value()
        if enabled then 'backlight-enabled' else 'backlight-disabled'
      @buttons = ko.computed => @alarm()?.device.configWithDefaults().buttons

    setAlarm: (alarm) ->
      @alarm(alarm)

    onButtonPress: (button) =>
      @alarm().device.rest.buttonPress({buttonId: button.id}, global: no)
        .done(ajaxShowToast)
        .fail(ajaxAlertFail)


  pimatic.pages.alarmKeypad = alarmKeypad = new AD2USBAlarmKeypadViewModel()

  ko.applyBindings(alarmKeypad, $('#alarm-keypad')[0])
  return
)


$(document).on("pagehide", '#alarm-keypad', tc (event) ->
  return
)

$(document).on("pagebeforeshow", '#alarm-keypad', tc (event) ->
  unless pimatic.alarm?
    jQuery.mobile.changePage '#index'
    return false
  pimatic.pages.alarmKeypad.setAlarm(pimatic.alarm)
)
