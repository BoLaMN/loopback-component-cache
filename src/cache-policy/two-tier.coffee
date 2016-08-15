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

  get: (context, callback) ->
    debug 'get: %s', context.keyCache

    key = context.keyCache

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

      finish = (done) ->
        (err, data) ->
          context.result = data

          done (err) ->
            if err
              debug err

      context.raceTimeout = setTimeout =>
        debug 'cache-hit-cool: %s timeout on backend', ckey
        done = finish context.done
        context.done = null
        @decode coolResult, done
      , @refetch

      @callbacks[context.keyCache] = (result) =>
        if not context.done
          return

        done = finish context.done
        context.done = null

        clearTimeout context.raceTimeout

        if err
          @cache.emit 'fetchError', err
          return @decode coolResult, done

        debug 'cache-hit-cool: %s retrieved from backend', ckey
        done null, result

      callback()

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
