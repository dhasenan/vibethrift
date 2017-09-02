module testapp;

import std.getopt;
import std.stdio;
import test.thrift.TestService;
import test.thrift.test_types;
import vibe.d;
import vibethrift.server;
alias DT = test.thrift.test_types.DateTime;

shared static this()
{
    string mode = "server";
    ushort port = 7711;
    readOption("m|mode", &mode, "whether to run as client or server");
    readOption("p|port", &port, "what port to use");

    if (mode == "server")
    {
        doserve(port);
    }
    else
    {
        doclient(port);
        setTimer(2.seconds, () => doclient(port), true);
    }
}

void doclient(ushort port)
{
    import thrift.codegen.client;
    import thrift.protocol.binary : TBinaryProtocol;
    import thrift.transport.buffered : TBufferedTransport;
    import thrift.transport.socket : TSocket;

    writeln("test start");
    auto socket = new TSocket("localhost", port);
    auto transport = new TBufferedTransport(socket);
    transport.open();
    auto protocol = new TBinaryProtocol!(TBufferedTransport)(transport);
    auto client = new TClient!(TestService)(protocol);
    writeln("client built");

    client.ping;

    writeln("pong");

    import std.datetime: SysTime, unixTimeToStdTime, UTC;

    auto nowUnix = client.now;
    auto stdSeconds = unixTimeToStdTime(nowUnix.epoch_seconds);
    auto dt = SysTime(stdSeconds, UTC());
    dt += nowUnix.hnseconds.dur!"hnsecs";
    writefln("now is %s", dt);

    writefln("Server says: %s", client.compliment("Zaphod"));

    transport.close;
}

void doserve(ushort port)
{
    serve!TestService(new Testy, "0.0.0.0", port);
    writeln("server started");
}

class Testy : TestService
{
    void ping()
    {
        writeln("pinged");
    }

    DT now()
    {
        import std.datetime : Clock, SysTime;
        import core.time : to;

        auto now = Clock.currTime;
        DT dt;
        dt.epoch_seconds = now.toUnixTime!long;
        dt.hnseconds = now.fracSecs.total!"hnsecs";
        return dt;
    }

    string compliment(string name)
    {
        return "You're lovely, " ~ name ~ ", absolutely adorable.";
    }
}
