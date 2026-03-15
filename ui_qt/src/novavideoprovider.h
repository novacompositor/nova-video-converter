#pragma once

#include <QImage>
#include <QQuickImageProvider>
#include <QSize>
#include <QString>

class NovaVideoProvider : public QQuickImageProvider {
public:
  NovaVideoProvider();

  // Override requestImage to supply our FFmpeg decoded frames
  QImage requestImage(const QString &id, QSize *size,
                      const QSize &requestedSize) override;
};
