# hotspots

a rails performance tool.

## collecting data

``` ruby
require 'memprof/tracer'
config.middleware.use Memprof::Tracer
```

The `Memprof::Tracer` middleware will record JSON stats about each
incoming request to `/tmp/memprof_tracer-PID.json`

## analyzing data

```
bundle install
./bin/hotspots /tmp/memprof_tracer-*.json hotspots-report/
open hotspots-report/index.html
```

## screenshots

### summary

![](screenshots/summary.png)

### top controllers and actions

![](screenshots/top_controllers.png)
![](screenshots/top_actions.png)

### request/response types

![](screenshots/request_response.png)

### response time

![](screenshots/response_time.png)

### gc and objects

![](screenshots/gc.png)
![](screenshots/objects.png)

### sql

![](screenshots/sql.png)

### sort options

![](screenshots/sort_options.png)
