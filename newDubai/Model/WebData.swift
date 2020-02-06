//
//  WebData.swift
//  newDubai
//
//  Created by KevinLin on 2019/6/28.
//  Copyright © 2019 KevinLin. All rights reserved.
//

import Foundation

class WebData: NSObject {
    @objc var mainWeb_url: String?
    @objc var otherWeb_url: String?
    @objc var isHiddenToolBar = false
    @objc var isHiddenReloadButton = false
    @objc var blankTitle: String?
    @objc var openNewWindow: String?
    @objc var refreshIsDisable = false
    @objc var backIsDisable = false
    
    var loginAcc = ""
    var nowOpenGame = false

    var userAgent = ""
    var defaultUserAgent = ""
    var isUseHardURL = false

    @objc static let shared = WebData()

    @objc func set(string: String?) {
        self.mainWeb_url = string
    }

    @objc func setOther(string: String?) {
        self.otherWeb_url = string
    }

    @objc func setIsHiddenToolBar(isHiddenToolBar: Bool) {
        self.isHiddenToolBar = isHiddenToolBar
    }

    @objc func setIsHiddenReloadButton(isHiddenReloadButton: Bool) {
        self.isHiddenReloadButton = isHiddenReloadButton
    }

    @objc func setBlankTitle(blankTitle: String?) {
        self.blankTitle = blankTitle
    }

    @objc func setNewWindow(string: String?) {
        self.openNewWindow = string
    }
}
