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
    if options.since?
      params.since = Numbers.parse(options.since) || moment(options.since).unix()
    df = Q.defer()

    url = @_getDataUrl(id)
    Logger.debug 'Getting typeform data', url
    response = HTTP.get url,
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

if Meteor.isClient then _.extend Typeform,
  
  whenSubmitted: (iframe) ->
    df = Q.defer()
    $iframe = $(iframe)
    _.delay ->
      intervalHandle = setInterval ->
        # TODO(aramk) This fails sometimes because iframe contents are not defined.
        try
          iframeContents = $iframe.contents()
        catch err
          # Ignore and retry.
          return
        $outro = $('.outro', iframeContents)
        $loader = $('#loader', iframeContents)
        if !$loader.is(':visible') and $outro.is(':visible')
          clearInterval(intervalHandle)
          df.resolve()
      , 1000
    , 1000
    df.promise
