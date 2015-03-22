$(document).on("templateinit", (event) ->

  class AlarmKeypadItem extends pimatic.ButtonsItem

    getItemTemplate: => 'alarm-keypad'

  pimatic.templateClasses['alarm-keypad'] = AlarmKeypadItem
)
