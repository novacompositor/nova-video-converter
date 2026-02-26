# Инструкция по сборке Nova Video Converter

Это приложение разработано на Flutter. Для корректной работы **необходимо** встроить бинарные файлы FFmpeg, так как приложение ищет их рядом с собой.

## Windows

### 1. Подготовка
1. Установите Flutter SDK.
2. Установите Visual Studio 2022 (с компонентом "Desktop development with C++").

### 2. Сборка
Выполните команду в корне проекта:
```bash
flutter build windows --release
```

### 3. Комплектация (Важно!)
После сборки перейдите в папку `build/windows/x64/runner/Release/`.
Там должен лежать файл `nova.exe`.

1. Скачайте FFmpeg для Windows (например, с [gyan.dev](https://www.gyan.dev/ffmpeg/builds/) - build 'essentials' или 'full').
2. Из скачанного архива извлеките файлы `ffmpeg.exe` и `ffprobe.exe`.
3. **Скопируйте** их в папку с `nova.exe`.

Структура папки должна быть такой:
```
Release/
  ├── nova.exe
  ├── ffmpeg.exe
  ├── ffprobe.exe
  ├── data/
  └── ...
```

Теперь папку `Release` можно запаковать в архив и распространять. При запуске `nova.exe` консоль открываться не будет.

---

## macOS

### 1. Подготовка
1. Установите Flutter SDK.
2. Установите Xcode.
3. Установите Cocoapods (`sudo gem install cocoapods`).

### 2. Сборка
Выполните команду:
```bash
flutter build macos --release
```

### 3. Комплектация
После сборки перейдите в `build/macos/Build/Products/Release/`.
Там будет лежать приложение `nova.app`.

Для встраивания FFmpeg внутрь приложения:

1. Скачайте FFmpeg для macOS (например, с [evermeet.cx](https://evermeet.cx/ffmpeg/)). Также скачайте FFprobe.
2. Кликните правой кнопкой на `nova.app` и выберите "Показать содержимое пакета" (Show Package Contents).
3. Перейдите в `Contents/Resources`.
4. **Скопируйте** туда файлы `ffmpeg` и `ffprobe`.
5. Убедитесь, что у них есть права на исполнение (`chmod +x ffmpeg ffprobe`).

Структура:
```
nova.app/
  └── Contents/
        ├── MacOS/
        │     └── nova (сам бинарник)
        └── Resources/
              ├── AppIcon.icns
              ├── ffmpeg  <-- ВАЖНО
              └── ffprobe <-- ВАЖНО
```

**Примечание:** Sandbox отключен в настройках проекта (`Release.entitlements`), чтобы разрешить запуск этих бинарников. При первом запуске macOS может спросить подтверждение безопасности для неподписанных бинарников FFmpeg (можно решить через `xattr -d com.apple.quarantine ...`).

---

## Linux
Для Linux просто положите бинарники `ffmpeg` и `ffprobe` рядом с исполняемым файлом `nova` (в папку `bundle`).
