# only called when container is bound to "this"
defaultTransitions = 
  exit : ( exitingView, callback ) ->
    this.height( this.height() )
    exitingView.fadeOut 500, ->
      callback()
  prepare : ( exitingView, enteringView, callback ) ->
    # newHeight = enteringView.outerHeight() + parseInt(this.css("padding-top"), 10) + parseInt(this.css("padding-bottom"), 10)
    # this.animate
    #   height : newHeight
    # , 500, ->
    #   callback()
    callback()
  enter : ( enteringView, callback ) ->
    enteringView.fadeIn 500, ->
      callback()

do ( $ = jQuery, root = do ->
  if typeof exports isnt "undefined"
    return exports
  else
    return window
) ->

  class ViewSwitcher

    constructor : ( options ) ->
      this.views = {}
      this.hub = $({})
      {@timedOffsets, @attrIdentifier, @container, @initialView} = options
      this.attrIdentifier = options.attrIdentifier or "id"

      this.state =       
        activeView : $("")
        pastViews : []

      this.exit = options.exit or defaultTransitions.exit
      this.prepare = options.prepare or defaultTransitions.prepare
      this.enter = options.enter or defaultTransitions.enter

      # Build the views object
      switcher = this
      rawViews = options.views
      if rawViews instanceof jQuery
        rawViews.each ->
          switcher.addView( this )
      else if rawViews instanceof Array
        rawViews.forEach ( el ) ->
          switcher.addView( el )
      else if rawViews.substr
        switcher.addView( rawViews )

      # render the initial view
      this.prepare.bind( this.container, this.state.activeView, this.views[this.initialView], this.enter.bind( this.container, this.views[this.initialView], this.finishRender.bind(this, this.views[this.initialView] ) ) )()

    addView : ( view ) ->
      view = $( view )
      name = view.attr( this.attrIdentifier )
      if this.views[name]
        console.error( "A view or method named #{name} is already registered on this ViewSwitcher")
      else
        this.views[name] = view

    removeView : ( name ) ->
      this.views[name] = undefined

    selectView : ( name ) ->
      return ( this.views[name] or $( "" ) )

    switchView : ( incomingViewName ) ->
      incomingView = this.views[incomingViewName]
      # timedOffset option needs to be tested!
      if this.timedOffsets
        setTimeout this.exit.bind( this.container, incomingView, $.noop ), 0
        setTimeout this.prepare.bind( this.container, this.state.activeView, incomingView, $.noop ), options.exitDelay
        setTimeout this.enter.bind( this.container, incomingView, $.noop ), options.exitDelay + options.prepareDelay
        setTimeout this.finishRender.bind(this, incomingView ), options.exitDelay + options.prepareDelay + options.enterDelay
      else
        boundCleanup = this.finishRender.bind(this, incomingView )
        boundEnter = this.enter.bind( this.container, incomingView, boundCleanup )
        boundPrepare = this.prepare.bind( this.container, this.state.activeView, incomingView, boundEnter )
        this.exit.bind( this.container, this.state.activeView, boundPrepare )()

    finishRender : ( incomingView ) ->
      this.state.pastViews.push( this.state.activeView )
      this.state.activeView = incomingView
      this.trigger( "renderComplete", this.state.activeView )

    on : ->
      this.hub.on.apply( this.hub, arguments )
    off : ->
      this.hub.off.apply( this.hub, arguments )
    trigger : ->
      this.hub.trigger.apply( this.hub, arguments )


  return root.ViewSwitcher = ViewSwitcher
