# hotspots

a rails performance tool.

## collecting data

``` ruby
require 'memprof/tracer'
use Memprof::Tracer
```

The `Memprof::Tracer` middleware will record JSON stats about each
incoming request to `/tmp/memprof-tracer-PID.json`

## analyzing data

```
./bin/hotspots /tmp/memprof-tracer-*.json hotspots-report/
open hotspots-report/index.html
```

## screenshots

### summary

![](/tmm1/hotspots/raw/master/screenshots/summary.png)

### top controllers and actions

![](/tmm1/hotspots/raw/master/screenshots/top_controllers.png)
![](/tmm1/hotspots/raw/master/screenshots/top_actions.png)

### request/response types

![](/tmm1/hotspots/raw/master/screenshots/request_response.png)

### response time

![](/tmm1/hotspots/raw/master/screenshots/response_time.png)

### gc and objects

![](/tmm1/hotspots/raw/master/screenshots/gc.png)
![](/tmm1/hotspots/raw/master/screenshots/objects.png)

### sql

![](/tmm1/hotspots/raw/master/screenshots/sql.png)

### sort options

![](/tmm1/hotspots/raw/master/screenshots/sort_options.png)
