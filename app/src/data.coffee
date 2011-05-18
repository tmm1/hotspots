class @Data
  constructor: (@data)->
    @current_details = '*'
    @current_compare = '*'
    @current_compare_sort = 'num_requests'

    @overall             = @data.overall
    @controllers_by_name = @data.controllers
    @actions_by_name     = @data.actions

    @controllers = for own name, controller of @controllers_by_name
      controller.name = name
      controller

    @actions     = for own name, action     of @actions_by_name
      action.name = name
      [action.controller_name, action.action_name] = name.split('#')

      controller = @controllers_by_name[action.controller_name]
      controller.actions ?= []
      controller.actions.push(action)
      action.controller = controller

      action

  byName: (name)->
    match = name.match(/^(.*)#\*$/)

    if name == '*'
      @overall
    else if match?
      @controllers_by_name[match[1]]
    else
      @controllers_by_name[name] || @actions_by_name[name]

  controllerNames: ->
    _.keys(@controllers_by_name).sort()

  allControllers: ->
    _(@controllers).sortBy((d)-> d.name)
  popularControllers: (num=5)->
    _(@controllers).chain()
      .sortBy((d)-> -d.num_requests)
      .first(num)
    .value()
  slowControllers: ->
    _(@controllers).chain()
      .sortBy((d)-> -d.response_time)
      .first(5)
    .value()

  actionNames: ->
    _(@actions_by_name).keys().sort()
  actionsIn: (name)->
    _(@controllers_by_name[name].actions).sortBy((d)-> d.name)

  allActions: ->
    _(@actions).sortBy((d)-> d.name)
  popularActions: (num=5)->
    _(@actions).chain()
      .sortBy((d)-> -d.num_requests)
      .first(num)
    .value()
  slowActions: ->
    _(@actions).chain()
      .sortBy((d)-> -d.response_time)
      .first(5)
    .value()

  requestMethods: (name=@current_details)->
    data = this.byName(name)
    _(data.request_methods).chain()
      .map (val, key)->
        type: key
        pct:  val
      .sortBy (d)->
        -d.pct
    .value()
  responseCodes: (name=@current_details)->
    data = this.byName(name)
    _(data.response_codes).chain()
      .map (val, key)->
        type: key
        pct:  val
      .sortBy (d)->
        -d.pct
    .value()
  timeBreakdown: (name=@current_details)->
    data = this.byName(name)
    _(data.time_breakdown).chain()
      .map (val, key)->
        if val > 0
          type: key
          pct:  val
      .compact()
      .sortBy (d)->
        -d.pct
    .value()
  responseTimes: (name=@current_details)->
    data = this.byName(name)
    data.response_times.median = data.response_time
    data.response_times.avg = _(data.response_times.list).avg()
    data.response_times
  gcTimes: (name=@current_details)->
    data = this.byName(name)
    data.gc_times.all ||= data.gc_times.list
    data.gc_times.list = _(data.gc_times.list).select((d)-> d>0)
    data.gc_times.median = _(data.gc_times.list).median()
    data.gc_times.avg = _(data.gc_times.list).avg()
    data.gc_times
  gcCalls: (name=@current_details)->
    data = this.byName(name).gc_calls

    num_reqs = data.list.length
    num_no_gc = _(data.list).sortedIndex(1)
    median_calls = data.list[ Math.floor(num_no_gc + (num_reqs-num_no_gc)/2) ] || 0

    data.pct_with_gc = 100 * (1 - num_no_gc/num_reqs)
    data.median_with_gc = median_calls

    data
  cpuTimes: (name=@current_details)->
    data = this.byName(name)
    data.cpu_times.median = data.cpu_time
    data.cpu_times.user_pct = data.cpu_user_time_pct
    data.cpu_times.sys_pct = data.cpu_sys_time_pct
    data.cpu_times
  ioTimes: (name=@current_details)->
    data = this.byName(name)
    data.io_times.median = data.io_time
    data.io_times.avg = _(data.io_times.list).avg()
    data.io_times
  ioBreakdown: (name=@current_details)->
    data = this.byName(name)
    _(data.io_breakdown).chain()
      .map (val, key)->
        if val > 0
          type: key
          pct:  val
      .compact()
      .sortBy (d)->
        -d.pct
    .value()
  sqlNums: (name=@current_details)->
    data = this.byName(name)
    data.sql_nums.median = data.sql_num
    data.sql_nums
  sqlBreakdown: (name=@current_details)->
    data = this.byName(name)
    _(data.sql_breakdown).chain()
      .map (val, key)->
        if val > 0
          type: if key == 'unknown' then 'other' else key.toUpperCase()
          pct: val
      .compact()
      .sortBy (d)->
        -d.pct
      .value()
  objectNums: (name=@current_details)->
    data = this.byName(name)
    data.object_nums.median = data.object_num
    data.object_nums
  objectBreakdown: (name=@current_details)->
    data = this.byName(name)
    _(data.object_breakdown).chain()
      .map (val, key)->
        if val > 0
          type: key.toUpperCase()
          pct: val
      .compact()
      .sortBy (d)->
        -d.pct
      .value()

  listByName: (name=@current_compare)->
    if name == '*'
      @controllers
    else if name == '*[popular]'
      this.popularControllers( @controllers.length/2 )
    else if name == '#*'
      @actions
    else if name == '#*[popular]'
      this.popularActions( @actions.length/2 )
    else if /#\*$/.test(name)
      @controllers_by_name[name.split('#')[0]].actions
    else
      []
  compareView: (opts)->
    opts.max = 0 if opts? and opts.max?

    _(this.listByName()).chain()
      .map (d)=>
        switch @current_compare_sort
          when 'num_requests'
            val = d.num_requests
            label = "#{val.commify()} reqs"

          when 'response_time'
            val = d.response_time
            label = val.durify(true)
          when 'response_times.min'
            val = d.response_times.list[0]
            label = val.durify(true)
          when 'response_times.max'
            val = _(d.response_times.list).last()
            label = val.durify(true)
          when 'response_times.avg'
            val = _(d.response_times.list).avg()
            label = val.durify(true)

          when 'gc_time'
            val = d.gc_time
            label = val.durify(true)
          when 'gc_times.max'
            val = _(d.gc_times.list).last()
            label = val.durify(true)
          when 'gc_times.avg'
            val = _(d.gc_times.list).avg()
            label = val.durify(true)

          when 'gc_calls.median_with_gc'
            val = this.gcCalls(d.name).median_with_gc
            label = "#{val}x"
          when 'gc_calls.max'
            val = _(d.gc_calls.list).last()
            label = "#{val}x"
          when 'gc_calls.pct_with_gc'
            val = this.gcCalls(d.name).pct_with_gc
            label = val.pctify()

          when 'cpu_times.sys_pct'
            val = this.cpuTimes(d.name).sys_pct
            label = val.pctify()
          when 'cpu_time'
            val = d.cpu_time
            label = val.durify(true)
          when 'cpu_times.max'
            val = _(d.cpu_times.list).last()
            label = val.durify(true)
          when 'cpu_times.avg'
            val = _(d.cpu_times.list).avg()
            label = val.durify(true)

          when 'io_time'
            val = d.io_time
            label = val.durify(true)
          when 'io_times.max'
            val = _(d.io_times.list).last()
            label = val.durify(true)
          when 'io_times.avg'
            val = _(d.io_times.list).avg()
            label = val.durify(true)

          when 'io_breakdown.select'
            val = d.io_breakdown['select()'] || 0
            label = val.pctify()
          when 'io_breakdown.poll'
            val = d.io_breakdown['poll()'] || 0
            label = val.pctify()
          when 'io_breakdown.read'
            val = d.io_breakdown['read()'] || 0
            label = val.pctify()
          when 'io_breakdown.write'
            val = d.io_breakdown['write()'] || 0
            label = val.pctify()

          when 'sql_num'
            val = d.sql_num
            label = val.commify() + ' queries'
          when 'sql_nums.max'
            val = _(d.sql_nums.list).last()
            label = val.commify() + ' queries'
          when 'sql_nums.avg'
            val = _(d.sql_nums.list).avg().round()
            label = val.commify() + ' queries'

          when 'sql_breakdown.select'
            val = d.sql_breakdown.select || 0
            label = val.pctify()
          when 'sql_breakdown.insert'
            val = d.sql_breakdown.insert || 0
            label = val.pctify()
          when 'sql_breakdown.update'
            val = d.sql_breakdown.update || 0
            label = val.pctify()
          when 'sql_breakdown.delete'
            val = d.sql_breakdown.delete || 0
            label = val.pctify()
          when 'sql_breakdown.unknown'
            val = d.sql_breakdown.unknown || 0
            label = val.pctify()

          when 'object_num'
            val = d.object_num
            label = val.commify() + ' objects'
          when 'object_nums.max'
            val = _(d.object_nums.list).last()
            label = val.commify() + ' objects'
          when 'object_nums.avg'
            val = _(d.object_nums.list).avg().round()
            label = val.commify() + ' objects'

          when 'object_breakdown.string'
            val = d.object_breakdown.string || 0
            label = val.pctify()
          when 'object_breakdown.hash'
            val = d.object_breakdown.hash || 0
            label = val.pctify()
          when 'object_breakdown.array'
            val = d.object_breakdown.array || 0
            label = val.pctify()
          when 'object_breakdown.node'
            val = d.object_breakdown.node || 0
            label = val.pctify()

        opts.max = val if val and opts? and opts.max < val

        if val
          type:  d.name
          pct:   val
          label: label
      .compact()
      .sortBy (d)->
        -d.pct
    .value()
