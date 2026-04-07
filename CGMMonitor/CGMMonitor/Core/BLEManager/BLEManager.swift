//
//  BLEManager.swift
//  CGMMonitor
//
//  Created by Chan Basha on 07/04/26.
//

import CoreBluetooth
import Combine


final class BLEManager: NSObject {
   
    static let shared = BLEManager()
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral?
    
    private let gluecoseSubject = PassthroughSubject<Int, Never>()
    
    var gluecosePublisher: AnyPublisher<Int, Never> {
        gluecoseSubject.eraseToAnyPublisher()
    }
    
    // CBUUID is used in CoreBluetooth to uniquely identify BLE services and characteristics. It acts as a key to discover and communicate with specific data points exposed by a peripheral device.
    private let serviceUUID = CBUUID(string: "1808")
    private let characteristicUUID = CBUUID(string: "2A18")
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            centralManager.scanForPeripherals(withServices: [CBUUID(string: "1808")], options: nil)
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        central.stopScan()
        central.connect(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        central.connect(peripheral)
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBPeripheralDelegate {
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        peripheral.services?.forEach {
            peripheral.discoverCharacteristics([characteristicUUID], for: $0)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        service.characteristics?.forEach {
            if $0.uuid == characteristicUUID {
                peripheral.setNotifyValue(true, for: $0)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard let data = characteristic.value else { return }
        
        let glucose = parseGlucose(data: data)
        gluecoseSubject.send(glucose)
    }
    
    private func parseGlucose(data: Data) -> Int {
        // Example parsing (depends on device spec)
        return Int(data.first ?? 0)
    }
    
}
