'use strict'

debug = require('debug')('loopback:cache:two-tier')

CachePolicy = require './abstract'
async = require 'async'

class TwoTierCachePolicy extends CachePolicy
  constructor: (@cache, @datastores, @codec, @options) ->
    super()

    @callbacks = {}

    @refetch = 0.5 * 1000
    @ttl = [ 30, 60 ] or @options.ttl

  get: (key, callback) ->
    debug 'get: %s', key

    hkey = @key key + ':h'
    ckey = @key key + ':c'

    datastores = [
      (cb) => @datastores[0].get hkey, cb
      (cb) => @datastores[1].get ckey, cb
    ]

    async.parallel datastores, (err, result) =>
      if err
        @cache.emit 'persistenceError', err
        return callback()

      [ hotFlag, coolResult ] = result

      if not coolResult
        return callback()

      if hotFlag
        debug 'cache-hit-hot: %s', hkey
        return @decode(coolResult, callback)

      debug 'cache-hit-cool: %s', ckey

      raceTimeout = setTimeout =>
        debug 'cache-hit-cool: %s timeout on backend', ckey
        c = callback
        callback = null
        @decode coolResult, c
      , @refetch

      @callbacks[key] = (result) =>
        if not callback
          return

        c = callback
        callback = null

        clearTimeout craceTimeout

        if err
          @cache.emit 'fetchError', err
          return @decode coolResult, c

        debug 'cache-hit-cool: %s retrieved from backend', ckey
        c null, result

      return
    return

  set: (key, result, callback) ->
    debug 'set: %s', key

    if @callbacks[key]
      @callbacks[key] result

    hkey = @key key + ':h'
    ckey = @key key + ':c'

    @encode result, (err, compressed) =>
      if err
        return callback null, result

      datastores = [
        (cb) => @datastores[0].set hkey, '1', @ttl[0], cb
        (cb) => @datastores[1].set ckey, compressed, @ttl[1], cb
      ]

      async.parallel datastores, (err) =>
        if err
          @cache.emit 'persistenceError', err

        callback null, result

module.exports = TwoTierCachePolicy
