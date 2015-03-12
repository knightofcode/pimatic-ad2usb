module.exports = (env) ->

  Promise = env.require 'bluebird'
  convict = env.require 'convict'
  assert = env.require 'cassert'

  EverSocket = require('eversocket').EverSocket
  AD2USB = require 'ad2usb'

  class AD2USBPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("AD2USBAdapter", {
        configDef: deviceConfigDef.AD2USBAdapter, 
        createCallback: (config) => return new AD2USBAdapter(config)
      })

      @framework.deviceManager.registerDeviceClass("AD2USBWirelessZone", {
        configDef: deviceConfigDef.AD2USBWirelessZone, 
        createCallback: (config) => return new AD2USBWirelessZone(config)
      })
    
    getAlarmById: (alarmId) =>
      return @framework.deviceManager.getDeviceById(alarmId)

  plugin = new AD2USBPlugin

  class AD2USBAdapter extends env.devices.Device
    _state: undefined

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

      super()

    attributes:
      state:
        description: 'alarm arming status'
        type: 'string'
        enum: ['disarmed', 'armed away', 'armed stay']

    actions:
      away:
        description: 'arms the alarm in away mode'
      stay:
        description: 'arms the alarm in stay mode'
      disarm:
        description: 'disarms the alarm'

    getState: ->
      Promise.resolve @_state

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

  class AD2USBWirelessZone extends env.devices.ContactSensor
    constructor: (@config) ->
      @name = config.name
      @id = config.id
      @_ad2usb = plugin.getAlarmById(config.alarmId)
      @_ad2usb.panel.on "loop:#{config.serial}:#{config.loop}", (closed) =>
        @_setContact(closed)
        state = if closed then 'closed' else 'opened'
        env.logger.info("#{@name} is #{state}")

      super()

  plugin.AD2USBAdapter = AD2USBAdapter
  plugin.AD2USBWirelessZone = AD2USBWirelessZone

  return plugin