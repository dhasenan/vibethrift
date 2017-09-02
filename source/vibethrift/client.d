module vibethrift.client;

import thrift.codegen.client : TClient;

/**
 * Create and open a client.
 *
 * The default TClient doesn't include a way to close it.  This yields a wrapper that can be closed,
 * but that conflicts with RPC methods named `close`.
 *
 * This assumes a binary protocol over sockets.
 */
Client!Service openClient(Service)(string host, ushort port)
{
    import thrift.protocol.binary : TBinaryProtocol;
    import thrift.transport.buffered : TBufferedTransport;
    import thrift.transport.socket : TSocket;

    auto socket = new TSocket("localhost", port);
    auto transport = new TBufferedTransport(socket);
    transport.open();
    auto protocol = new TBinaryProtocol!(TBufferedTransport)(transport);
    return new Client!(Service)(protocol);
}

class Client(Service) : TClient!Service
{
    import thrift.protocol.base : TProtocol;
    this(TProtocol protocol) { super(protocol); }

    void close()
    {
        if (this.iprot_)
        {
            this.iprot_.transport.close;
        }
        if (this.oprot_)
        {
            this.oprot_.transport.close;
        }
    }
}
