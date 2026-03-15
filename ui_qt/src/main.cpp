#include "novabridgestub.h"
#include "novavideoprovider.h"
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QTimer>

int main(int argc, char *argv[]) {
  // HiDPI: let Qt auto-detect scale factor
  QGuiApplication::setHighDpiScaleFactorRoundingPolicy(
      Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);

  QGuiApplication app(argc, argv);

  // ── App metadata ──────────────────────────────────────────────────────────
  app.setApplicationName("NovaCompositor"); // Must match the desktop file name
  app.setApplicationVersion("0.1.0");
  app.setOrganizationName("Nova Compositor Team");
  app.setOrganizationDomain("novacompositor.app");
  app.setDesktopFileName("novacompositor");

  // ── App icon ──────────────────────────────────────────────────────────────
  app.setWindowIcon(QIcon(":/resources/icons/nova_app_icon.png"));

  // ── Qt Quick style ─────────────────────────────────────────────────────────
  QQuickStyle::setStyle("Basic"); // We use custom NovaTheme

  // NOTE: Inter font files can be placed in ui_qt/resources/fonts/ for
  // bundling. Without them, Qt will fall back to a system sans-serif font.

  // ── QML Engine ────────────────────────────────────────────────────────────
  QQmlApplicationEngine engine;

  // Register the NovaVideoProvider to handle image://videoframe/... URLs
  engine.addImageProvider(QLatin1String("videoframe"), new NovaVideoProvider);

  // Expose App Bridge to QML
  static NovaBridgeStub appBridge;
  engine.rootContext()->setContextProperty("appBridge", &appBridge);

  // Expose app version to QML
  engine.rootContext()->setContextProperty("APP_VERSION",
                                           app.applicationVersion());
  engine.rootContext()->setContextProperty("APP_SPLASH_PATH",
                                           "qrc:/resources/splash/splash.png");

  // ── Load main QML ─────────────────────────────────────────────────────────
  const QUrl url(QStringLiteral("qrc:/NovaCompositor/qml/Main.qml"));
  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreated, &app,
      [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
          QCoreApplication::exit(-1);
        }
      },
      Qt::QueuedConnection);

  // ── Tell engine to look for modules inside the embedded resources ──────────
  // The NovaCompositor QML module lives at qrc:/NovaCompositor/qmldir.
  // Without this, Qt 6.4 won't find it when processing 'import NovaCompositor'.
  engine.addImportPath(QStringLiteral("qrc:/"));

  engine.load(url);

  return app.exec();
}
