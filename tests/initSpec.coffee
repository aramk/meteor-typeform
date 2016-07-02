describe 'initSpec', ->

  it 'clears the db', ->
    Collections.removeAllDocs(TypeformIOResponses)
