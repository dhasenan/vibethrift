/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements. See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership. The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
module vibethrift.server;

import std.stdio;

import core.time : seconds, Duration;
import std.exception : enforce;
import std.variant : Variant;

import thrift.base;
import thrift.protocol.base;
import thrift.protocol.processor;
import thrift.server.base;
import thrift.server.simple : TSimpleServer;
import thrift.server.transport.base;
import thrift.transport.base;
import thrift.util.cancellation;

import vibe.core.net;
import vibe.core.stream;
import vibe.core.sync;
import vibethrift.socket;

/**
 * Start providing a thrift service with the default binary protocol using vibe.
 *
 * Params:
 *   service = the service to provide
 *   bindAddress = the address to bind to. Use INADDR_ANY ("0.0.0.0") to bind to all interfaces.
 *   port = the port to listen on.
 */
void serve(Service)(Service service, string bindAddress, ushort port)
{
    import thrift.codegen.processor : TServiceProcessor;

    auto processor = new TServiceProcessor!Service(service);
    auto server = new TVibeBinaryServer(processor, bindAddress, port);
    server.serve();
}

/**
 * A Vibe-specific server that doesn't block you to the end of time.
 */
class TVibeBinaryServer : TServer
{
    ///
    this(TProcessor processor, string bindAddress, ushort port)
    {
        import thrift.protocol.binary : TBinaryProtocolFactory;
        import thrift.transport.buffered : TBufferedTransportFactory;
        super(processor, null, new TBufferedTransportFactory(), new TBinaryProtocolFactory!());
        this.bindAddress = bindAddress;
        this.port = port;
    }

    private string bindAddress;
    private ushort port;

    override void serve(TCancellation unused = null)
    {
        listenTCP(port, &newConnection, bindAddress);
    }

    void newConnection(TCPConnection conn)
    {
        auto client = new TVibeSocket(conn);
        TTransport inputTransport;
        TTransport outputTransport;
        TProtocol inputProtocol;
        TProtocol outputProtocol;

        try
        {
            scope (failure) client.close();

            inputTransport = inputTransportFactory_.getTransport(client);
            scope (failure) inputTransport.close();

            outputTransport = outputTransportFactory_.getTransport(client);
            scope (failure) outputTransport.close();

            inputProtocol = inputProtocolFactory_.getProtocol(inputTransport);
            outputProtocol = outputProtocolFactory_.getProtocol(outputTransport);
        }
        catch (TTransportException ttx)
        {
            logError("TServerTransport failed on accept: %s", ttx);
            return;
        }
        catch (TException tx)
        {
            logError("Caught TException on accept: %s", tx);
            return;
        }

        auto info = TConnectionInfo(inputProtocol, outputProtocol, client);
        auto processor = processorFactory_.getProcessor(info);

        Variant connectionContext;
        if (eventHandler)
        {
            connectionContext = eventHandler.createContext(inputProtocol, outputProtocol);
        }

        try
        {
            while (true)
            {
                if (eventHandler)
                {
                    eventHandler.preProcess(connectionContext, client);
                }

                if (!processor.process(inputProtocol, outputProtocol,
                        connectionContext) || !inputProtocol.transport.peek())
                {
                    // Something went fundamentlly wrong or there is nothing more to
                    // process, close the connection.
                    break;
                }
            }
        }
        catch (TTransportException ttx)
        {
            logError("Client died: %s", ttx);
        }
        catch (Exception e)
        {
            logError("Uncaught exception: %s", e);
        }

        if (eventHandler)
        {
            eventHandler.deleteContext(connectionContext, inputProtocol, outputProtocol);
        }

        try
        {
            inputTransport.close();
        }
        catch (TTransportException ttx)
        {
            logError("Input close failed: %s", ttx);
        }
        try
        {
            outputTransport.close();
        }
        catch (TTransportException ttx)
        {
            logError("Output close failed: %s", ttx);
        }
        try
        {
            client.close();
        }
        catch (TTransportException ttx)
        {
            logError("Client close failed: %s", ttx);
        }
    }
}

