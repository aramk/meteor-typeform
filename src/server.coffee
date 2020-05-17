# Sets up proxy endpoints for passing typeform requests through the Meteor server. This is
# necessary when loading typeforms in iframes in order to detect when they have been submitted,
# since the content of iframes cannot be observed unless it is loaded from the same host.

{URLSearchParams} = Npm.require('url')

HTTP.methods

  # Form load.
  'typeform/:username/:id': ->
    username = @params.username
    id = @params.id
    unless username? and id?
      throw new Meteor.Error(500, 'Invalid typeform username and ID')
    url = "https://#{@params.username}.typeform.com/to/#{@params.id}"
    @addHeader('Content-Type', 'text/html')
    proxyTypeform.call(@, url)

  # Token request on form load. :type can be 'default' or 'touch'.
  'app/form/result/token/:id/:type': ->
    info = getRefererInfo.call(@)
    url = "https://#{info.username}.typeform.com/app/form/result/token/#{info.id}/default"
    proxyTypeform.call(@, url)

  # Upload credentials request.
  # e.g. app/form/field/uploadCredentials/13156738?uploadStrategy=xhr
  'app/form/field/uploadCredentials/:id': ->
    info = getRefererInfo.call(@)
    id = @params.id
    url = "https://#{info.username}.typeform.com/app/form/field/uploadCredentials/#{id}"
    @addHeader('Content-Type', 'application/json')
    proxyTypeform.call(@, url)

  # Form submit.
  'app/form/submit/:id': post: (data) ->
    info = getRefererInfo.call(@)
    url = "https://#{info.username}.typeform.com/app/form/submit/#{info.id}"
    @addHeader('Content-Type', 'application/json')
    proxyTypeform.call @, url,
      method: 'POST'
      data: data
  
  'forms/:id/start-submission': post: (data) ->
    info = getRefererInfo.call(@)
    url = "https://#{info.username}.typeform.com/forms/#{info.id}/start-submission"
    @addHeader('Content-Type', 'application/json')
    proxyTypeform.call @, url,
      method: 'POST'
      data: data
  
  'forms/:id/complete-submission': post: (data) ->
    info = getRefererInfo.call(@)
    url = "https://#{info.username}.typeform.com/forms/#{info.id}/complete-submission"
    @addHeader('Content-Type', 'application/json')
    proxyTypeform.call @, url,
      method: 'POST'
      data: data

  'bundles/quickyformapp/js/build/attributionUtil.js': -> scriptProxy.apply(@, arguments)
  'bundles/quickyformapp/js/build/trackingClient.js': -> scriptProxy.apply(@, arguments)

scriptProxy = ->
  info = getRefererInfo.call(@)
  url = "https://#{info.username}.typeform.com#{@request.originalUrl}"
  proxyTypeform.call(@, url)

# Proxy request for Typeform to allow accessing the contents of iframes to determine when the
# typeform has been submitted.
# http://stackoverflow.com/questions/364952
proxyTypeform = (url, options) ->
  requestHeaders = getProxyHeaders.call(@)
  options = Setter.merge
    url: url
    method: 'GET'
    headers: requestHeaders
    params: @query
  , options

  form = options.form
  if form?
    options.form = form
    return Request.call(options)
  else
    writer = @createWriteStream()
    HTTP.call options.method, url, options, (err, result) =>
      if err
        msg = "Failed to load typeform"
        Logger.error(msg, err)
        writer.end(msg)
        return
      _.each result.headers, (value, key) => @addHeader key, value
      writer.end(result.content)
    # Prevent returning anything since we are writing to stream.
    return undefined

# Set request headers so Typeform thinks we're a brower and generates an interactive form.
getProxyHeaders = ->
  requestHeaders = {}
  acceptedHeaders = ['connection', 'cache-control', 'accept', 'user-agent', 'accept-language',
      'cookie']
  _.each acceptedHeaders, (key) =>
    requestHeaders[key] = @requestHeaders[key]
  # Avoid any compression since we don't support deflating on the server like a browser.
  requestHeaders['accept-encoding'] = 'identity'
  requestHeaders

getRefererInfo = ->
  referer = @requestHeaders.referer
  match = referer.match /typeform\/(\w+)\/(\w+)/
  unless match
    throw new Meteor.Error "Could not parse referer: #{referer}"
  {username: match[1], id: match[2]}

serializeQuery = (query) ->
  params = new URLSearchParams()
  _.each query, (value, param) ->
    params.set(param, value)
  params.toString()
