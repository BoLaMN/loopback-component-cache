'use strict'

{ EventEmitter } = require 'events'
assert = require 'assert'
Broadcast = require('./broadcast')

policies =
  'standard': require './cache-policy/standard'
  'two-tier': require './cache-policy/two-tier'

datastores =
  'memory': require './data-stores/memory'
  'redis': require './data-stores/redis'

interfaces =
  'redis': require './interfaces/redis'

codecs =
  'json': require './codecs/json'

class Cache extends EventEmitter
  constructor: (options = {}) ->
    super()

    @codec = codecs[options.codec]
    @metrics = increment: ->

    @datastores = []

    Object.keys(options.datastores).forEach (name) =>
      datastore = options.datastores[name]

      assert datastore.type, 'missing datastore type foe ' + name

      @datastores.push new datastores[datastore.type] datastore

    @policy = new policies[options.policy.type] this, @datastores, @codec, options.policy
    @interface = new interfaces[options.interface.type] options.interface
    @broadcast = new Broadcast @interface, @codec, @policy, options

  get: (context, callback) ->
    @metrics.increment 'get'
    @policy.get context, callback
    return

  set: (key, data, callback = ->) ->
    @metrics.increment 'set'
    @policy.set key, data, callback
    return

  invalidate: (key, callback) ->
    @metrics.increment 'invalidate'

    @policy.invalidate key, (err) =>
      if err
        return callback err

      @broadcast.publish 'invalidate', { key: key }, callback

    return

  clear: ->
    @metrics.increment 'clear'
    @datastore.clear()
    return

module.exports = Cache
