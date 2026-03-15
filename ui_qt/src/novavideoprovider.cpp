#include "novavideoprovider.h"
#include "app_bridge/src/lib.rs.h" // cxx generated FFI
#include <QDebug>
#include <cstdint>

NovaVideoProvider::NovaVideoProvider()
    : QQuickImageProvider(QQuickImageProvider::Image) {}

QImage NovaVideoProvider::requestImage(const QString &id, QSize *size,
                                       const QSize &requestedSize) {
  // Expected id format: "path/to/media.mp4?time=1000"
  QString path = id;
  int64_t time_ms = 0;

  if (id.contains("?time=")) {
    auto parts = id.split("?time=");
    path = parts.first();
    time_ms = parts.last().toLongLong();
  } else if (id.contains("?t=")) {
    auto parts = id.split("?t=");
    path = parts.first();
    time_ms = parts.last().toLongLong();
  }

  // Remove "file://" if it is accidentally included
  if (path.startsWith("file://")) {
    path = path.mid(7);
  }

  // Call the Rust bridge
  rust::String r_path = path.toUtf8().constData();
  VideoFrameData frame_data = get_video_frame(r_path, time_ms);

  if (frame_data.width == 0 || frame_data.height == 0) {
    qWarning() << "[NovaVideoProvider] Failed to decode frame for" << path;
    // Return a red placeholder image on error
    QImage errorImg(1920, 1080, QImage::Format_RGBA8888);
    errorImg.fill(Qt::red);
    if (size)
      *size = errorImg.size();
    return errorImg;
  }

  // Copy the raw pixel data into a QImage
  // FFmpeg decode.rs scaler outputs RGBA8888 packed
  QImage img(frame_data.data.data(), frame_data.width, frame_data.height,
             QImage::Format_RGBA8888);

  // QImage doesn't own the memory created by rust::Vec, so we need to copy it
  QImage finalImg = img.copy();

  if (size) {
    *size = finalImg.size();
  }

  return finalImg;
}
