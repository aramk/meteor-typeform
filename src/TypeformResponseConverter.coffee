# Converts responses from Typeform into a document following the TypeformResponses schema.
class TypeformResponseConverter

  constructor: (settings) ->
    @settings = Setter.merge {
      formId: null
    }, settings
  
  # Converts the given typeform data and field map into a response documemt.
  #  * `data` - The typeform doc from the Data API.
  getResponses: (data) ->
    responses = []
    _.each data.items, (rawResponse) =>
      # Ignore responses which aren't complete.
      return unless rawResponse.submitted_at?
      # Ignore responses which are already stored.
      metadata = rawResponse.metadata
      response =
        dates:
          start: @parseDate(rawResponse.landed_at).toDate()
          finish: @parseDate(rawResponse.submitted_at).toDate()
        token: rawResponse.token
        formId: @settings.formId ? metadata.referer.match(/to\/(\w+)/)?[1]
        data: rawResponse
      responses.push(response)
    responses

  # All dates are in UTC/GMT.
  parseDate: (date) -> moment.utc(date)

  parseValue: (formFieldId, value) ->
    # Form field IDs are prefixed with their type.
    if @_formFieldHasKeyword(formFieldId, 'number')
      Numbers.parse(value)
    else if @_formFieldHasKeyword(formFieldId, 'opinionscale')
      @_maybeParseNumber(value)
    else if @_formFieldHasKeyword(formFieldId, 'yesno') and !Types.isBoolean(value)
      value == '1'
    else
      value

  _formFieldHasKeyword: (formFieldId, keyword) -> formFieldId.indexOf(keyword) != -1

  _maybeParseNumber: (value) ->
    numValue = Numbers.parse(value)
    if Numbers.isDefined(numValue) then numValue else value
