_    = require 'lodash'
util = require 'util'
includeTree = require './util/includeTree'

class QueryGenerator

  constructor: (@config) ->

  toSql: (args) ->
    args = args || {}
    args.includes = args.includes || []

    @_includeTree = includeTree args.includes

    sql = @_wrapWithJsonHandling {
      config: @config[args.source]
      includes: @_includeTree.source
    }
    sql += ';'
    sql

  _toColumnSql: (config, includes = []) ->

    self = @
    columns = config.columns.map (column) -> "#{column.table || config.table}.\"#{column.name}\" \"#{column.alias||column.name}\""

    @_getRelationshipChain config, includes, (include, relationship, relationshipConfig) ->

      relationshipIncludes = _.union(relationship.required || [], self._includeTree[include] || [])

      relationSql = self._wrapWithJsonHandling {
          config: relationshipConfig
          relationshipType: relationship.type
          includes: relationshipIncludes
          whereSql: relationship.whereSql
        }

      relationSql = "(#{relationSql}) as #{include}"
      columns.push relationSql

    _.uniq(columns).join ', '

  _wrapWithJsonHandling: (options) ->
    selectSql = "select #{@_getMethodByRelationshipType(options.relationshipType)}(#{options.config.table}) from ("
    selectSql += "select #{@_toColumnSql(options.config, options.includes)} "
    selectSql += "from #{options.config.table}"
    selectSql += " #{options.whereSql}" if options.whereSql
    selectSql += ") as #{options.config.table}"

  _getMethodByRelationshipType: (relationshipType) ->
    if relationshipType is 'list' then "json_agg" else "row_to_json"

  _getRelationshipChain: (config, includes, callback) ->
    for include in includes
      relationship = config.relationships[include]
      if relationship
        relationshipConfig = @config[relationship.config]
        callback include, relationship, relationshipConfig

module.exports = QueryGenerator