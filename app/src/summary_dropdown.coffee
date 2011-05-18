class @SummaryDropdown
  @template: (str)->
    (obj)->
      $(
        str.replace /\{(.+?)\}/g, (all,match) ->
          obj[match] || ''
      )

  @entryTemplate = @template(
    '''
    <div class="entry" name="{name}">
      <div class="name">{name}</div>
      <div class="num">{num}</div>
    </div>
    '''
  )

  constructor: (@self)->
    @self ?= $('.summary.dropdown')
    @more = @self.find('.more')

    this.attachBehaviors()

  attachBehaviors: ->
    # @self.find('.current')
    #   .click =>
    #     @self.toggleClass('open')
    #     @more.slideToggle('fast')
    #     false

    $('.entry', @more[0])
      .live 'click', (event) =>
        target = $(event.currentTarget)
        this.select(target.attr('name'), target)
        false

    true

  select: (name, clicked = null)->
    data = DATA.byName(name)

    @self.find('.entry.current').removeClass('current')

    if name == '*'
      this.updateActions()
      @self.find('.controllers .entry.all').addClass('current')

    else if name.match(/#\*$/)
      @self.find(".controllers .entry[name='#{data.name}']:first").addClass('current')
      this.updateActions(data.name)
      @self.find(".actions .entry[name='#{name}']:first").addClass('current')

    else if data.controller_name
      this.updateActions()
      action = @self.find(".actions .entry[name='#{name}']:first")
      if action.length
        action.addClass('current')
      else
        @self.find(".controllers .entry[name='#{data.controller_name}']:first").addClass('current')
        this.updateActions(data.controller_name)
        @self.find(".actions .entry[name='#{name}']:first").addClass('current')

    else
      if clicked
        clicked.addClass('current')
      else
        @self.find(".controllers .entry[name='#{data.name}']:first").addClass('current')
      this.updateActions(data.name)
      return

    @self.find('.current span.label').text(
      "#{data.num_requests.commify()} requests " + if name == '*'
        "total"
      else
        "to #{data.name}" + (if data.name.match(/#/) then '' else '#*')
    )

    @more.slideUp ->
      DATA.current_details = name
      $.event.trigger('redraw')

    true

  updateActions: (controller)->
    section = @self.find('section.actionsIn')
    section.find('.entry').remove()

    unless controller
      section.hide()
    else
      section.find('h3').text("actions in #{controller}")
      data = DATA.actionsIn(controller)

      @constructor.entryTemplate
        name: "#{data.length} actions"
        num: "#{_(data).sum((d)-> d.num_requests).commify()} requests"
      .addClass('all')
      .attr('name', "#{controller}#*")
      .appendTo(section)

      for datum in data
        @constructor.entryTemplate
          name: datum.name
          num:
            if /^slow/.test(name)
              "#{datum.response_time.commify()} ms"
            else
              "#{datum.num_requests.commify()} reqs"
        .appendTo(section)

      section.show()

    true

  update: ->
    for name in ['popularControllers','popularActions','slowControllers','slowActions','allControllers']
      section = @self.find("section.#{name}")
      section.find('.entry').remove()

      data = DATA[name]()

      if /^all/.test(name)
        @constructor.entryTemplate
          name: "#{data.length} controllers"
          num: "#{_(data).sum((d)-> d.num_requests).commify()} requests"
        .addClass('all')
        .addClass('current')
        .attr('name', '*')
        .appendTo(section)

      for datum in data
        @constructor.entryTemplate
          name: datum.name
          num:
            if /^slow/.test(name)
              "#{datum.response_time.commify()} ms"
            else
              "#{datum.num_requests.commify()} reqs"
        .appendTo(section)

    true
