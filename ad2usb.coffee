# #Plugin template

# This is an plugin template and mini tutorial for creating pimatic plugins. It will explain the 
# basics of how the plugin system works and how a plugin should look like.

# ##The plugin code

# Your plugin must export a single function, that takes one argument and returns a instance of
# your plugin class. The parameter is an envirement object containing all pimatic related functions
# and classes. See the [startup.coffee](http://sweetpi.de/pimatic/docs/startup.html) for details.
module.exports = (env) ->

  convict = env.require 'convict'
  Q = env.require 'q'
  assert = env.require 'cassert'
  EverSocket = require('eversocket').EverSocket
  AD2USB = require 'ad2usb'

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

      # wait till all plugins are loaded
      @framework.on "after init", =>

        # Check if the mobile-frontent was loaded and get a instance
        mobileFrontend = @framework.getPlugin 'mobile-frontend'
        if mobileFrontend?

          mobileFrontend.registerAssetFile 'js', "pimatic-ad2usb/app/alarm-device-item.coffee"
          mobileFrontend.registerAssetFile 'css', "pimatic-ad2usb/app/alarm-device-item.css"
          mobileFrontend.registerAssetFile 'html', "pimatic-ad2usb/app/alarm-device-item-template.html"
        else
          env.logger.warn "The pimatic-ad2usb plugin could not find the mobile-frontend. No gui will be available"


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

    getTemplateName: ->
      "AlarmDeviceItem"

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