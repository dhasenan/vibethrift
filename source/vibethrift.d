module vibethrift;

import core.time : Duration;
import std.exception : enforce;
import thrift.transport.base;
import vibe.core.net : connectTCP, TCPConnection;

class TVibeSocket : TBaseTransport
{
    this(TCPConnection conn)
    {
        _conn = conn;
    }

    this(string host, ushort port)
    {
        _host = host;
        _port = port;
    }

    override bool isOpen() @property
    {
        return _conn !is null && _conn.connected;
    }

    override void open()
    {
        if (isOpen) return;
        enforce(!!_host, new TTransportException("No host; can't open socket."));
        enforce(!!_port, new TTransportException("No port; can't open socket."));
        try
        {
            _conn = connectTCP(_host, _port);
        }
        catch (Exception e)
        {
            // Would include the whole exception IF IT LET ME
            throw new TTransportException("failed to open connection to remote host: " ~ e.msg);
        }
        _conn.readTimeout = _recvTimeout;
    }

    override void close()
    {
        if (!isOpen) return;
        _conn.close();
        _conn = null;
    }

    /*
    override size_t writeSome(in ubyte[] buf)
    {
        enforce(isOpen, new TTransportException("Attempted to write to closed TVibeSocket"));
        return _conn.write(buf, IOMode.once);
    }
    */

    override void write(in ubyte[] buf)
    {
        enforce(isOpen, new TTransportException("Attempted to write to closed TVibeSocket"));
        _conn.write(buf);
    }

    override size_t read(ubyte[] buf)
    {
        enforce(isOpen, new TTransportException(
            "Cannot read if socket is not open.", TTransportException.Type.NOT_OPEN));
        auto count = buf.length;
        auto peek = _conn.peek;
        if (count > peek.length) count = peek.length;
        _conn.read(buf[0..count]);
        return count;
    }

    override bool peek()
    {
        if (!isOpen) return false;
        return _conn.peek().length > 0;
    }

    void sendTimeout(Duration value) @property
    {
        // vibe doesn't have a way to specify a write timeout?
        // probably just caches writes locally to avoid blocking...
    }

    void recvTimeout(Duration value) @property
    {
        _recvTimeout = value;
        if (isOpen)
        {
            _conn.readTimeout = value;
        }
    }


private:
    TCPConnection _conn;
    string _host;
    ushort _port;
    Duration _recvTimeout;
}
