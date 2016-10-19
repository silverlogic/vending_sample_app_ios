//
//  SettingsViewController.swift
//  VendingDemo
//
//  Created by Muhammad Azeem on 10/18/16.
//  Copyright © 2016 Muhammad Azeem. All rights reserved.
//

import UIKit
import VendingSDK
import CoreLocation

let settingsKey = "settings"
let useBluetoothSimulatorKey = "useBluetoothSimulator"

class Settings : NSObject {
    static let sharedInstance: Settings = Settings()
    
    var useStubbedMachines: Bool {
        get { return (UserDefaults.standard.object(forKey: "useStubbedMachines") as? Bool) ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "useStubbedMachines") }
    }
    
    dynamic var useBluetoothSimulator: Bool = true
    var resultType: ControllerResultConfig? {
        get {
            if let resultTypeString = UserDefaults.standard.object(forKey: "resultType") as? String,
                let resultType = ControllerResultConfig(from: resultTypeString) {
                return resultType
            }
            
            return nil
        }
        set {
            UserDefaults.standard.set(newValue?.toString(), forKey: "resultType")
            if newValue == nil {
                useBluetoothSimulator = true
            } else {
                useBluetoothSimulator = false
            }
        }
    }
    
    var useMobileLocation: Bool {
        get { return (UserDefaults.standard.object(forKey: "useMobileLocation") as? Bool) ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "useMobileLocation") }
    }
    
    var stubbedLocation : CLLocation {
        if let locationString = Bundle.main.object(forInfoDictionaryKey: "StubbedLocation") as? String {
            let components = locationString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if components.count == 2, let latitude = Double(components[0]), let longitude = Double(components[1]) {
                return CLLocation(latitude: latitude, longitude: longitude)
            }
        }
        
        return CLLocation(latitude: 0, longitude: 0)
    }
    
    var serverUrl: URL {
        get {
            if let urlString = UserDefaults.standard.object(forKey: "serverUrl") as? String, let url = URL(string: urlString) {
                return url
            } else {
                return URL(string: Bundle.main.object(forInfoDictionaryKey: "VendingServerURL") as! String)!
            }
        }
        set { UserDefaults.standard.set(newValue.absoluteString, forKey: "serverUrl") }
    }
    
    private override init() {
        super.init()
        
        useBluetoothSimulator = resultType == nil
    }
}

class SettingsViewController: UIViewController {
    let resultTypes : [ControllerResultConfig] = [.allSuccess, .deviceNotLocated, .connectionFailed, .vendingFailed]
    
    let settings: Settings = Settings.sharedInstance
    
    @IBOutlet weak var stubbedMachinesSwitch: UISwitch!
    @IBOutlet weak var bluetoothSimulatorSwitch: UISwitch!
    @IBOutlet weak var serverUrlTextField: UITextField!
    @IBOutlet weak var resultTypeTextField: UITextField!
    @IBOutlet weak var locationSegment: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        serverUrlTextField.delegate = self
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50))
        toolBar.barStyle = UIBarStyle.default
        toolBar.items = [
            UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(hideKeyboard))]
        toolBar.sizeToFit()
        
        resultTypeTextField.inputAccessoryView = toolBar
        resultTypeTextField.inputView = pickerView
        
        bluetoothSimulatorSwitch.isOn = settings.useBluetoothSimulator
        stubbedMachinesSwitch.isOn = settings.useStubbedMachines
        serverUrlTextField.text = settings.serverUrl.absoluteString
        serverUrlTextField.isEnabled = !settings.useStubbedMachines
        locationSegment.selectedSegmentIndex = settings.useMobileLocation ? 0 : 1
        
        settings.addObserver(self, forKeyPath: useBluetoothSimulatorKey, options: [.initial, .new], context: nil)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSettings))
    }
    
    deinit {
        settings.removeObserver(self, forKeyPath: useBluetoothSimulatorKey)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == useBluetoothSimulatorKey else {
            return
        }
        
        if settings.useBluetoothSimulator {
            resultTypeTextField.text = "Using bluetooth dongle"
            resultTypeTextField.isEnabled = false
            
            if let pickerView = resultTypeTextField.inputView as? UIPickerView {
                pickerView.selectRow(0, inComponent: 0, animated: false)
            }
        } else {
            resultTypeTextField.text = settings.resultType?.description
            resultTypeTextField.isEnabled = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Action methods
    @IBAction func stubbedMachinesSwitched(_ sender: UISwitch) {
        settings.useStubbedMachines = sender.isOn
        serverUrlTextField.isEnabled = !settings.useStubbedMachines
    }
    
    @IBAction func bluetoothSimulatorSwitched(_ sender: UISwitch) {
        if sender.isOn {
            settings.resultType = nil
        } else {
            settings.resultType = .allSuccess
        }
    }
    
    @IBAction func locationSegmentChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            settings.useMobileLocation = true
        } else {
            settings.useMobileLocation = false
        }
    }
    
    // MARK: - Private methods
    func dismissSettings() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func hideKeyboard() {
        resultTypeTextField.resignFirstResponder()
    }
}

extension SettingsViewController : UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let result = resultTypes[row]
        
        settings.resultType = result
    }
}

extension SettingsViewController : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return resultTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return resultTypes[row].description
    }
}

extension SettingsViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text, let url = URL(string: text) {
            settings.serverUrl = url
        } else {
            let alert = UIAlertController(title: "Error!", message: "Invalid url", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
        }
    }
}
