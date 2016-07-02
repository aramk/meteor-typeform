TypeformIOResponses = new Meteor.Collection('typeformIOResponses')

schema =
  # The unique session identifier.
  sessionId:
    type: String
    index: true
  # The unique token for this response.
  token:
    type: String
    index: true
  'dates.created':
    type: Date
    index: true
    optional: true
  # The raw data from the response.
  data:
    type: Object
    blackbox: true

# Only server can modify.
TypeformIOResponses.allow
  insert: -> false
  update: -> false
  remove: -> false

TypeformIOResponses.before.insert (userId, doc) ->
  doc.dates ?= {}
  doc.dates.created = new Date()
