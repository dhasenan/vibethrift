namespace d test.thrift

struct DateTime
{
  1: required i64 epoch_seconds
  2: optional i64 hnseconds  // absent means 0
}

service TestService
{
  void ping()
  DateTime now()
  string compliment(1: required string name)
}
