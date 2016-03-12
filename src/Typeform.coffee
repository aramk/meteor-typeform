Typeform =
  
  _config: null

  config: (config) ->
    if !@_config? or config?
      @_config ?=
        dataUrlPrefix: 'https://api.typeform.com/v0/form'
      Setter.merge(@_config, config)
    Setter.clone(@_config)

  getData: (id, options) ->
    unless id
      return Q.reject('ID not provided')
    options = Setter.merge
      key: @_getApiKey()
      completed: true
    , options
    params =
      key: options.key
      completed: options.completed
    if options.since? then params.since = moment(options.since).unix()
    df = Q.defer()

    response = HTTP.get @_getDataUrl(id),
      params: params
    , Promises.toCallback(df)
    @_handleHttpResponse(df, 'querying typeform data')

  _getDataUrl: (id) -> Paths.join(@_config.dataUrlPrefix, id)

  _getApiKey: ->
    key = @_config.apiKey
    unless key then throw new Error('API key not configured.')
    key

  _handleHttpResponse: (df, action) ->
    promise = df.promise.then (result) -> result.data
    df.promise.fail (err) -> Logger.error 'Error:', action , err
    promise
