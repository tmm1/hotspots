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
