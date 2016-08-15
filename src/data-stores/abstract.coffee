
class AbstractStore
  constructor: (options) ->
    @prefix = options.prefix or 'cache:'

  key: (key) ->
    '' + @prefix + key


module.exports = AbstractStore