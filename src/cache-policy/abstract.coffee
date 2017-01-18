'use strict'

debug = require('debug')('loopback:cache:abstract')
async = require 'async'

class CachePolicy
  constructor: (@options = {}) ->
    @prefix = @options.prefix or 'cache'

  key: (key) ->
    @prefix + ':' + key

  decode: (encodedValue, callback) ->
    @codec.decode encodedValue, (err, decoded) =>
      if err
        @cache.emit 'decodeError', err
        return callback(err)

      callback null, decoded

  encode: (value, callback) ->
    @codec.encode value, (err, encoded) =>
      if err
        @cache.emit 'encodeError', err
        return callback err

      callback null, encoded

  invalidate: (key, callback) ->
    debug 'invalidate: %s', key

    invalidate = (datastore, done) =>
      datastore.del @key(key), (err) =>
        if err
          @cache.emit 'persistenceError', err
        done err

    async.each @datastores, invalidate, callback

    return

module.exports = CachePolicy