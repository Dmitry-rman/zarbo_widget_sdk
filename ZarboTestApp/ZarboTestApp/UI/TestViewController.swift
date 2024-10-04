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
    @IBOutlet weak var loaderView: UIActivityIndicatorView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    
    private let dataStorage: IDataStorage = DataStorage()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        configureUI()
        setStatus(NSLocalizedString("Click on the \"Try it on\" button to start", comment: ""))
    }
    
    // MARK: - actions

    @IBAction
    func actionButtonTap(_ sender: Any) {
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
    private func cancelAction() {
        Zarbo.cancel()
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
        
        skuTextField?.resignFirstResponder()
        
        let modelSKU = skuTextField.text ?? ""
        dataStorage.setSKU(modelSKU)
        
        let isARQuickLook = true
        let type: Zarbo.ZarboPreview
        let urlToShare: URL? = nil
        if isARQuickLook {
            // Zarbo.ZarboPreview.qlPreview использует стандарный QLPreviewController и ARQuickLook
            type = .qlPreview(urlToShare: urlToShare)
        } else {
            // Zarbo.ZarboPreview.zarbo использует ARKit и увеличивает расход памяти. Но позволяет шарить свою ссылку и др.
           type = .zarbo(urlToShare: urlToShare)
        }
        
        let status = Zarbo.presentModelView(
            sku: modelSKU,
            previewType: type, // Этот параметр можно опустить, по-умолчанию .qlPreview
            presenting: self
        ) { [weak self] progress in
            self?.changeProgress(progress)
        } onCompleted: { [weak self] result in
            guard let self else { return }
            self.hideLoader()
        
            switch (result) {
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
        
        switch status {
        case .arIsNotSupported:
            self.showError("AR не поддерживается на этом устройстве!")
        case .start:
            self.setStatus("Запуск ZarboWidget")
            self.showLoader()
            self.actionButton.setTitle(NSLocalizedString("Cancel", comment: ""), for: .normal)
        case .sdkIsNotConfigured:
            self.showError("ZarboWidgetSDK не сконфигурирован!") 
        @unknown default:
            self.setStatus("Неизвестный статус")
        }
    }
    
    private func configureUI() {
        skuTextField.text = dataStorage.getSKU()
        skuTextField.delegate = self
        skuTextField.returnKeyType = .done
        
        dismissButton.setTitle(NSLocalizedString("Close", comment: ""), for: .normal)
        actionButton.layer.cornerRadius = 8.0
        dismissButton.isHidden = (presentingViewController == nil && modalPresentationStyle != .fullScreen)
    }
    
    private func setStatus(_ text: String) {
        statusLabel.text = text
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
        skuTextField?.resignFirstResponder()
        return true
    }
}
