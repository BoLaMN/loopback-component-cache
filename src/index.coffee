debug = require('debug')('loopback:cache:component')

{ defaults } = require 'lodash'

Cache = require './cache'

module.exports = (app, options = {}) ->

  options = defaults
    codec: 'json'
    datastores:
      local:
        type: 'memory'
    policy:
      type: 'standard'
      ttl: 300 # seconds
      prefix: 'cache'
    interface:
      type: 'redis'
      host: app.get 'REDIS_HOST'
  , options

  app.cache = new Cache options

  return