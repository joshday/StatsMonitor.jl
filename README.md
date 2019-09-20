# StatsMonitor

## Message Format in JSON

Use JSON3 for super fast parsing.

```
{
    "API Calls": {
        "sum": 1,
        "tags": ["loonanalytics.com", "API"] (optional)
    },
    "Avg time on site": {
        "mean": 1.234,
        "tags": ["loonanalytics.com", "]
    }
}
```

## Usage

```julia
# start UDP server
@async StatsMonitor.udp_server()

# send data
function test()
    sock = UDPSocket()
    s = """
    {
        "myId": {
            "mean": $(randn()),
            "tags": ["tag 1", "tag 2"]
        }
    }
    """
    t = Timer(t -> send(sock, ip"127.0.0.1", opts.port, s), 1, interval=1/100)
    sleep(10)
    close(t)
    close(sock)
end

test()
```