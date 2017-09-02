module vibethrift.socket;

import core.time : Duration;
import std.exception : enforce;
import thrift.transport.base;
import vibe.core.net : connectTCP, TCPConnection;
import vibe.core.stream : IOMode, Stream;
import vibe.stream.tls;

import std.stdio;

/**
 * Client Vibe socket transport.
 */
class TVibeSocket : TBaseTransport
{
    this(TCPConnection conn, bool upgradeSSL = false)
    {
        _conn = conn;
        _upgradeSSL = upgradeSSL;
        if (upgradeSSL)
        {
            auto ctx = createTLSContext(TLSContextKind.client);
            _stream = createTLSStream(_conn, ctx);
        }
        else
        {
            _stream = _conn;
        }
    }

    this(string host, ushort port, bool upgradeSSL = false)
    {
        _upgradeSSL = upgradeSSL;
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
        if (_upgradeSSL)
        {
            auto ctx = createTLSContext(TLSContextKind.client);
            _stream = createTLSStream(_conn, ctx);
        }
        else
        {
            _stream = _conn;
        }
    }

    override void close()
    {
        if (!isOpen) return;
        _conn.close();
        _conn = null;
        _stream = null;
    }

    override void flush()
    {
        if (!isOpen) return;
        _stream.flush;
    }

    override void write(in ubyte[] buf)
    {
        enforce(isOpen, new TTransportException("Attempted to write to closed TVibeSocket"));
        _stream.write(buf);
    }

    override size_t read(ubyte[] buf)
    {
        enforce(isOpen, new TTransportException(
            "Cannot read if socket is not open.", TTransportException.Type.NOT_OPEN));
        _conn.waitForData(_recvTimeout);
        auto len = _conn.peek.length;
        if (len == 0) return 0;

        if (len < buf.length) buf = buf[0..len];
        _stream.read(buf);
        return buf.length;
    }

    override void readAll(ubyte[] buf)
    {
        enforce(isOpen, new TTransportException(
            "Cannot read if socket is not open.", TTransportException.Type.NOT_OPEN));
        _stream.read(buf);
    }

    override bool peek()
    {
        if (!isOpen) return false;
        auto len = _stream.peek().length;
        return len > 0;
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
    Stream _stream;
    bool _upgradeSSL;
    string _host;
    ushort _port;
    Duration _recvTimeout;
}
