//
//  ViewController.swift
//  Demo App
//
//  Created by Dmitry on 17.09.2024.
//

import UIKit
import ZarboWidgetSDK

final class TestViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var skuTextField: UITextField!
    @IBOutlet weak var usdzUrlTextField: UITextField!
    @IBOutlet weak var packageUrlTextField: UITextField!
    @IBOutlet weak var loaderView: UIActivityIndicatorView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    
    private var dataStorage: IDataStorage = DataStorage()
    private var packetDownloadFileTask: URLSessionDownloadTask?
    private var usdzDownloadFileTask: URLSessionDownloadTask?
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    private enum FileType {
        case packetFile
        case usdzFile
        
        var fileExtension: String {
            switch self {
            case .packetFile:
                return "zwb"
            case .usdzFile:
                return "usdz"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        configureUI()
        setStatus(NSLocalizedString("Click on the \"Try it on\" button to start", comment: ""))
    }
    
    // MARK: - actions
    
    @IBAction
    func showCustomButtonTap(_ sender: Any) {
        guard let packageUrl = Bundle.main.url(forResource: "chair", withExtension: "zwb"),
              let packetData: Data = try? Data(contentsOf: packageUrl) else {
            return
        }
        
        hideKeyboard()
        
        DispatchQueue.global(qos: .utility).async {
            do {
                var widget = try ZarboSDK.getWidget(data: packetData)
                widget.model.title = "Новая модель"
                widget.model.urlToShare = URL.init(string: "https://embed.zarbo.tech/82e606a0-07c0-4417-9a7d-733d789150c4/6461")
                
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    let status = ZarboSDK.showPackage(widget: widget, on: self)
                    self.processStatus(status)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.showError(error.localizedDescription)
                    self.setStatus("Ошибка")
                }
            }
        }
    }
    
    @IBAction
    func showLocalPackageButtonTap(_ sender: Any) {
        guard let packageUrl = Bundle.main.url(forResource: "chair", withExtension: "zwb"),
              let packetData: Data = try? Data(contentsOf: packageUrl) else {
            let errorText = "Ошибка пакета"
            self.showError(errorText)
            self.setStatus("Ошибка")
            return
        }
        
        hideKeyboard()
        let status = ZarboSDK.showPackage(
            data: packetData,
            on: self,
            onCompleted: processCompletion(_ :)
        )
        processStatus(status)
    }
    
    @IBAction
    func showUsdzFromUrl(_ sender: Any) {
        guard let text = usdzUrlTextField.text,
              let url: URL = URL.init(string: text) else {
            self.showError("Неправильный URL usdz файла")
            return
        }
        
        hideKeyboard()
        showLoader()
        setStatus("Скачивание")
        
        dataStorage.usdzUrl = url.absoluteString
        usdzDownloadFileTask = urlSession.downloadTask(with: url)
        usdzDownloadFileTask?.resume()
    }
    
    @IBAction
    func showUsdz(_ sender: Any) {
        hideKeyboard()
        
        let url: URL = Bundle.main.url(forResource: "banya_38a13", withExtension: "usdz")!
        let status = ZarboSDK.showPackage(
            modelUrl: url,
            urlToShare: URL.init(string: "https://embed.zarbo.tech/82e606a0-07c0-4417-9a7d-733d789150c4/6461"),
            title: "Баня",
            on: self
        )
        
        processStatus(status)
    }
    
    @IBAction
    func showPackageFromUrl(_ sender: Any) {
        guard let text = packageUrlTextField.text,
              let url: URL = .init(string: text) else {
            self.showError("Неправильный URL пакета")
            return
        }
        
        hideKeyboard()
        showLoader()
        setStatus("Скачивание")
        
        dataStorage.packetUrl = url.absoluteString
        packetDownloadFileTask = urlSession.downloadTask(with: url)
        packetDownloadFileTask?.resume()
    }

    @IBAction
    func searchActionButtonTap(_ sender: Any) {
        if loaderView.isAnimating {
            cancelAction()
        } else {
            searchAction()
        }
    }
    
    @IBAction
    func dismissButtonTap(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    // MARK: - private
    
    @MainActor
    private func hideKeyboard() {
        usdzUrlTextField.resignFirstResponder()
        packageUrlTextField.resignFirstResponder()
        skuTextField.resignFirstResponder()
    }
    
    @MainActor
    private func cancelAction() {
        packetDownloadFileTask?.cancel()
        usdzDownloadFileTask?.cancel()
    }
    
    @MainActor
    private func showError(_ message: String) {
        let alertController = UIAlertController.init(
            title: NSLocalizedString("Error", comment: ""),
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(.init(title: NSLocalizedString("OK", comment: ""), style: .cancel))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @MainActor
    private func showLoader() {
        loaderView?.startAnimating()
        changeProgress(0)
    }
    
    @MainActor
    private func hideLoader() {
        loaderView?.stopAnimating()
    }
    
    @MainActor
    private func changeProgress(_ value: Float) {
        if value > 0 {
            let percent = Int(value*100)
            let format = NSLocalizedString("Downloading %d", comment: "")
            setStatus(String.localizedStringWithFormat(format, percent) + "%")
        }
    }
    
    private func searchAction() {
        
        hideKeyboard()
        
        let modelSKU = skuTextField.text ?? ""
        dataStorage.sku = modelSKU
        
        let status = ZarboSDK.showPackage(
            sku: modelSKU,
            on: self,
            onProgress: changeProgress(_ :),
            onCompleted: processCompletion(_ :)
        )
        
        processStatus(status)
    }
    
    private func processCompletion(_ compeltion: ZarboSDK.ZarboCompletion) {
        self.hideLoader()

        switch (compeltion) {
        case .error(let error):
            let errorText = error.localizedDescription
            self.showError(errorText)
            self.setStatus("Ошибка")
        case .cancelled:
            self.setStatus("Отменено")
        case .success:
            self.setStatus("Успешный показ")
        @unknown default:
            self.setStatus("Неизвестный статус")
        }

        self.actionButton.setTitle(NSLocalizedString("Try it on", comment: ""), for: .normal)
    }
    
    private func processStatus(_ status: ZarboSDK.ZWMStatus) {
        
        switch status {
        case .arIsNotSupported:
            self.showError("AR не поддерживается на этом устройстве!")
        case .showed:
            self.setStatus("Показ ZarboWidget")
        case .start:
            self.setStatus("Запуск ZarboWidget")
            self.actionButton.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        case .sdkIsNotConfigured:
            self.showError("ZarboWidgetSDK не сконфигурирован!")
        case .error(let error):
            self.showError(error.localizedDescription)
        @unknown default:
            self.setStatus("Неизвестный статус")
        }
    }
    
    private func configureUI() {
        
        skuTextField.text = dataStorage.sku
        skuTextField.delegate = self
        skuTextField.returnKeyType = .done
        
        usdzUrlTextField.text = dataStorage.usdzUrl
        usdzUrlTextField.delegate = self
        usdzUrlTextField.returnKeyType = .done
        
        packageUrlTextField.text = dataStorage.packetUrl
        packageUrlTextField.delegate = self
        packageUrlTextField.returnKeyType = .done
        
        dismissButton.setTitle(NSLocalizedString("Close", comment: ""), for: .normal)
        actionButton.layer.cornerRadius = 8.0
        dismissButton.isHidden = (presentingViewController == nil && modalPresentationStyle != .fullScreen)
    }
    
    private func setStatus(_ text: String) {
        statusLabel.text = text
    }
    
    private func getLocalUrl(from location: URL, fileType: FileType) -> URL? {
        let tempDirectoryPath = NSTemporaryDirectory()
        let destinationUrl: URL = URL.init(fileURLWithPath: tempDirectoryPath).appendingPathComponent("tmp_file.\(fileType.fileExtension)")
 
        do {
            // Перемещаем загруженный файл в нужное место
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: destinationUrl.path) {
                let _ = try? fileManager.removeItem(at: destinationUrl)
            }
            try fileManager.moveItem(at: location, to: destinationUrl)
            return destinationUrl
        } catch {
            showError(error.localizedDescription)
            return nil
        }
    }
    
    deinit {
        #if DEBUG
        debugPrint("deinit \(Self.self)")
        #endif
    }
}

extension TestViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField){
       textField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension TestViewController: URLSessionDownloadDelegate {
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let fileType: FileType
        
        if downloadTask == usdzDownloadFileTask {
            fileType = .usdzFile
        } else if downloadTask == packetDownloadFileTask {
            fileType = .packetFile
        } else {
            return
        }
        
        if let url = self.getLocalUrl(from: location, fileType: fileType) {
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                
                self.hideLoader()
                self.setStatus("Завершено скачивание")

                do {
                    let status: ZarboSDK.ZWMStatus
                    
                    switch fileType {
                    case .packetFile:
                        let data = try Data.init(contentsOf: url)
                        status = ZarboSDK.showPackage(
                            data: data,
                            on: self,
                            onCompleted: processCompletion(_ :)
                        )
                    case .usdzFile:
                        status = ZarboSDK.showPackage(modelUrl: url, on: self)
                    }
                    
                    self.processStatus(status)
                } catch {
                    self.showError(error.localizedDescription)
                    self.setStatus("Ошибка")
                }
            }
        }
    }
    
    // Делегат для отслеживания прогресса
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        DispatchQueue.main.async { [weak self] in
            self?.changeProgress(progress)
        }
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error {
            showError(error.localizedDescription)
            setStatus("Ошибка")
        }
    }
}
