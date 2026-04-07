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
    var peripherals: CBPeripheral?
    
    private let gluecoseSubject = PassthroughSubject<CGFloat, Never>()
    
    var gluecosePublisher: AnyPublisher<CGFloat, Never> {
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

extension BLEManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            centralManager.scanForPeripherals(withServices: [CBUUID(string: "1808")], options: nil)
        default:
            break
        }
    }
}
