class @Bargraph
  constructor: (@data_src, @opts={})->
    margin = 0
    left = @opts.left || 140
    fontsize = @opts.fontsize || 13
    barh = @opts.barh || 25
    w = @opts.width || 590
    max = x = h = y = 0
    data = []

    recalcData = =>
      data = if _.isFunction(@data_src)
        @data_src(@opts)
      else
        @data_src
    recalcVars = =>
      if @opts.show_n
        data = _(data).first(@opts.show_n)

        max_label_len = 0
        _(data).map (d)->
          max_label_len = d.type.length if d.type.length > max_label_len
        left = max_label_len * fontsize/1.5

      h = data.length * barh + margin * 2
      y = pv.Scale.ordinal(pv.range(data.length)).splitBanded(0, h - margin*2, 4/5)
      max = @opts.max || 100
      x = pv.Scale.linear(0, max).range(0, w-left)

    recalcData()
    recalcVars()

    @vis = new pv.Panel()
      .margin(margin)
      .width(-> w - margin*2 - left)
      .height(-> h - margin*2)
      .left(-> left)

    @bar = @vis
      .add(pv.Bar)
        .data(-> data)
        .top(-> y(this.index))
        .width((d)-> x(d.pct)+1)
        .height(-> y.range().band)

    if @opts.colors
      colors = pv.Colors.category20()
      @bar
        .fillStyle(-> colors(this.index).color)

    @vis
      .add(pv.Rule)
        .data(-> if max <= 100 then x.ticks(max/10) else x.ticks())
        .strokeStyle((d)-> if d then 'rgba(255,255,255,0.25)' else '#000')
        .top(0)
        .left((d)-> x(d))

    @vis
      .add(pv.Rule)
        .left(0)

    overflow = (d,bar)->
      label = if d.label
        d.label
      else
          Math.round(d.pct) + '%'
      x(d.pct) <= (if label then 6+label.length*10 else 30)

    curr = -1
    label = null

    label = @bar
      .anchor('right')
      .add(pv.Label)
        .font((fontsize-3)+'px sans-serif')
        .textStyle('white')
        .textAlign('right')
        .textMargin(6)
        .textStyle (d)->
          if overflow(d,this) then 'black' else 'white'
        .textAlign (d)->
          if overflow(d,this) then 'left' else 'right'
        .visible (d)->
          if overflow(d,this) then (curr == this.index) else true
        .text (d)=>
          if d.label
            d.label
          else
            Math.round(d.pct) + '%'

    @bar
      .events(true)
      .event 'mouseover', ->
        curr = this.index
        label.render()
      .event 'mouseout', ->
        curr = -1
        label.render()

    @link = @bar
      .anchor('left')
      .add(pv.Label)
        .font(fontsize+'px sans-serif')
        .textAlign('right')
        .textMargin(5)
        .text((d)-> d.type)

    if @opts.link?
      @link
        .events(true)
        .cursor('pointer')
        .event 'click', ->
          $summary.select(if this.text().match('#') then this.text() else "#{this.text()}#*")
        .textStyle ->
          if DATA.current_details == (if this.text().match('#') then this.text() else "#{this.text()}#*")
            'black'
          else
            'rgba(0,0,0,0.5)'

    if @opts.canvas
      @vis.canvas(@opts.canvas)

    @vis.render()

    $(@vis.canvas()).css
      display: 'block'
    .bind('redraw', =>
      recalcData()
      recalcVars()

      @vis.render()
    )
