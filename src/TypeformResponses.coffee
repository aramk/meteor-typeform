TypeformResponses = new Meteor.Collection('typeformResponses')

schema =
  # The Typeform form ID used to produce this response.
  formId:
    type: String
    index: true
  # The unique Typeform token for this response.
  token:
    type: String
    index: true
    # This is blank for preliminary responses until a sync populates it.
    optional: true
    # TODO(aramk) This isn't working, and it might cause issues with soft removal.
    # unique: true
  # The user who submitted the typeform.
  userId:
    type: String
    index: true
    optional: true
  'dates.start':
    type: Date
    index: true
  'dates.finish':
    type: Date
    index: true
  # The raw data from the response.
  data:
    type: Object
    blackbox: true

# Only server can modify.
TypeformResponses.allow
  insert: -> false
  update: -> false
  remove: -> false

_.extend TypeformResponses,

  getLatest: -> TypeformResponses.find({token: {$exists: true}}, {sort: 'dates.finish': -1, limit: 1}).fetch()[0]

return unless Meteor.server

_.extend TypeformResponses,

  init: (typeformId, userId, modifier = {}) ->
    date = new Date()
    modifier = Setter.merge(Objects.flattenProperties({
      formId: typeformId
      userId: userId
      dates:
        start: date
        finish: date
      data: {}
    }), modifier)
    TypeformResponses.upsert(
      {
        formId: typeformId
        userId: userId
        token: {$exists: false}
      }
      {
        $set: modifier
      }
    )
  sync: (typeformId, options) ->
    unless typeformId then throw new Meteor.Error('No typeform ID provided')

    options ?= {}
    Setter.defaults options,
      getResponses: (data) ->
        converter = new TypeformResponseConverter(formId: typeformId)
        converter.getResponses(data)

    Logger.info 'Syncing typeform responses...'
    # Use date of last stored typeform response as the start date for the query to obtain the latest
    # responses not yet synced.
    latest = TypeformResponses.getLatest()
    if latest?
      # Date is exclusive in data API, so -1 to ensure other submissions at that time are included.
      sinceDate = moment(latest.dates.finish).unix() - 1
      options = Setter.merge
        since: sinceDate
      , options
    try
      data = Promises.runSync -> Typeform.getData typeformId, options
    catch e
      Logger.error(e)
      return 0
    responses = options.getResponses(data, options)
    if _.isEmpty(responses)
      Logger.info 'No responses to sync'
      return 0
    Logger.info "Syncing #{responses.length} responses..."
    # TODO(aramk) We still need to run sanitization and validation from collection2 so not batch
    # inserting.
    # ids = Surveys.batchInsert(surveys)
    ids = []
    _.each responses, (response) ->
      existing = TypeformResponses.findOne(token: response.token)
      return if existing
      # Add userId if available
      response.userId ?= response.data?.hidden?.user_id
      try
        # Fill in the results into the preliminary response.
        selector =
          formId: typeformId
          token: {$exists: false}
        if response.userId?
          selector.userId = response.userId
        TypeformResponses.upsert(
          selector
          {$set: Objects.flattenProperties(response)}
        )
        responseId = TypeformResponses.findOne(selector)
        ids.push(responseId)
      catch err
        Logger.error('Failed to insert response', response, err)
    Logger.info 'Created', ids.length, 'Typeform responses'
    return ids.length
