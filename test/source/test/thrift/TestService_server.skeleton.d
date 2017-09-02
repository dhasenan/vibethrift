/*
 * This auto-generated skeleton file illustrates how to build a server. If you
 * intend to customize it, you should edit a copy with another file name to 
 * avoid overwriting it when running the generator again.
 */
module test.thrift.TestService_server;
version (TestServiceSkeleton)
{

import std.stdio;
import thrift.codegen.processor;
import thrift.protocol.binary;
import thrift.server.simple;
import thrift.server.transport.socket;
import thrift.transport.buffered;
import thrift.util.hashset;

import test.thrift.TestService;
import test.thrift.test_types;


class TestServiceHandler : TestService {
  this() {
    // Your initialization goes here.
  }

  void ping() {
    // Your implementation goes here.
    writeln("ping called");
  }

  DateTime now() {
    // Your implementation goes here.
    writeln("now called");
    return typeof(return).init;
  }

  string compliment(string name) {
    // Your implementation goes here.
    writeln("compliment called");
    return typeof(return).init;
  }

}

void main() {
  auto protocolFactory = new TBinaryProtocolFactory!();
  auto processor = new TServiceProcessor!TestService(new TestServiceHandler);
  auto serverTransport = new TServerSocket(9090);
  auto transportFactory = new TBufferedTransportFactory;
  auto server = new TSimpleServer(
    processor, serverTransport, transportFactory, protocolFactory);
  server.serve();
}
}
