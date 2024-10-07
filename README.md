# Zarbo Widget SDK for iOS

SDK состоит из библиотеки (**ZarboWidgetSDK**) как xcframeworks.

## Возможности SDK
- Показ 3D модели с получением статусов и процесса загрузки
- Масштабирование, позиционирование в пространстве AR модели
- Возможность шаринга ссылки, указанонй из мобильного приложения
- Поддержка приложений с циклом управления на **UIKit**

## Требования и ограничения

Для работы **ZarboWidgetSDK** необходима iOS версии 14.0 или выше.

## Подключение
### Через XCode и xcframeworks
SDK можно подключить с помощью непосредственного добавления **ZarboWidgetSDK.xcframework** в проект.
Для этого нужно скачать архив  **ZarboWidgetSDK.xcframework.zip** распаковать и добавить ссылку на библиотеку в секцию **Frameworks, Libraries and Embedded Content**:

![img-xcode-xcframeworks]

## Подготовка к работе

Вначале вам понадобится получить от Zarbo **API_KEY** ключ сервиса и хост (**API_HOST**).
Для этого вам необходимо связаться по адресу info@zarbo.tech.
Для работы с AR В мобильном приложении необходимо добавить в Info.plist разрешение "Privacy - Camera Usage Description" (**NSCameraUsageDescription**).

## Начало работы

Для начала работы в AppDelegate нужно инициализировать конфигурацию Zarbo.configuration (**ZarboConfiguration**), используя следующие обязательные параметры:
- **apiKey**: API ключ для работы с сервисом.
- **host**: название хоста или сервера.

Для показа 3D модели в **UIKit** используется метод **presentModelView**, который вызывается у сконфигурированного синглота или экземпляра sdk (**Zarbo**). Метод принимает следующие параметры:
- **sku**: артикул товара модели.
- **previewType**: опциональный тип для превью модели. По-умолчанию используется .qlPreview (системный компонент).
Тип .zarbo(urlToShare: URL?) использует ARKit и увеличивает расход памяти. Но позволяет шарить свою ссылку и др.:
```swift
    /// Тип контроллера для отображение 3D модели
    public enum ZarboPreview {
        // ARQuickLook - стандартный просмотрщик
        case qlPreview
        // Превью с помощью контроллера Zarbo. Увеличивает расход памяти
        case zarbo(urlToShare: URL?)
    }
```
- **presenting**: ссылка на экземпляр UIViewController, с которого происходит показ.
- **onProgress**: замыкание, которое вызывается с параметром **progress** при скачивании файла. Float значение от 0 до 1.
- **onCompleted**: замыкание, которое выдаёт результат в виде параметра **result** с типом-перечислением **ZarboCompletion**.
**ZarboCompletion** - это перечисление со значениями: **error(Error)** (с типом ошибки Error),**success**(успешно) и **cancelled** (показ отменён).
```swift
        public enum ZarboCompletion {
          case cancelled
          case error(_ error: Error)
          case success
    }
```

Результатом вызова **presentModelView** является статус (тип-перечисление) **ZarboStatus**:
```swift
    /// Тип результата статуса
        public enum ZarboStatus {
          case arIsNotSupported
          case sdkIsNotConfigured
          case start
    }
```
, где последнее значение **ZarboStatus.start** означает успешный запуск SDK, а первые 2 с соответствующей их названию ошибкой.

## Пример создания экземпляра SDK

### Пример использования в UIKit приложении

```swift
        let status = Zarbo.presentModelView(
            sku: MODEL_SKU, // артикул модели
            previewType: ZARBO_PREVIEW_TYPE, // опциональный параметр, по-умолчанию системный .qlPreview
            presenting: VIEW_CONTROLLER //UIViewController, откуда запускается экран
        ) { progress in
            // TODO: Обработать вывести прогресса скачивания
            print(progress)
        } onCompleted: { [weak self] result in
            guard let self else { return }
            
            switch (result) {
            case .error(let error):
                // TODO: Обработать вывод ошибки
                print(error.localizedDescription)
            case .cancelled:
                // TODO: Обработать - Показ отменён, например, при скачивании
                print("Cancelled")
            case .success:
                // TODO: Обработать успешный показ
                print("Success")
            @unknown default:
                break
            }
        }
        
        switch status {
        case .arIsNotSupported:
            // TODO: Обработать - AR не поддерживается на этом устройстве
            break
        case .start:
            // TODO: Обработать запуск ZarboWidget
            break
        case .sdkIsNotConfigured:
            // TODO: Обработать ZarboWidgetSDK не сконфигурирован
            break
        @unknown default:
            break
        }
```

## Поддержка

По всем возникающим вопросам, доработкам и предложениям обращаться https://t.me/kdimitry

[img-xcode-xcframeworks]: images/xcode_xcframeworks.png
