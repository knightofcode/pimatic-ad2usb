module.exports = (env) ->

  Promise = env.require 'bluebird'
  convict = env.require 'convict'
  assert = env.require 'cassert'

  EverSocket = require('eversocket').EverSocket
  AD2USB = require 'ad2usb'

  class AD2USBPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("AD2USBAlarm", {
        configDef: deviceConfigDef.AD2USBAlarm,
        createCallback: (config) => return new AD2USBAlarm(config)
      })

      @framework.deviceManager.registerDeviceClass("AD2USBWirelessSensor", {
        configDef: deviceConfigDef.AD2USBWirelessSensor,
        createCallback: (config) => return new AD2USBWirelessSensor(config)
      })

      @framework.deviceManager.registerDeviceClass("AD2USBAlarmKeypad", {
        configDef: deviceConfigDef.AD2USBAlarmKeypad,
        createCallback: (config) => return new AD2USBAlarmKeypad(config)
      })

      @framework.on "after init", =>
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', "pimatic-ad2usb/app/alarm-item.coffee"
          mobileFrontend.registerAssetFile 'css', "pimatic-ad2usb/app/alarm-item.css"
          mobileFrontend.registerAssetFile 'html', "pimatic-ad2usb/app/alarm-item.jade"
          mobileFrontend.registerAssetFile 'js', "pimatic-ad2usb/app/alarm-keypad-page.coffee"
          mobileFrontend.registerAssetFile 'css', "pimatic-ad2usb/app/alarm-keypad-page.css"
          mobileFrontend.registerAssetFile 'html', "pimatic-ad2usb/app/alarm-keypad-page.jade"
        else
          env.logger.warn "AD2USBPlugin could not find the mobile-frontend. No gui will be available"

    getAlarmById: (alarmId) =>
      return @framework.deviceManager.getDeviceById(alarmId)

  plugin = new AD2USBPlugin

  class AD2USBAlarm extends env.devices.Device

    _state: undefined

    template: 'alarm'

    constructor: (@config) ->
      @name = config.name
      @id = config.id
      @_code = config.code

      socket = new EverSocket(type: 'tcp4', timeout: 10000, reconnectOnTimeout: true)
      env.logger.info("connecting to #{@name} at #{config.host} on port #{config.port}")
      socket.on 'error', (err) =>
        env.logger.error("error communicating with #{@name}: #{err}. Reconnecting.")
        socket.reconnect()
      socket.connect parseInt(config.port), config.host, =>
        env.logger.info("connection established with #{@name}")

      @panel = new AD2USB socket

      @panel.on 'ready', =>
        env.logger.info("#{@name} ready")
        @_state = 'ready'
        @emit 'state', 'ready'

      @panel.on 'disarmed', =>
        env.logger.info("#{@name} disarmed")
        @_state = 'disarmed'
        @emit 'state', 'disarmed'

      @panel.on 'armedStay', =>
        env.logger.info("#{@name} armed in stay mode")
        @_state = 'armed stay'
        @emit 'state', 'armed stay'

      @panel.on 'armedAway', =>
        env.logger.info("#{@name} armed in away mode")
        @_state = 'armed away'
        @emit 'state', 'armed away'

      @panel.on 'beep', (beeps) =>
        @emit 'beep', beeps

      @panel.on 'message:1', (msg) =>
        @emit 'messageLine1', msg

      @panel.on 'message:2', (msg) =>
        @emit 'messageLine2', msg

      @panel.on 'backlight', (backlight) =>
        @emit 'backlight', backlight

      KEYPAD_KEYS = [
        'OFF', 'AWAY', 'STAY', 'NIGHT',
        'A',   '1',    '2',    '3',
        'B',   '4',    '5',    '6',
        'C',   '7',    '8',    '9',
        'D',   '*',    '0',    '#',
      ]

      configDefaults = { buttons: ({ id: key, text: key } for key in KEYPAD_KEYS) }
      configDefaults.__proto__ = config.__proto__
      config.__proto__ = configDefaults

      super()

    attributes:
      state:
        description: 'alarm arming status'
        type: 'string'
        enum: ['ready', 'disarmed', 'armed away', 'armed stay']
      messageLine1:
        description: 'message line 1'
        type: 'string'
      messageLine2:
        description: 'message line 2'
        type: 'string'
      backlight:
        description: 'backlight'
        type: 'boolean'

    actions:
      away:
        description: 'arms the alarm in away mode'
      stay:
        description: 'arms the alarm in stay mode'
      disarm:
        description: 'disarms the alarm'
      buttonPress:
        description: 'presses a keypad button'
        params:
          buttonId:
            type: 'string'


    getState: ->
      Promise.resolve @_state

    getMessageLine1: ->
      Promise.resolve @panel['message:1']

    getMessageLine2: ->
      Promise.resolve @panel['message:2']

    getBacklight: ->
      Promise.resolve @panel['backlight']

    away: ->
      env.logger.info 'away'
      Promise.fromNode (callback) =>
        @panel.armAway @_code, callback

    stay: ->
      env.logger.info 'stay'
      Promise.fromNode (callback) =>
        @panel.armStay @_code, callback

    disarm: ->
      env.logger.info 'disarm'
      Promise.fromNode (callback) =>
        @panel.disarm @_code, callback

    buttonPress: (buttonId) ->
      keycode = switch
        when !isNaN(buttonId)    then buttonId
        when buttonId == '*'     then '*'
        when buttonId == '#'     then '#'
        when buttonId == 'OFF'   then '1'
        when buttonId == 'AWAY'  then '2'
        when buttonId == 'STAY'  then '3'
        when buttonId == 'NIGHT' then '33'
        when buttonId == 'A'     then "\u0001\u0001\u0001"
        when buttonId == 'B'     then "\u0002\u0002\u0002"
        when buttonId == 'C'     then "\u0003\u0003\u0003"
        when buttonId == 'D'     then "\u0004\u0004\u0004"
        else null
      if keycode != null
        @panel.send keycode

  class AD2USBWirelessSensor extends env.devices.ContactSensor
    constructor: (@config) ->
      @name = config.name
      @id = config.id
      @_alarm = plugin.getAlarmById(config.alarmId)
      @_alarm.panel.on "loop:#{config.serial}:#{config.loop}", (closed) =>
        @_setContact(closed)
        env.logger.info("#{@name} is #{if closed then 'closed' else 'opened'}")

      super()

  plugin.AD2USBAlarm = AD2USBAlarm
  plugin.AD2USBWirelessSensor = AD2USBWirelessSensor

  return plugin
