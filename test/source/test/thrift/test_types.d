/**
 * Autogenerated by Thrift Compiler (1.0.0-dev)
 *
 * DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
 *  @generated
 */
module test.thrift.test_types;

import thrift.base;
import thrift.codegen.base;
import thrift.util.hashset;

struct DateTime {
  long epoch_seconds;
  long hnseconds;
  
  mixin TStructHelpers!([
    TFieldMeta(`epoch_seconds`, 1, TReq.REQUIRED),
    TFieldMeta(`hnseconds`, 2, TReq.OPTIONAL)
  ]);
}
