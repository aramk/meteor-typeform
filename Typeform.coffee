Typeform =
  
  _config: null

  config: (config) ->
    if !@_config? or config?
      @_config ?= {
        apiUrl: 'https://api.typeform.io'
        apiVersion: 'latest'
      }
      Setter.merge(@_config, config)
    Setter.clone(@_config)

  _getUrl: -> Paths.join(@_config.apiUrl, @_config.apiVersion)

  _getHeaders: ->
    key = @_config.apiKey
    unless key then throw new Error('API key not configured.')
    {'X-API-TOKEN': key}

  authenticate: ->
    df = Q.defer()
    url = @_getUrl() + '/'
    Logger.debug('Authenticating Typeform: ' + url)
    HTTP.get url, {headers: @_getHeaders()}, Promises.toCallback(df)
    df.promise.then(
      (result) ->
        Logger.debug('Typeform authenticated', result.data)
        result.data
      (err) -> Logger.error('Typeform not authenticated', err)
    )
    df.promise

  create: (formData) ->
    df = Q.defer()
    HTTP.post Paths.join(@_getUrl(), 'forms'), {
      data: formData
      headers: @_getHeaders()
    }, Promises.toCallback(df)
    @_handleHttpResponse(df, 'crating typeform')

  delete: (data) ->
    urls = @getUrlsFromData(data)
    HTTP.del Paths.join(urls.self), {
      headers: @_getHeaders()
    }, Promises.toCallback(df)
    @_handleHttpResponse(df, 'deleting typeform')

  _handleHttpResponse: (df, action) ->
    promise = df.promise.then (result) -> result.data
    df.promise.fail (err) -> Logger.error 'Error:', action , err
    promise

  getUrlsFromData: (data) ->
    formLink = _.find data._links, (link) -> link.rel == 'self'
    renderLink = _.find data._links, (link) -> link.rel == 'form_render'
    {self: formLink.href, form_render: renderLink.href}
