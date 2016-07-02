describe 'TypeformIOResponses', ->
  
  it 'exists', -> expect(TypeformIOResponses?).to.be.true

  if Meteor.isServer
    it 'can insert docs', (test, waitFor) ->
      response = Fixtures['typeform-io-response.json']
      insertDoc =
        sessionId: response.uid
        token: response.token
        data: response
      TypeformIOResponses.insert insertDoc, waitFor (err, id) ->
        doc = TypeformIOResponses.findOne(_id: id)
        expect(doc.sessionId).to.be.defined
        expect(doc.sessionId).to.equal(response.uid)
        expect(doc.token).to.be.defined
        expect(doc.token).to.equal(response.token)
        expect(doc.data).to.deep.equal(response)
        expect(doc.dates.created).to.be.an.instanceOf(Date)
