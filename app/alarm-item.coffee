$(document).on("templateinit", (event) ->

  class AlarmItem extends pimatic.DeviceItem

    getItemTemplate: -> 'alarm'

    constructor: (templData, @device) ->

      @stateDisplayValueText = ko.computed => @getAttribute('state').displayValueText()

      @stateClass = ko.computed =>
        stateValue = @getAttribute('state').displayValueText()
        if stateValue == 'disarmed' then return 'disarmed-state'
        else if stateValue == 'ready' then return 'ready-state'
        else return 'armed-state'

      super(templData, @device)

    onShowPress: ->
      pimatic.alarm = this
      jQuery.mobile.changePage '#alarm-keypad', transition: 'slide'

  pimatic.templateClasses['alarm'] = AlarmItem
)
