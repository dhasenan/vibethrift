# vibethrift: Thrift RPCs, Vibe-friendly!

Thrift is an RPC mechanism with some interesting properties.

Vibe.d is a painless non-blocking IO framework for the D programming language.

Match made in heaven, yes? And now it's here! Joy for all!


## Server-side usage

On the server side, we make some default assumptions about your usage -- primarily that you're using
the binary protocol.

```D
import vibe.d;
import vibethrift.server;
import my.generated.service;

class MyServiceHandler : MyService
{
    // Your code here!
}

shared static this()
{
    auto listenAddress = "0.0.0.0";
    ushort port = 9172;
    serve(new MyServiceHandler(), listenAddress, port);

    // And now you can maybe run a web server too, or run several services, or something like that.
}
```

Sorry, no SSL support just yet.


## Client-side usage

You can use the `vibethrift.socket.TVibeSocket` class as a drop-in replacement for `TSocket`.
Alternatively, you can use the `vibethrift.client.openClient` method. This returns a wrapped client
that adds a `close` method for closing the transport.

The downside is that this shadows an RPC with the signature `void close()`. So in that case, you'll
probably need to use `TVibeSocket`.

