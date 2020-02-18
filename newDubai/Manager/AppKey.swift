//
//  AppKey.swift
//  newDubai
//
//  Created by KevinLin on 2019/6/28.
//  Copyright © 2019 KevinLin. All rights reserved.
//

import Foundation
import UIKit
import SAMKeychain

class AppKey {
    private var uuid: String?

    public func getUUID() -> String {
        if let UUIDDate = SAMKeychain.passwordData(forService: Bundle.main.bundleIdentifier!, account: Bundle.main.bundleIdentifier!) {
            uuid = String(data: UUIDDate, encoding: String.Encoding.utf8)
        } else {
            uuid = UIDevice.current.identifierForVendor?.uuidString
            SAMKeychain.setPassword(uuid!, forService: Bundle.main.bundleIdentifier!, account: Bundle.main.bundleIdentifier!)
        }

        return uuid!
    }
}
