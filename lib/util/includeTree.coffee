_ = require 'lodash'

module.exports = (includes) ->

  result =
    source: []

  for include in includes
    dependencies = include.split '.'
    for dependency, index in dependencies
      if index > 0
        parent = dependencies[index - 1]
        requested = dependencies[index]
        result[parent] = result[parent] || []
        result[parent].push requested
      else
        result.source.push dependency

  result[key] = _.uniq(value) for own key, value of result
  result
