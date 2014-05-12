# #Plugin template

# This is an plugin template and mini tutorial for creating pimatic plugins. It will explain the 
# basics of how the plugin system works and how a plugin should look like.

# ##The plugin code

# Your plugin must export a single function, that takes one argument and returns a instance of
# your plugin class. The parameter is an envirement object containing all pimatic related functions
# and classes. See the [startup.coffee](http://sweetpi.de/pimatic/docs/startup.html) for details.
module.exports = (env) ->


  # ###require modules included in pimatic
  # To require modules that are included in pimatic use `env.require`. For available packages take 
  # a look at the dependencies section in pimatics package.json

  # Require [convict](https://github.com/mozilla/node-convict) for config validation.
  convict = env.require "convict"

  # Require the [Q](https://github.com/kriskowal/q) promise library
  Q = env.require 'q'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  # Include you own depencies with nodes global require function:
  #  
  #     someThing = require 'someThing'
  #
  EverSocket = require('eversocket').EverSocket
  AD2USB = require 'ad2usb'

  # ###MyPlugin class
  # Create a class that extends the Plugin class and implements the following functions:
  class AD2USBPlugin extends env.plugins.Plugin

  # ####init()
  # The `init` function is called by the framework to ask your plugin to initialise.
  #
  # #####params:
  #  * `app` is the [express] instance the framework is using.
  #  * `framework` the framework itself
  #  * `config` the properties the user specified as config for your plugin in the `plugins`
  #     section of the config.json file
  #
  #
    init: (app, @framework, config) =>
      # Require your config schema
      @conf = convict require('./ad2usb-config-schema')
      # and validate the given config.
      @conf.load(config)
      @conf.validate()


    createDevice: (deviceConfig) =>
      switch deviceConfig.class
        when "AD2USBAdapter"
          @framework.registerDevice(new AD2USBAdapter(deviceConfig))
          return true
        when "AD2USBWirelessZone"
          deviceConfig.framework = @framework
          @framework.registerDevice(new AD2USBWirelessZone(deviceConfig))
          return true
        else
          return false


  class AD2USBAdapter extends env.devices.Device
    _state: undefined

    constructor: (deviceConfig) ->
      @name = deviceConfig.name
      @id = deviceConfig.id
      @_code = deviceConfig.code

      socket = new EverSocket(type: 'tcp4', timeout: 10000, reconnectOnTimeout: true)
      env.logger.info("connecting to #{@name} at #{deviceConfig.host} on port #{deviceConfig.port}")
      socket.on 'error', (err) =>
        env.logger.error("error communicating with #{@name}: #{err}. Reconnecting.")
        socket.reconnect()
      socket.connect parseInt(deviceConfig.port), deviceConfig.host, =>
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
        type: String
        labels: ['disarmed', 'armed away', 'armed stay']

    actions:
      away:
        description: 'arms the alarm in away mode'
      stay:
        description: 'arms the alarm in stay mode'
      disarm:
        description: 'disarms the alarm'

    getState: ->
      Q(@_state)

    away: ->
      env.logger.info 'away'
      Q.ninvoke @panel, 'armAway', @_code

    stay: ->
      env.logger.info 'stay'
      Q.ninvoke @panel, 'armStay', @_code

    disarm: ->
      env.logger.info 'disarm'
      Q.ninvoke @panel, 'disarm', @_code

  class AD2USBWirelessZone extends env.devices.ContactSensor
    constructor: (deviceConfig) ->
      framework = deviceConfig.framework
      delete deviceConfig.framework

      @name = deviceConfig.name
      @id = deviceConfig.id
      @_ad2usb = framework.getDeviceById(deviceConfig.ad2usbId)
      @_ad2usb.panel.on "loop:#{deviceConfig.serial}:#{deviceConfig.loop}", (closed) =>
        state = if closed then 'closed' else 'opened'
        @_setContact(state)
        env.logger.info("#{@name} is #{state}")

      super()

  return new AD2USBPlugin()