class @Histogram
  constructor: (@data_src, @opts={})->
    h = @opts.height || 120
    w = @opts.width || 270
    box_offset = -35
    data = []
    dmax = x = y = bins = 0
    median = avg = avg_bin = 0
    min = q1 = med = q2 = max = 0
    lines = []

    recalcData = =>
      data = if _.isFunction(@data_src)
        @data_src(@opts)
      else
        @data_src
    recalcVars = =>
      dmax = if @opts.max? and @opts.max>0 then @opts.max else pv.max(data.list)
      if data.box and data.box.length>0
        outlier_max = data.box[3] + 1.5 * (data.box[3]-data.box[1])
        dmax = outlier_max if dmax > outlier_max and outlier_max > 0
      if data.avg and data.avg > dmax
        dmax = data.avg * 1.1
      dmax = 0.1 if dmax == 0

      x = pv.Scale.linear(0, dmax).range(0, w)
      bins = pv.histogram(data.list).bins(x.ticks(25))
      y = pv.Scale.linear(0, pv.max(bins, (d)-> d.y)).range(0, h)

      median = data.median || 0
      avg = data.avg || 0
      if avg
        avg_bin = _(bins).detect (d)->
          avg >= d.x and d.x+d.dx >= avg

      if data.box.length > 0
        [min, q1, med, q2, max] = data.box
        lines = [min, q1, med, q2, max]

        if x(q1) - x(min) < 2
          lines.splice(0,1)

        if x(max) - x(q2) < 2
          lines.splice(-1,1)
      else
        lines = []

    recalcData()
    recalcVars()

    @vis = new pv.Panel()
      .width(w)
      .height(-> h)
      .right(14)
      .top(10)
      .left(10)
      .bottom(-> if data.box.length > 0 then 40 else 20)

    @vis
      .add(pv.Bar)
        .data(-> bins)
        .bottom(0)
        .left((d)-> x(d.x))
        .width((d)-> x(d.dx))
        .height((d)-> y(d.y))
        .fillStyle('#aaa')
        .strokeStyle('rgba(255,255,255,0.2)')
        .lineWidth(1)
        .antialias(false)

    @vis
      .add(pv.Rule)
        .visible(-> avg_bin)
        .left(-> x(avg))
        .bottom(0)
        .strokeStyle('#e11')
        .height(-> y(avg_bin.y))

    @vis
      .add(pv.Rule)
        .data(-> y.ticks(5))
        .bottom((d)-> y(d))
        .strokeStyle('#fff')

    @vis
      .add(pv.Rule)
        .data(-> x.ticks(5))
        .left((d)-> x(d))
        .bottom(-5)
        .height(5)
      .anchor('bottom')
      .add(pv.Label)
        .text (d)->
          if d == 0
            "0"
          else if d < 100
            "#{Math.round(d*100)/100.0}ms"
          else
            "#{Math.round(d/10.0)/100.0}s".replace(/(\.\d+)0+s$/,'$1s')

    @vis
      .add(pv.Rule)
        .width(w+1)
        .bottom(0)

    @vis
      .add(pv.Rule) # range line
        .visible(-> data.box.length > 0)
        .bottom(box_offset+5)
        .left(-> x(min))
        .width(-> x(Math.max(max,dmax)) - x(min))

    @vis
      .add(pv.Bar) # q1-q2 area
        .visible(-> data.box.length > 0)
        .bottom(box_offset)
        .left(-> x(q1))
        .width(-> x(q2) - x(q1))
        .height(10)
        .fillStyle('#ccc')

    @vis
      .add(pv.Rule) # top/bottom stroke
        .visible(-> data.box.length > 0)
        .data([box_offset, box_offset+10])
        .width(-> x(q2) - x(q1))
        .left(-> x(q1))
        .bottom((d)-> d)

    @vis
      .add(pv.Rule) # left/right stroke
        .visible(-> data.box.length > 0)
        .data(-> lines)
        .bottom(box_offset)
        .height(11)
        .left((d)-> x(d))

    @vis.render()

    $(@vis.canvas()).css
      display: 'block'
    .bind('redraw', =>
      recalcData()
      recalcVars()

      @vis.render()
    )
