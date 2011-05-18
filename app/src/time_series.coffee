class @TimeSeries
  constructor: ()->
    w = 580
    h = 150
    current_dot = -1

    overall_series = _(DATA.overall.time_series).chain()
      .map (val, key)->
        time: key
        num: val
      .sortBy (d)->
        d.time
      .value()
    current_series = null

    start_time = new Date(_(overall_series).first().time*1000)
    end_time   = new Date(_(overall_series).last().time*1000)

    x = pv.Scale.linear(start_time, end_time).range(0, w)
    y = pv.Scale.linear(0, _(overall_series).max((d)-> d.num).num).range(0, h)

    recalcData = =>
      if DATA.current_details == '*'
        current_series = null
      else
        current_series = _(DATA.byName(DATA.current_details).time_series).chain()
          .map (val, key)->
            time: key
            num: val
          .sortBy (d)->
            d.time
          .value()

      data = current_series || overall_series

      current_dot = -1
      max = _(data).max((d)-> d.num)
      if max
        _(data).detect (d)->
          current_dot += 1
          d.num == max.num

    recalcData()

    @vis = new pv.Panel()
      .margin(10)
      .width(w)
      .height(h)
      .bottom(25)
      .top(-> if current_series? then 0 else 35)

    @vis
      .events('all')
      .event('mousemove', pv.Behavior.point(Infinity).collapse('y'))

    @vis
      .add(pv.Rule)
        .data(y.ticks(5))
        .bottom(y)
        .strokeStyle('lightgray')

    @vis
      .add(pv.Area)
        .data(overall_series)
        .bottom(0)
        .height((d)-> y(d.num))
        .left((d)-> x(new Date(d.time*1000)))
        .fillStyle('rgba(204,204,204,0.5)')

    vis = @vis

    @vis
      .add(pv.Line)
        .data(-> current_series || overall_series)
        .bottom((d)-> y(d.num))
        .left((d)-> x(new Date(d.time*1000)))
        .strokeStyle('#1f77b4')
        .event('point', -> current_dot = this.index; vis)
        .event('unpoint', -> if current_series? then current_dot = -1; vis)
      .anchor('top')
      .add(pv.Dot)
        .fillStyle('#1f77b4')
        .size(3)
        .visible(-> current_dot == this.index)

    full_fmt = (d)->
      day_fmt(d) + ' ' + min_fmt(d)
    day_fmt = (d)->
      pv.Format.date("%a")(d) + ' ' + pv.Format.date("%m/%d")(d).replace(/(^| |\/)0+/g,'$1').toLowerCase()
    hour_fmt = (d)->
      pv.Format.date("%I%p")(d).replace(/^0*/,'').toLowerCase()
    min_fmt = (d)->
      pv.Format.date("%I:%M%p")(d).replace(/^0*/,'').toLowerCase()
    human_fmt = (d)->
      if d.getHours() == 0 and d.getMinutes() == 0 # midnight
        day_fmt(d)
      else if d.getMinutes() == 0 # top of the hour
        hour_fmt(d)
      else
        min_fmt(d)

    calcLabelXPos = ->
      data = (current_series || overall_series)
      curr = data[current_dot]
      xpos = x(new Date(curr.time*1000))
      label_w = 240

      if xpos <= label_w/2
        ['left', 0]
      else if xpos > (w-label_w/2)
        ['right', w]
      else
        ['center', xpos]
    calcLabelYPos = ->
      data = (current_series || overall_series)
      max = pv.max(data, (d)-> d.num)
      y(max) + 25

    @vis
      .add(pv.Area)
        .visible(-> current_dot > -1)
        .data([0, w])
        .height(22)
        .bottom(-> calcLabelYPos()-12)
        .left((d)-> d)
        .fillStyle('rgba(31,119,180,0.2)')

    time_slice = overall_series[1].time-overall_series[0].time

    @vis
      .add(pv.Label)
        .visible(-> current_dot > -1)
        .textBaseline('top')
        .textShadow('0.05em 0.05em 0.05em rgba(0,0,0,.5)')
        .font('13px sans-serif')
        .visible(-> current_dot != -1)
        .left(-> calcLabelXPos()[1])
        .textAlign(-> calcLabelXPos()[0])
        .bottom(-> calcLabelYPos())
        .text ->
          data = (current_series || overall_series)
          curr = data[current_dot]

          "#{full_fmt(new Date(curr.time*1000))}: #{curr.num.commify()} reqs (#{(curr.num/time_slice).round(1)}/s)"
        .textBaseline('middle')

    @vis
      .add(pv.Rule)
        .data(x.ticks())
        .left(x)
        .height(5)
        .bottom(-> -this.height())
      .add(pv.Label)
        .data(x.ticks())
        .bottom(-23)
        .text(human_fmt)
        .textAlign('center')

    @vis.render()

    $(@vis.canvas()).bind 'redraw', =>
      recalcData()
      @vis.render()
