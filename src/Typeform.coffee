Typeform =
  
  _config: null

  config: (config) ->
    if !@_config? or config?
      @_config ?=
        dataUrlPrefix: 'https://api.typeform.com/forms'
      Setter.merge(@_config, config)
    Setter.clone(@_config)

  getData: (id, options) ->
    unless id? then return Q.reject('ID not provided')
    accessToken = Meteor.settings?.typeform?.accessToken
    unless accessToken? then return Q.reject('Access token not provided')

    options = Setter.merge
      key: @_getApiKey()
      completed: true
    , options
    params = _.pick(options, 'key', 'completed', 'since', 'until', 'offset', 'limit', 'token',
        'order_by', 'order_by[]')
    if options.since?
      params.since = Numbers.parse(options.since) || moment(options.since).unix()
    df = Q.defer()

    url = @_getDataUrl(id)
    Logger.debug 'Getting typeform data', url, _.omit(params, 'key')
    response = HTTP.get url,
      params: params
      headers:
        authorization: "bearer #{accessToken}"
    , Promises.toCallback(df)
    @_handleHttpResponse(df, 'querying typeform data')

  # Returns a promise containing all the data from the API by making paginated calls, since
  # Typeform won't return the full set of responses for large datasets.
  getAllData: (id, options) ->
    df = Q.defer()
    options = Setter.merge
      offset: 0
      limit: 300
    , options
    
    offset = options.offset
    limit = options.limit
    totalLimit = options.totalLimit

    responses = []
    firstResponse = null

    getNextPage = =>
      nextOptions = Setter.merge {}, options, {offset: offset}
      @getData(id, nextOptions)
        .then(Meteor.bindEnvironment((response) ->
          firstResponse ?= response
          responses.push(response.responses...)
          showing = response.stats?.responses?.showing
          if showing > 0 and (!totalLimit? or responses.length < totalLimit)
            offset += showing
            getNextPage()
          else
            if totalLimit?
              firstResponse.responses = responses.slice(0, totalLimit)
            else
              firstResponse.responses = responses
            firstResponse.stats?.responses?.showing = responses.length
            df.resolve(firstResponse)
        )).fail(df.reject).done()

    getNextPage()
    
    df.promise

  _getDataUrl: (id) -> Paths.join(@_config.dataUrlPrefix, id, 'responses')

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
        if !$('#loader', iframeContents).is(':visible') and $('[data-qa*="thank-you-screen-visible"]', iframeContents).is(':visible')
          clearInterval(intervalHandle)
          df.resolve()
      , 1000
    , 1000
    df.promise
