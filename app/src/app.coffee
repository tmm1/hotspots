pv.max = (array, f)->
  if array.length > 100000
    f ||= (d)->d
  ret = _(array).max(f)
  if f? then f(ret) else ret

_.mixin
  sum: (obj, iterator, context) ->
    _.reduce obj, ((sum, num) -> sum + if iterator then iterator(num) else num), 0, context
  median: (obj) ->
    sorted = _.map(obj, (d)-> d).sort()
    sorted[Math.floor(sorted.length/2)]
  avg: (obj, iterator, context) ->
    sum = _.sum obj, iterator, context
    sum / obj.length

Number::commify = ->
  [num, decimal] = "#{this}".split('.')
  decimal = if decimal then ".#{decimal}" else ''

  rgx = /(\d+)(\d{3})/
  while rgx.test(num)
    num = num.replace(rgx, '$1,$2')

  num + decimal

Number::durify = (space=false)->
  if this >= 1000
    "#{Math.round(this/100)/10}#{if space then ' ' else ''}s"
  else
    "#{Math.round(this)}#{if space then ' ' else ''}ms"

Number::pctify = ()->
  Math.round(this) + '%'

Number::round = (decimals=0)->
  Math.round(this*Math.pow(10,decimals)) / Math.pow(10,decimals)

String::lpad = (len, padding=' ')->
  return this if this.length > len

  str = this
  for num in [0..(len-str.length)]
    str = "#{padding}#{str}"
  str

# Stub data.
#@DATA = new Data
#  overall:
#    response_time: 291
#    num_requests: 3082
#  controllers:
#    'search':
#      response_time: 312
#      num_requests: 2139
#    'admin':
#      response_time: 402
#      num_requests: 943
#  actions:
#    'search#fulltext':
#      response_time: 503
#      num_requests: 1959
#    'search#by_title':
#      response_time: 110
#      num_requests: 180
#    'admin#index':
#      response_time: 102
#      num_requests: 323
#    'admin#regenerate':
#      response_time: 664
#      num_requests: 620

