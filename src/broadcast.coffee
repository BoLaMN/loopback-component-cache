debug = require('debug')('stash:broadcast')

{ EventEmitter } = require 'events'

class Broadcast extends EventEmitter
  constructor: (@interface, @codec, @policy, @options = {}) ->
    super()

    @channel = 'cache'
    @queue = []

    @interface.subscribe @channel
    @interface.on 'message', @receive.bind this

    @connect (err) =>
      if err
        debug err

      @flush()
      @emit 'ready'

  invalidate: (name, payload) ->

    ignore = (name) ->
      debug "broadcast:#{ name }:ignored message"

    if name isnt 'invalidate'
      return ignore()

    if typeof payload isnt 'object'
      return ignore()

    key = payload.key

    if typeof key isnt 'string'
      return ignore()

    debug 'broadcast:invalidation'

    @policy.invalidate key, (err) ->
      if err
        return callback err

    return

  receive: (channel, message) ->
    @codec.decode message, (err, result) =>
      if err
        return debug 'invalid message'

      if not result or not result.name or not result.payload
        return debug 'ignored message'

      { name, payload } = result

      @invalidate name, payload

  flush: ->
    while args = @queue.pop()
      @publish args...

  publish: (args...) ->
    if not @interface.connected
      @queue.push args
      @connect()
    else
      [ name, payload, cb ] = args

      message =
        name: name
        payload: payload

      @codec.encode message, (err, encoded) =>
        if err
          return cb err

        @interface.publish @channel, encoded, cb

  connect: (done) ->
    if @interface.connected
      return setImmediate done

    @interface.once 'ready', done

    return

module.exports = Broadcast