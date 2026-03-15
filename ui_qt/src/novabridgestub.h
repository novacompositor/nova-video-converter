#pragma once
#include <QDebug>
#include <QObject>
#include <QString>

/// Stub bridge to Rust engine. Will be replaced by CXX-generated bridge in
/// app_bridge.
class NovaBridgeStub : public QObject {
  Q_OBJECT
  Q_PROPERTY(QString engineApiVersion READ engineApiVersion CONSTANT)

public:
  explicit NovaBridgeStub(QObject *parent = nullptr);

  QString engineApiVersion() const;

public slots:
  void dispatchCommand(const QString &commandJson);

signals:
  void engineEventReceived(const QString &eventJson);
};
