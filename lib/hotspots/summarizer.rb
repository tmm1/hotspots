require 'rubygems'
require 'yajl'
require 'thin/statuses'
require 'time'

class Array
  def sum
    inject(0){ |sum, num| sum+num }
  end
end

class Distribution
  def initialize
    @samples = []
  end

  def <<(sample)
    @samples << sample if sample
    @sum = nil
  end

  def median
    size = @samples.size
    @samples.sort[size/2]
  end

  def sum
    @sum ||= @samples.sum
  end

  def to_json
    @samples.sort!
    size = @samples.size
    s = @samples

    Yajl.dump(
      :box => size > 5 && s.last != 0 ? [s.first, s[size*0.25], s[size*0.5], s[size*0.75], s.last] : [],
      :list => @samples
    )
  end
end

class TimeDistribution < Distribution
  def <<(sample)
    if sample.is_a?(Float)
      super((sample*1000).round)
    else
      super(sample)
    end
  end
end

class Breakdown
  def initialize(&blk)
    @key_blk = blk or raise ArgumentError, 'block required'
    @data = Hash.new(0)
  end

  def <<(obj)
    if key = @key_blk.call(obj)
      @data[key] += 1
    end
  end

  def to_json
    sum = @data.values.sum
    Yajl.dump(@data.inject({}) do |hash, (k,v)|
      hash[k] = (10000.0 * v/sum).round / 100.0
      hash
    end)
  end
end

class TimeSeries
  def initialize
    @buckets = Hash.new(0)
  end

  TIME_MIN = Time.parse('2011-01-01 12:00:00')

  def <<(sample)
    if sample and sample > 0 and Time.at(sample/1000) > TIME_MIN
      # @buckets[ (sample / 1000 / 600) * 600 ] += 1
      # @buckets[ (sample / 1000 / 300) * 300 ] += 1
      @buckets[ (sample / 1000 / 60) * 60 ] += 1
      # @buckets[ sample / 1000 ] += 1
    end
  end

  def to_json
    Yajl.dump(@buckets)
  end
end

class Summarizer
  IO_OPS = [ :connect, :read, :write, :recv, :send, :select, :poll ]

  def initialize(&blk)
    if @key_blk = blk
      @data = Hash.new{|h,k| h[k] = Summarizer.new }
      return
    end

    @num_requests = 0

    @response_times = TimeDistribution.new
    @gc_times = TimeDistribution.new
    @cpu_times = TimeDistribution.new
    @io_times = TimeDistribution.new

    @gc_calls = Distribution.new

    @sql_queries = Distribution.new
    @sql_breakdown = Hash.new(0)

    @objects_created = Distribution.new
    @object_breakdown = Hash.new(0)

    @request_methods = Breakdown.new{ |o|
      o[:request][:REQUEST_METHOD] if o[:request]
    }
    @response_codes  = Breakdown.new{ |o|
      if o[:response] and code = o[:response][:code]
        "#{Thin::HTTP_STATUS_CODES[code]} - #{code}"
      end
    }

    @time = Hash.new(0)
    @time_series = TimeSeries.new
  end

  def <<(obj)
    return unless obj and obj[:time]

    if @key_blk
      if key = @key_blk.call(obj)
        @data[key] << obj
      end
      return
    end

    @num_requests += 1

    @request_methods << obj
    @response_codes  << obj

    @time_series << obj[:start] if @time_series

    @response_times << obj[:time]
    @time[:total] += obj[:time]

    if gc = obj[:tracers][:gc]
      @time[:gc] += gc[:time]

      @gc_times << (gc[:calls] == 0 ? 0 : gc[:time]/gc[:calls])
      @gc_calls << gc[:calls]
    end

    if resource = obj[:tracers][:resource] || obj[:tracers][:resources]
      @cpu_times << (resource[:utime] + resource[:stime])
      @time[:cpu]+= (resource[:utime] + resource[:stime])

      @time[:utime] += resource[:utime]
      @time[:stime] += resource[:stime]

      # @time[:cpu] = @time[:utime]+@time[:stime]
    end

    if fd = obj[:tracers][:fd]
      io_time = 0

      IO_OPS.each do |op|
        if fd[op] and time = fd[op][:time]
          io_time   += time
          @time[op] += time
        end
      end

      @time[:io] += io_time
      @io_times << io_time
    end

    [ :mysql, :postgres ].each do |db|
      if sql = obj[:tracers][db] and !sql.empty?
        @sql_queries << sql[:queries]

        if types = sql[:types] and !types.empty?
          types.each do |type, val|
            @sql_breakdown[type] += val[:queries] if val and val[:queries]
          end
        end
      end
    end

    if objects = obj[:tracers][:objects]
      @objects_created << objects[:created]

      if types = objects[:types] and !types.empty?
        types.each do |type, num|
          @object_breakdown[type] += num
        end
      end
    end
  end

  def to_json
    Yajl.dump(@data || {
      :num_requests => @num_requests,

      :request_methods => @request_methods,
      :response_codes => @response_codes,

      :response_time => @response_times.median,
      :gc_time => @gc_times.median,
      :cpu_time => @cpu_times.median,
      :io_time => @io_times.median,
      :sql_num => @sql_queries.median,
      :object_num => @objects_created.median,

      :response_times => @response_times,
      :gc_times => @gc_times,
      :cpu_times => @cpu_times,
      :io_times => @io_times,
      :sql_nums => @sql_queries,
      :object_nums => @objects_created,

      :gc_calls => @gc_calls,
      :cpu_user_time_pct => @time[:cpu] == 0 ? 0 : (10000.0 *  @time[:utime]/@time[:cpu]).round / 100.0,
      :cpu_sys_time_pct  => @time[:cpu] == 0 ? 0 : (10000.0 *  @time[:stime]/@time[:cpu]).round / 100.0,

      :time_breakdown => {
        'I/O' => @time[:total] == 0 ? 0 : ((10000.0 *  @time[:io]/@time[:total]).round / 100.0),
        'GC'  => @time[:total] == 0 ? 0 : ((10000.0 *  @time[:gc]/@time[:total]).round / 100.0),
        'CPU' => @time[:total] == 0 ? 0 : ((10000.0 * @time[:cpu]/@time[:total]).round / 100.0),
      },
      :io_breakdown => IO_OPS.inject({}){ |hash, op|
        hash["#{op}()"] = (10000.0 *  @time[op]/@time[:io]).round / 100.0 if @time[op] > 0
        hash
      },
      :sql_breakdown => @sql_breakdown.inject({}){ |hash, (type,num)|
        hash[type] = (10000.0 *  num/@sql_queries.sum).round / 100.0
        hash
      },
      :object_breakdown => @object_breakdown.inject({}){ |hash, (type,num)|
        hash[type] = (10000.0 *  num/@objects_created.sum).round / 100.0
        hash
      },

      :time_series => @time_series,
    }, :pretty => true)
  end
end
