// Nova bridge stub — placeholder until the real Rust FFI bridge is implemented.
// This file provides the C-side interface hooks that will be filled by
// app_bridge.

#include "novabridgestub.h"

NovaBridgeStub::NovaBridgeStub(QObject *parent) : QObject(parent) {}

QString NovaBridgeStub::engineApiVersion() const { return "0.1.0"; }

void NovaBridgeStub::dispatchCommand(const QString &commandJson) {
  qDebug("[NovaBridgeStub] Command dispatched (stub): %s",
         commandJson.toUtf8().constData());
  // TODO: forward to Rust engine via FFI
}
