import UIKit
import CoreBluetooth

class BleLedBlinkerViewController: UIViewController {

    @IBOutlet weak var ledButton:UIButton!
    

    let kUARTServiceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b" // サービス
    let kTXCharacteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8" // ペリフェラルへ送信用

    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var serviceUUID : CBUUID!
    var kTXCBCharacteristic: CBCharacteristic?
    var charcteristicUUIDs: [CBUUID]!

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
        charcteristicUUIDs = [CBUUID(string: kTXCharacteristicUUID)]
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
        } else{
            sender.setTitleColor(.gray, for: .normal)
            str = "0"
        }

        let writeData = str.data(using: .utf8)!
        peripheral.writeValue(writeData, for: kTXCBCharacteristic, type: .withResponse)
    }


}



//MARK : - CBCentralManagerDelegate
extension BleLedBlinkerViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("CentralManager didUpdateState")

        switch central.state {
            
        //電源ONを待って、スキャンする
        case CBManagerState.poweredOn:
            let services: [CBUUID] = [serviceUUID]
            centralManager?.scanForPeripherals(withServices: services,
                                               options: nil)
        default:
            break
        }
    }
    
    /// ペリフェラルを発見すると呼ばれる
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        
        self.peripheral = peripheral
        centralManager?.stopScan()
        
        //接続開始
        central.connect(peripheral, options: nil)
        print("  - centralManager didDiscover")
    }
    
    /// 接続されると呼ばれる
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
        print("  - centralManager didConnect")
    }
    
    /// 切断されると呼ばれる？
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print(#function)
        if error != nil {
            print(error.debugDescription)
            setup() // リトライ
            return
        }
    }
}

//MARK : - CBPeripheralDelegate
extension BleLedBlinkerViewController: CBPeripheralDelegate {
    
    /// サービス発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        
        if error != nil {
            print(error.debugDescription)
            return
        }
        
        //キャリアクタリスティク探索開始
        if let service = peripheral.services?.first {
            print("Searching characteristic...")
            peripheral.discoverCharacteristics(charcteristicUUIDs,
                                               for: service)
        }
    }
    
    /// キャリアクタリスティク発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if error != nil {
            print(error.debugDescription)
            return
        }

        for characteristics in service.characteristics! {
            if(characteristics.uuid == CBUUID(string: kTXCharacteristicUUID)) {
//                peripheral.setNotifyValue(true, for: (service.characteristics?[1])!)
                self.kTXCBCharacteristic = characteristics
            }
        }
        
        print("  - Characteristic didDiscovered")

    }
    
    /// データ送信時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print(#function)
        if error != nil {
            print(error.debugDescription)
            return
        }
    }
}
