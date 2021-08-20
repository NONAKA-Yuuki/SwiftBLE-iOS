//
//  ViewController.swift
//  iOS-BLEtest
//
//  Created by 野中祐希 on 2021/08/20.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {

    @IBOutlet weak var ledButton: UIButton!
    
    let kUARTServiceUUID = "63d6672b-986b-406f-9f6f-6a712d015e04"   // サービス
    let kTXCharacteristicUUID = "2ec43578-5fcd-4c0e-8758-ffeb77537a83"  // ペリフェラル
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var serviceUUID: CBUUID!
    var kTXCBCharacteristic: CBCharacteristic!
    var characteristicUUIDs: [CBUUID]!
    
    var stateLed: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ledButton.setTitleColor(.gray, for: .normal)
        setup()
    }
    private func setup() {
        print("setup...")
        
        centralManager = CBCentralManager()
        centralManager.delegate = self as CBCentralManagerDelegate
        
        serviceUUID = CBUUID(string: kUARTServiceUUID)
        characteristicUUIDs = [CBUUID(string: kTXCharacteristicUUID)]
    }
    
    @IBAction func tappedLed(_ sender:UIButton) {
        guard let peripheral = self.peripheral else {
            return
        }
        
        guard let kTXCBCharacteristic = kTXCBCharacteristic else {
            return
        }
        
        var str:String!
        self.stateLed = !self.stateLed
        if self.stateLed {
            sender.setTitleColor(.orange, for: .normal)
            str = "1"
        } else {
            sender.setTitleColor(.gray, for: .normal)
            str = "0"
        }
        
        let writeData = str.data(using: .utf8)!
        peripheral.writeValue(writeData, for: kTXCBCharacteristic, type: .withResponse)
    }

}



// MARK: -CBCentralManagerDelegate
extension ViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("CentralManager didUpdateState")
        
        switch central.state {
        // 電源ONを待って、スキャンする
        case CBManagerState.poweredOn:
            let services: [CBUUID] = [serviceUUID]
            centralManager?.scanForPeripherals(withServices: services, options: nil)
        default:
            break
        }
    }
    
    // ペリフェラルを発見すると呼ばれる
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        
        self.peripheral = peripheral
        centralManager?.stopScan()
        
        // 接続開始
        central.connect(peripheral, options: nil)
        print(" - centralManager didDiscover")
    }
    
    // 接続されると呼ばれる
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
        print(" - centralManager didDonnect")
    }
    
    // 切断されると呼ばれる？
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print(#function)
        if error != nil {
            print(error.debugDescription)
            setup() // リトライ
            return
        }
    }
}

//MARK: - CBPeripheralDelegate
extension ViewController: CBPeripheralDelegate {
    
    // サービス発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        if error != nil {
            print(error.debugDescription)
            return
        }
        
        // キャリアクタリスティク探索開始
        if let service = peripheral.services?.first {
            peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        }
    }
    
    // キャリアクタリスティック発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if error != nil {
            print(error.debugDescription)
            return
        }
        
        for characteristics in service.characteristics! {
            if(characteristics.uuid == CBUUID(string: kTXCharacteristicUUID)) {
                self.kTXCBCharacteristic = characteristics
            }
        }
        
        print(" - Characteristiv didDiscoverd")
    }
    
    // データ送信時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor charactaristic: CBCharacteristic, error: Error?) {
        print(#function)
        if error != nil {
            print(error.debugDescription)
            return
        }
    }
}
