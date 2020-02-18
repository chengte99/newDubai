//
//  OpenInFirefoxControllerSwift.swift
//  DUBAIPALACE
//
//  Created by KevinLin on 2017/12/28.
//  Copyright © 2017年 KevinLin. All rights reserved.
//

import Foundation
import UIKit

open class OpenInFirefoxControllerSwift {
    let firefoxScheme = "firefox:"
    let basicURL = URL(string: "firefox://")!

    // This would need to be changed if used from an extension… but you
    // can't open arbitrary URLs from an extension anyway.
    let app = UIApplication.shared

    fileprivate func encodeByAddingPercentEscapes(_ input: String) -> String {
        let customAllowedSet = CharacterSet(charactersIn: "&=\"#%/<>?@\\^`{|}").inverted
        return input.addingPercentEncoding(withAllowedCharacters: customAllowedSet)!
        //        return input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    }

    open func isFirefoxInstalled() -> Bool {
        return app.canOpenURL(basicURL)
    }

    open func openInFirefox(_ url: URL) -> Bool {
        if !isFirefoxInstalled() {
            return false
        }

        let scheme = url.scheme
        if scheme == "http" || scheme == "https" {
            let escaped = encodeByAddingPercentEscapes(url.absoluteString)
            if let firefoxURL = URL(string: "firefox://open-url?url=\(escaped)") {
                return app.openURL(firefoxURL)
            }
        }
        return false
    }
}
