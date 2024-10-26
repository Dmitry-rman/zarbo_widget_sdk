# Zarbo Widget SDK for iOS

SDK состоит из библиотеки (**ZarboWidgetSDK**) как xcframeworks.

## Возможности SDK
- Показ USDZ 3D модели
- Показ ZWB пакета
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

Опционально для работы с функциями поиска по SKU вам может понадобится получить от Zarbo **API_KEY** ключ сервиса и хост (**API_HOST**). Запуск пакетов ZWB и USDZ моделей производится без этих параметров.
Для этого вам необходимо связаться по адресу info@zarbo.tech.
Для работы с AR В мобильном приложении необходимо добавить в Info.plist разрешение "Privacy - Camera Usage Description" (**NSCameraUsageDescription**).

## Начало работы

Для начала работы в AppDelegate нужно инициализировать конфигурацию Zarbo.configuration (**ZarboConfiguration**), используя следующие обязательные параметры:
- **apiKey**: опциональный API ключ (для работы с сервисом поиска SKU).
- **host**: опциональное название хоста или сервера (для работы с сервисом поиска SKU).
Пример:
```swift
ZarboSDK.configuration = .init(apiKey: ZARBO_API_KEY, host: ZARBO_HOST, playerType: .zarbo)
```
, где **playerType** - это тип просмотрщика для показа моделей.
Возможные варианты zarbo(более гибки в UI и увелививает размер памяти) и стандартный просмотрщик **qlPreview**(ARQuickLook).
Если разработчиком не используется метод поиска по SKU, то параметра apiKey и host можно оставить пустыми.

Для показа USDZ 3D модели в **UIKit** используется метод **showUSDZ**, который вызывается у сконфигурированного синглота или экземпляра sdk (**ZarboSDK**):
```swift
    /*
    Функция показывает виджет
    **Parameters:**
        - modelUrl:  локальный URL USDZ модели
        - urlToShare:   URL для шаринга (работает только для zarbo preiew)
        - title:  заголовок (работает только для zarbo preiew)
        - on:  контроллер для презентации виджета
        - modelDirectoryUrl: URL директории, где находится usdz модель
    */
    func showUSDZ(
        modelUrl: URL,
        urlToShare: URL? = nil,
        title: String? = nil,
        on viewController: UIViewController
    ) -> ZWMStatus
```

Результатом вызова **showPackage** является статус (тип-перечисление) **ZWMStatus**:
```swift
    /// Статус запуска SDK
    public enum ZWMStatus {
        // Успешный старт
        case start 
        // AR не поддерживается
        case arIsNotSupported
        // Успешный показ
        case showed
        // в SDK нет важных данных для запуска
        case sdkIsNotConfigured
        // Ошибка показа
        case error(_ error: Error)
    }
```
, где значение **ZWMStatus.start** означает успешный запуск SDK.

Для показа ZWB виджета есть метод **showPackage** с параметрами:
```swift
    /**
    Функция показывает виджет
    **Parameters:**
        - widget: модель виджета
        - on:  контроллер для презентации виджета
        - modelDirectoryUrl: URL директории
    */
    func showPackage(
        widget: ZWWidget,
        on viewController: UIViewController
    ) -> ZWMStatus 
```

В SDK предусмотрен метод для десериализации виджета **ZWMWidget** из **Data**, используя функцию **getWidget** c параметром:
```swift
    /**
    Функция генерирует виджет по Data
    **Parameters:**
        - data: бинарные данные виджета
    */
    func getWidget(data: Data) throws -> ZWWidget
```

Если перед разработчиком стоит задача просто загрузить ZWB файл пакета и показать его автономно, то для показа пакета ZWB из бинарных данных можно использовать готовый метод **showPackage** со следующими параметрами:
```swift
    /**
    Функция показывает виджет
    **Parameters:**
        - data:  Данные пакета
        - on:  контроллер для презентации виджета
        - onCompleted: замыкание для результата показа
    */
    func showPackage(
        data: Data,
        on viewController: UIViewController,
        onCompleted: @escaping (ZarboCompletion) -> Void
    ) -> ZWMStatus 
```
**onCompleted**: замыкание для результата показа, которое имеет тип **ZarboCompletion**:
```swift
    public enum ZarboCompletion {
        case cancelled
        case error(_ error: Error)
        case success
    }
```

Еще один метод для поиска и отображение ZWB пакета **showPackage** по его артикулу с параметрами (в настоящий момент не реализовано):
```swift
    /**
    Функция показывает виджет по SKU модели
    **Parameters:**
        - sku:  артикул модели
        - on:  контроллер для презентации виджета
    */
    static public func showPackage(
        sku: String,
        on viewController: UIViewController,
        onProgress: @escaping (_ progress: Float) -> Void,
        onCompleted: @escaping (ZarboCompletion) -> Void
    ) -> ZWMStatus 
```

- **onProgress**: замыкание, которое вызывается с параметром **progress** при скачивании файла. Float значение от 0 до 1.
- **onCompleted**: замыкание, которое выдаёт результат в виде параметра **result** с типом-перечислением **ZarboCompletion**.

## Пример создания экземпляра SDK

### Пример использования в UIKit приложении для показа локального пакета ZWB

```swift
        // Локальный файл ZWB пакета из ресурсов приложения
        guard let packageUrl = Bundle.main.url(forResource: "chair", withExtension: "zwb"),
              let packetData: Data = try? Data(contentsOf: packageUrl) else {
            // TODO: обработать ошибку
            return
        }
        
        let status = ZarboSDK.showPackage(
            data: packetData,
            on: self,
            onCompleted: { [weak self] result in
            
            switch (compeltion) {
            case .error(let error):
               // TODO: обработать ошибку
            case .cancelled:
               // Отменено
            case .success:
              // Успешный показ
            @unknown default:
               // "Неизвестный статус"
            }
        })
        
        switch status {
        case .arIsNotSupported:
            // AR не поддерживается на этом устройстве!
        case .showed:
            // Показ ZarboWidget
        case .start:
            // Запуск ZarboWidget
        case .sdkIsNotConfigured:
            // ZarboWidgetSDK не сконфигурирован!
        case .error(let error):
            // TODO: обработать ошибку
            debugError(error.localizedDescription)
        @unknown default:
            // Неизвестный статус
        }
```

## Поддержка

По всем возникающим вопросам, доработкам и предложениям обращаться info@zarbo.tech

[img-xcode-xcframeworks]: images/xcode_xcframeworks.png
