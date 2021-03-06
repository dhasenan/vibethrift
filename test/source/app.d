module testapp;

import std.conv : to;
import std.getopt;
import std.stdio;
import test.thrift.TestService;
import test.thrift.test_types;
import vibe.d;
import vibethrift.server;
alias DT = test.thrift.test_types.DateTime;

shared static this()
{
    string host = "localhost";
    string mode = "server";
    ushort port = 7711;
    readOption("h|host", &host, "remote host");
    readOption("m|mode", &mode, "whether to run as client or server");
    readOption("p|port", &port, "what port to use");

    if (mode == "server")
    {
        doserve(port);
    }
    else
    {
        doclient(host, port);
        setTimer(2.seconds, () => doclient(host, port), true);
    }
}

void doclient(string host, ushort port)
{
    import std.datetime: SysTime, unixTimeToStdTime, UTC;
    import vibethrift.client : openClient;

    auto client = openClient!TestService(host, port);
    writeln("pinging server...");
    client.ping;
    writeln("pong! Checking time...");

    auto nowUnix = client.now;
    auto stdSeconds = unixTimeToStdTime(nowUnix.epoch_seconds);
    auto dt = SysTime(stdSeconds, UTC());
    dt += nowUnix.hnseconds.dur!"hnsecs";
    writefln("now is %s", dt);

    writefln("Server says: %s", client.compliment("Zaphod"));

    client.close;
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
        writeln("pinged from " ~ remoteAddress.to!string);
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
        return "You're lovely, " ~ name ~ ", absolutely adorable. " ~
            "And you're calling from " ~ remoteAddress.to!string;
    }
}
