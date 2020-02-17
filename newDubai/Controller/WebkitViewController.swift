//
//  WebkitViewController.swift
//  newDubai
//
//  Created by KevinLin on 2019/6/28.
//  Copyright © 2019 KevinLin. All rights reserved.
//

import UIKit
import WebKit
import SafariServices
import PPSPing
import SwiftyJSON

class WebkitViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, UIScrollViewDelegate, SFSafariViewControllerDelegate, WKScriptMessageHandler {

    var web_url: String?
    @objc dynamic var blankURL: String = ""
    var wk: WKWebView!

    var service: PPSPingServices!
    var failString = ""
    var deviceVersion = UIDevice.current.systemVersion
    var hostDomain = ""
    var deviceIp = ""
    var pingCount = 0
    var ReachableVia = ""

    var cookieTmp = ""
    var screenImg: UIImageView!
    var progressLabel: UILabel!
    var progressView: UIProgressView!
    var progressYOffset: CGFloat {
        return AppData.isBF ? AppData.customWelcomeYOffsetBF : 0
    }
    var uuidLabel: UILabel!

    var timer = Timer()
    let statusBarHeight = UIApplication.shared.statusBarFrame.height

    var isViewAppeared: Bool = false
    
    //configure statusbar
    var _statusBarStyle: UIStatusBarStyle = .lightContent
    var statusBarStyle: UIStatusBarStyle {
        get {
            return _statusBarStyle
        }
        set {
            _statusBarStyle = newValue
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }

    var _isStatusBarHidden: Bool = false
    var isStatusBarHidden: Bool {
        get {
            return _isStatusBarHidden
        }
        set {
            _isStatusBarHidden = newValue
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return isStatusBarHidden
    }
    //configure statusbar end

    func HGLog<T>(_ message: T, file: String = #file, function: String = #function,
        line: Int = #line) {
        #if DEBUG
            //获取文件名
            let fileName = (file as NSString).lastPathComponent
            //打印日志内容
            //            print("\(fileName):\(line) \(function) | \(message)")

            let now: Date = Date()
            let dateFormat: DateFormatter = DateFormatter()
            dateFormat.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
            dateFormat.timeZone = NSTimeZone.local
            let dateString: String = dateFormat.string(from: now)

            print("\(fileName):\(line) \(dateString) | \(message)")
        #endif
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.body)
        /*
         window.webkit.messageHandlers.CallApp.postMessage({register:'http://www.baidu.com'})
         
         {isLogout:1}
         {isReload:1}
         {isNative:1,url:'http://www.baidu.com',isHiddenTool:1,isHiddenReloadButton:1}
         {register:'http://www.baidu.com'}
         {title:'BBIN'}
         {isOpenGame:true}
         */

        if let tag = message.body as? String {
            if tag == "windowClose" {
                print("window.close()")
                self.newWKClose()
            }
        }

        if let dic = message.body as? [String: Any] {
            if let title = dic["title"] as? String {
                WebData.shared.setBlankTitle(blankTitle: title)
            }

            if let isOpenGame = dic["isOpenGame"] as? Bool {
                WebData.shared.nowOpenGame = isOpenGame
            }

            if let registerString = dic["register"] as? String {
                if let url = URL(string: registerString) {
                    if UIApplication.shared.canOpenURL(url) {
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        } else {
                            UIApplication.shared.openURL(url)
                        }
                    }
                }
            }

            if let registerString = dic["url"] as? String {
                if let url = URL(string: registerString) {
                    if UIApplication.shared.canOpenURL(url) {
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        } else {
                            UIApplication.shared.openURL(url)
                        }
                    }
                }
            }

            // 518
            if let urlString = dic["APIGameURL"] as? String {
                if let title = dic["title"] as? String {
                    if title == "" {
                        WebData.shared.setBlankTitle(blankTitle: "游戏大厅")
                    } else {
                        WebData.shared.setBlankTitle(blankTitle: title)
                    }
                }

                if let onSafari = dic["onSafari"] as? Bool {
                    if !onSafari {
                        WebData.shared.setOther(string: urlString)
                        performSegue(withIdentifier: "show", sender: self)
                    } else {
                        if let url = URL(string: urlString) {
                            let svc = SFSafariViewController(url: url)
                            svc.delegate = self
                            present(svc, animated: true, completion: nil)
                        }
                    }
                }
            }

            if let pinCode = dic["ping_code"] as? String {
                UserDefaults.standard.set(pinCode, forKey: "ping_code")
                UserDefaults.standard.synchronize()
            }

            if let account = dic["web_acc"] as? String {
                if WebData.shared.loginAcc == "" {
                    print("do postAsync")
                    WebData.shared.loginAcc = account
                    let dbdomain = LogData.shared.dBDomainFinal
                    let sessID = LogData.shared.sessID
                    APIManager.shared.postAccountAsync(domain: dbdomain, sessID: sessID, account: account) { (json) in
                        if let json = json {
                            if let _ = json["success"].int {
                                print("##### Account async success #####")
                            }
                        }
                    }
                } else {
                    print("ignore it")
                }
            }
            // 518 end

            if let logout = dic["isLogout"] as? Int {
                if logout == 1 {
                    //call logout method
                    print(" call logout method")
                    self.callLogout()
                }
            }

            //            window.webkit.messageHandlers.CallApp.postMessage({rememberAccType:'get', newAcc:'kevin123'})
            if let rememberAccType = dic["rememberAccType"] as? String {
                if rememberAccType == "get" {
                    // get method
                    if let acc = UserDefaults.standard.string(forKey: "rememberAcc") {
                        if acc != "" {
                            let content: [String: Any] = [
                                "code": "200",
                                "acc": acc,
                                "msg": "acc exist"
                            ]
                            let json = JSON(content)

                            self.wk.evaluateJavaScript("commFn.func.pg_login.reAppMemoryAccount(JSON.stringify(\(json)));") { (any, error) in
                                //                            self.wk.evaluateJavaScript("console.log( JSON.stringify(\(json)) );") { (any, error) in
                                if error == nil {
                                    print("commFn.func.pg_login.memoryAccount success")
                                } else {
                                    print(error?.localizedDescription)
                                }
                            }
                        }
                    } else {
                        let content: [String: Any] = [
                            "code": "201",
                            "acc": "",
                            "msg": "acc empty"
                        ]
                        let json = JSON(content)

                        self.wk.evaluateJavaScript("commFn.func.pg_login.reAppMemoryAccount(JSON.stringify(\(json)));") { (any, error) in
                            //                        self.wk.evaluateJavaScript("console.log( JSON.stringify(\(json)) );") { (any, error) in
                            if error == nil {
                                print("commFn.func.pg_login.memoryAccount success")
                            } else {
                                print(error?.localizedDescription)
                            }
                        }
                    }
                } else if rememberAccType == "set" {
                    // set method
                    if let newAcc = dic["newAcc"] as? String {
                        if newAcc == "" {
                            UserDefaults.standard.removeObject(forKey: "rememberAcc")
                        } else {
                            UserDefaults.standard.set(newAcc, forKey: "rememberAcc")
                        }
                    }
                }
            }

            if let reload = dic["isReload"] as? Int {
                if reload == 1 {
                    //call reload method
                    print(" call reload method")
                    self.callReload()
                }
            }

            if let isNative = dic["isNative"] as? Int {
                if isNative == 1 {
                    //call native wkwebview
                    if let urlString = dic["url"] as? String {
                        if let isHiddenTool = dic["isHiddenTool"] as? Int {
                            if isHiddenTool == 1 {
                                WebData.shared.setIsHiddenToolBar(isHiddenToolBar: true)
                            } else {
                                WebData.shared.setIsHiddenToolBar(isHiddenToolBar: false)
                            }
                        }

                        if let isHiddenReloadButton = dic["isHiddenReloadButton"] as? Int {
                            if isHiddenReloadButton == 1 {
                                WebData.shared.setIsHiddenReloadButton(isHiddenReloadButton: true)
                            } else {
                                WebData.shared.setIsHiddenReloadButton(isHiddenReloadButton: false)
                            }
                        }

                        WebData.shared.setOther(string: urlString)
                        performSegue(withIdentifier: "show", sender: self)
                    }
                } else {
                    //call safari webview
                    if let urlString = dic["url"] as? String {
                        if let url = URL(string: urlString) {
                            let svc = SFSafariViewController(url: url)
                            svc.delegate = self
                            present(svc, animated: true, completion: nil)
                        }
                    }
                }
            }

            //kevin 指紋手勢
            //func1,4,5,6,7
            //            window.webkit.messageHandlers.CallApp.postMessage({callApp:'status'})
            //            window.webkit.messageHandlers.CallApp.postMessage({callApp:'callTouchID',gesture:''})
            //            window.webkit.messageHandlers.CallApp.postMessage({callApp:'callGesture',gesture:'21036'})
            //            window.webkit.messageHandlers.CallApp.postMessage({callApp:'errCount',value:'0'})
            //            window.webkit.messageHandlers.CallApp.postMessage({callApp:'closeFastGuide',data:true})
            //            window.webkit.messageHandlers.CallApp.postMessage({callApp:'cleanAccPW'})
            if let callApp = dic["callApp"] as? String {
                if callApp == "status" {
                    let _ = AppTouchID().checkBiometrics()
                    //取得裝置指紋手勢狀態
                    var account = ""
                    var gesture = ""
                    var errCount = ""
                    let isSupportTouchID = UserDefaults.standard.bool(forKey: "isSupportTouchID")
                    let hasTouchID = UserDefaults.standard.bool(forKey: "hasTouchID")
                    let closeFastGuide = UserDefaults.standard.bool(forKey: "closeFastGuide")
                    if let hasGesture = UserDefaults.standard.string(forKey: "gesture") {
                        gesture = hasGesture
                    }
                    if let acc = UserDefaults.standard.string(forKey: "account") {
                        account = acc
                    }
                    if let count = UserDefaults.standard.string(forKey: "errCount") {
                        errCount = count
                    }

                    //call JS 1
                    let content: [String: Any] = [
                        "support": isSupportTouchID,
                        "touchID": hasTouchID,
                        "gesture": gesture,
                        "account": account,
                        "errCount": errCount,
                        "closeFastGuide": closeFastGuide
                    ]
                    let json = JSON(content)
                    print(json)

                    self.wk.evaluateJavaScript("commFn.func.pg_quick.rtAppInfo(JSON.stringify(\(json)));") { (any, error) in
                        //                    self.wk.evaluateJavaScript("console.log( JSON.stringify(\(json)) );") { (any, error) in
                        if error == nil {
                            print("commFn.func.pg_quick.rtAppInfo success")
                        } else {
                            print(error?.localizedDescription)
                        }
                    }
                } else if callApp == "callTouchID" {
                    let resCode = AppTouchID().checkBiometrics()
                    if resCode != 0 {
                        let customCode = String(resCode)
                        //call JS 5
                        let content: [String: Any] = [
                            "status": customCode,
                            "msg": "TouchID is wrong"
                        ]
                        let json = JSON(content)
                        //                        print(json)

                        self.wk.evaluateJavaScript("commFn.func.pg_quick.rtAppEnterFail(JSON.stringify(\(json)));") { (any, error) in
                            if error == nil {
                                print("commFn.func.pg_quick.rtAppEnterFail success")
                            } else {
                                print(error?.localizedDescription)
                            }
                        }
                        return
                    }
                    //呼叫指紋
                    if let acc = UserDefaults.standard.string(forKey: "account") {
                        AppTouchID().authenticateUser { (code) in
                            //                            print(code)
                            if code == 0 {
                                //call 富博
                                if let pw = UserDefaults.standard.string(forKey: "password") {
                                    let newPW = "\(Date().timeStamp)*\(pw)"
                                    let enPW = AESHelp.shared.aes_en(str: newPW)
                                    let urlStrArray = self.web_url!.components(separatedBy: "mb")
                                    let host = urlStrArray.first!

                                    if (TaipeiWebConf) {
                                        self.fastLogin_js7(acc: acc, pw: enPW, type: "touchID")
                                    } else {
                                        self.fastLogin(host: host, acc: acc, pwd: enPW, type: "touchID", currentURL: self.web_url!)
                                    }
                                }
                            } else {
                                let customCode = String(code)
                                //call JS 5
                                let content: [String: Any] = [
                                    "status": customCode,
                                    "msg": "TouchID is wrong"
                                ]
                                let json = JSON(content)
                                print(json)

                                DispatchQueue.main.async {
                                    self.wk.evaluateJavaScript("commFn.func.pg_quick.rtAppEnterFail(JSON.stringify(\(json)));") { (any, error) in
                                        //                                    self.wk.evaluateJavaScript("console.log( JSON.stringify(\(json)) );") { (any, error) in
                                        if error == nil {
                                            print("commFn.func.pg_quick.rtAppEnterFail success")
                                        } else {
                                            print(error?.localizedDescription)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else if callApp == "callGesture" {
                    //呼叫手勢比對
                    if let gesture = dic["gesture"] as? String {
                        if let bindGesture = UserDefaults.standard.string(forKey: "gesture") {
                            if gesture != bindGesture {
                                //與綁定的手勢不同
                                print("與綁定的手勢不同")
                            } else {
                                //與綁定的手勢相同
                                //call 富博
                                UserDefaults.standard.set("0", forKey: "errCount")
                                if let acc = UserDefaults.standard.string(forKey: "account") {
                                    if let pw = UserDefaults.standard.string(forKey: "password") {
                                        let newPW = "\(Date().timeStamp)*\(pw)"
                                        let enPW = AESHelp.shared.aes_en(str: newPW)
                                        let urlStrArray = self.web_url!.components(separatedBy: "mb")
                                        let host = urlStrArray.first!

                                        if (TaipeiWebConf) {
                                            self.fastLogin_js7(acc: acc, pw: enPW, type: "gesture")
                                        } else {
                                            self.fastLogin(host: host, acc: acc, pwd: enPW, type: "gesture", currentURL: self.web_url!)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else if callApp == "errCount" {
                    if let errCount = dic["value"] as? String {
                        UserDefaults.standard.set(errCount, forKey: "errCount")
                    }
                } else if callApp == "closeFastGuide" {
                    if let closeFastGuide = dic["data"] as? Bool {
                        UserDefaults.standard.set(closeFastGuide, forKey: "closeFastGuide")
                    }
                } else if callApp == "cleanAccPW" {
                    //會員停用, 清除帳號密碼手勢, 台北用
                    UserDefaults.standard.removeObject(forKey: "account")
                    UserDefaults.standard.removeObject(forKey: "password")
                    UserDefaults.standard.removeObject(forKey: "gesture")
                }
            }

            //func2, 3
            //            window.webkit.messageHandlers.CallApp.postMessage({actionType:'setup',loginType:'touchID',account:'kevintest99',password:'asd123',gesture:''})
            //            window.webkit.messageHandlers.CallApp.postMessage({actionType:'setup',loginType:'gesture',account:'kevintest99',password:'asd123',gesture:'21036'})
            if let actionType = dic["actionType"] as? String {
                var canBind = false
                if actionType == "setup" {
                    if let account = UserDefaults.standard.string(forKey: "account") {
                        //先前有綁定帳號
                        if let acc = dic["account"] as? String {
                            if acc != account {
                                //與第一次綁定帳號不同，不可綁定
                                canBind = false

                                //call JS 5
                                let content: [String: Any] = [
                                    "status": "203",
                                    "msg": "TouchID is wrong"
                                ]
                                let json = JSON(content)
                                //                                print(json)

                                self.wk.evaluateJavaScript("commFn.func.pg_quick.rtAppEnterFail(JSON.stringify(\(json)));") { (any, error) in
                                    if error == nil {
                                        print("commFn.func.pg_quick.rtAppEnterFail success")
                                    } else {
                                        print(error?.localizedDescription)
                                    }
                                }
                            } else {
                                //與第一次綁定帳號同，可綁定
                                canBind = true
                            }
                        }
                    } else {
                        //先前無綁定帳號，可綁定
                        canBind = true
                    }

                    if canBind {
                        UserDefaults.standard.set("0", forKey: "errCount")
                        if let loginType = dic["loginType"] as? String {
                            if loginType == "touchID" {
                                let resCode = AppTouchID().checkBiometrics()
                                if resCode != 0 {
                                    let customCode = String(resCode)
                                    //call JS 5
                                    let content: [String: Any] = [
                                        "status": customCode,
                                        "msg": "TouchID is wrong"
                                    ]
                                    let json = JSON(content)
                                    //                        print(json)

                                    self.wk.evaluateJavaScript("commFn.func.pg_quick.rtAppEnterFail(JSON.stringify(\(json)));") { (any, error) in
                                        if error == nil {
                                            print("commFn.func.pg_quick.rtAppEnterFail success")
                                        } else {
                                            print(error?.localizedDescription)
                                        }
                                    }
                                    return
                                }
                            }

                            if let acc = dic["account"] as? String {
                                if let pw = dic["password"] as? String {
                                    let dePW = AESHelp.shared.aes_de(str: pw)
                                    let dePWArray = dePW.components(separatedBy: "*")
                                    let realPW = dePWArray.last!

                                    if loginType == "gesture" {
                                        if let gesture = dic["gesture"] as? String {
                                            UserDefaults.standard.set(gesture, forKey: "gesture")
                                        }
                                    }

                                    UserDefaults.standard.set(acc, forKey: "account")
                                    UserDefaults.standard.set(realPW, forKey: "password")
                                    UserDefaults.standard.synchronize()

                                    //call 富博
                                    let newPW = "\(Date().timeStamp)*\(realPW)"
                                    let enPW = AESHelp.shared.aes_en(str: newPW)
                                    let urlStrArray = self.web_url!.components(separatedBy: "mb")
                                    let host = urlStrArray.first!

                                    if (TaipeiWebConf) {
                                        self.fastLogin_js7(acc: acc, pw: enPW, type: loginType)
                                    } else {
                                        self.fastLogin(host: host, acc: acc, pwd: enPW, type: loginType, currentURL: self.web_url!)
                                    }
                                }
                            }
                        }
                    }
                } else if actionType == "login" {
                    //                    window.webkit.messageHandlers.CallApp.postMessage({actionType:'login',loginType:'touchID',account:'kevintest99',password:'asd123',gesture:''})
                    //                    window.webkit.messageHandlers.CallApp.postMessage({actionType:'login',loginType:'gesture',account:'kevintest99',password:'asd123',gesture:'21036'})
                    if let account = UserDefaults.standard.string(forKey: "account") {
                        if let acc = dic["account"] as? String {
                            if acc != account {
                                //與第一次綁定帳號不同，直接登入
                                //call JS 4, false
                                let content: [String: Any] = [
                                    "status": false,
                                    "msg": "Account is different"
                                ]
                                let json = JSON(content)
                                print(json)

                            } else {
                                //與第一次綁定帳號同，覆蓋綁定的帳密
                                if let pw = dic["password"] as? String {
                                    let dePW = AESHelp.shared.aes_de(str: pw)
                                    let dePWArray = dePW.components(separatedBy: "*")
                                    let realPW = dePWArray.last!

                                    UserDefaults.standard.set(acc, forKey: "account")
                                    UserDefaults.standard.set(realPW, forKey: "password")
                                }

                                //call JS 4, true
                                let content: [String: Any] = [
                                    "status": true,
                                    "msg": "Account is same"
                                ]
                                let json = JSON(content)
                                print(json)
                            }
                        }
                    }
                }
            }

            //            window.webkit.messageHandlers.CallApp.postMessage({getCache:'1'})
            if let getCache = dic["getCache"] as? String {
                if getCache == "1" {
                    print("showCache")
                    self.showCache()
                }
            }

            //            window.webkit.messageHandlers.CallApp.postMessage({cleanCache:'1'})
            if let cleanCache = dic["cleanCache"] as? String {
                if cleanCache == "1" {
                    print("cleanCache")
                    self.cleanCache()
                }
            }

            //            window.webkit.messageHandlers.CallApp.postMessage({refreshIsDisable:'1',backIsDisable:'1'})
            if let refreshIsDisable = dic["refreshIsDisable"] as? String {
                if refreshIsDisable == "1" {
                    WebData.shared.refreshIsDisable = true
                }
            }
            if let backIsDisable = dic["backIsDisable"] as? String {
                if backIsDisable == "1" {
                    WebData.shared.backIsDisable = true
                }
            }
        }
    }

    func fastLogin(host: String, acc: String, pwd: String, type: String, currentURL: String) {
        APIManager.shared.fastLoginAPI(host: host, account: acc, password: pwd, type: type) { (json) in
            if let json = json {
                print(json)
                if let code = json["code"].string {
                    if code == "100" {
                        //success login
                        if let newUrlString = json["token"].string {
                            //                            let newUrlString = "\(currentURL)?\(token)"

                            if let url = URL(string: newUrlString) {
                                let request = URLRequest(url: url)
                                self.wk.load(request)
                            }
                        }
                    } else {
                        if code == "201" {
                            //會員停用, 清除帳號密碼手勢
                            UserDefaults.standard.removeObject(forKey: "account")
                            UserDefaults.standard.removeObject(forKey: "password")
                            UserDefaults.standard.removeObject(forKey: "gesture")
                        }

                        //fail, call JS 3
                        let content: [String: Any] = [
                            "status": false,
                            "code": code,
                            "type": type,
                        ]
                        let failJSON = JSON(content)

                        self.wk.evaluateJavaScript("commFn.func.pg_quick.rtAccVerFail(JSON.stringify(\(failJSON)));") { (any, error) in
                            //                        self.wk.evaluateJavaScript("console.log( JSON.stringify(\(failJSON)) );") { (any, error) in
                            if error == nil {
                                print("commFn.func.pg_quick.rtAccVerFail success")
                            } else {
                                print(error?.localizedDescription)
                            }
                        }
                    }
                }
            }
        }
    }

    func fastLogin_js7(acc: String, pw: String, type: String) {
        let content: [String: Any] = [
            "acc": acc,
            "pw": pw,
            "loginType": type
        ]
        let json = JSON(content)
        //        print(json)

        DispatchQueue.main.async {
            self.wk.evaluateJavaScript("commFn.func.pg_quick.rtAppLogin(JSON.stringify(\(json)));") { (any, error) in
                //            self.wk.evaluateJavaScript("console.log( JSON.stringify(\(json)) );") { (any, error) in
                if error == nil {
                    print("commFn.func.pg_quick.rtAppLogin success")
                } else {
                    print(error?.localizedDescription)
                }
            }
        }
    }

    func newWKClose() {
        if self.newWK != nil {
            self.newWK.stopLoading()
            self.newWK.removeFromSuperview()
            self.newWK = nil
        }
    }

    func openNativeBrowser(browser: String, urlString: String) {
        if let url = URL(string: urlString) {
            if browser == "chrome" {
                if OpenInChromeController.sharedInstance().open(inChrome: url) {
                    print("open in chrome")
                }
                else {
                    print("No chrome")
                    if let url = URL(string: "itms-apps://itunes.apple.com/us/app/chrome/id535886823") {
                        UIApplication.shared.openURL(url)
                    }
                }
            } else if browser == "firefox" {
                let openInFireFox = OpenInFirefoxControllerSwift()
                if openInFireFox.isFirefoxInstalled() {
                    if openInFireFox.openInFirefox(url) {
                        print("open in firefox")
                    }
                } else {
                    print("no firefox")
                    if let url = URL(string: "itms-apps://itunes.apple.com/us/app/firefox-web-browser/id989804926") {
                        UIApplication.shared.openURL(url)
                    }
                }
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }

    @objc func showCache() {
        let path = NSHomeDirectory() + "/Library/Caches"
        let cache = CacheManager().getCacheSize(withFilePath: path)
        print("cache = \(cache)")

        let content: [String: Any] = [
            "code": "200",
            "cache": cache,
            "msg": "get cache success"
        ]
        let json = JSON(content)
        self.wk.evaluateJavaScript("commFn.func.pg_memMain.rtAppCache(JSON.stringify(\(json)));") { (any, error) in
            if error == nil {
                print("commFn.func.pg_memMain.rtAppCache success")
            } else {
                print(error?.localizedDescription)
            }
        }
    }

    @objc func cleanCache() {
        //        //method 1
        //        //        let websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        //        let websiteDataTypes: Set = [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]
        //        //        print("websiteDataTypes = \(websiteDataTypes)")
        //        let date = Date(timeIntervalSince1970: 0)
        //        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: date, completionHandler: {
        //            print("remove WKWebsiteDataTypeDiskCache && WKWebsiteDataTypeMemoryCache data in iOS9 later")
        //        })

        //method 2
        let path = NSHomeDirectory() + "/Library/Caches"
        do {
            try FileManager.default.removeItem(atPath: path)
        }
        catch {
            print("removeItem fail")
        }

        //get cache
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            let cache = CacheManager().getCacheSize(withFilePath: path)
            print("cleanCache cache = \(cache)")

            let content: [String: Any] = [
                "code": "201",
                "cache": cache,
                "msg": "clean cache success"
            ]
            let json = JSON(content)
            self.wk.evaluateJavaScript("commFn.func.pg_memMain.rtAppCache(JSON.stringify(\(json)));") { (any, error) in
                if error == nil {
                    print("commFn.func.pg_memMain.rtAppCache success")
                } else {
                    print(error?.localizedDescription)
                }
            }
        }
    }

    @objc func callLogout() {
        print("#### callLogout")
        if #available(iOS 9.0, *) {
            let websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
            let date = Date(timeIntervalSince1970: 0)
            WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: date, completionHandler: {
                print("remove allWebsiteDataTypes data in iOS9 later")
            })

            let cookieStorage = HTTPCookieStorage.shared
            cookieStorage.removeCookies(since: Date.distantPast)
        } else {
            var libraryPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, false).first!
            libraryPath += "/Cookies"

            do {
                try FileManager.default.removeItem(atPath: libraryPath)
            } catch {
                print("error")
            }
            URLCache.shared.removeAllCachedResponses()
        }
    }

    func callReload() {
        print("#### callReload")

        self.wk.reload()
    }

    //new
    var newWK: WKWebView!
    var newWKIsOpened = false
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        if !TaipeiWebConf {
            if navigationAction.targetFrame == nil {
                if let request_url = navigationAction.request.url {
                    self.blankURL = request_url.absoluteString
                    webView.load(navigationAction.request)
                }
            }
            return nil
        } else {
            if self.newWK == nil {
                self.newWK = WKWebView(frame: UIScreen.main.bounds, configuration: configuration)
                self.newWK.uiDelegate = self
                self.newWK.navigationDelegate = self
                self.newWKIsOpened = true

                self.newWK.evaluateJavaScript("(function (){var _close = window.close;window.close = function () {webkit.messageHandlers.CallApp.postMessage('windowClose');_close();};})();") { (any, error) in
                    if error != nil {
                        print(error?.localizedDescription ?? "evaluateJavaScript Fail")
                    }
                }
            }

            if let myTargetFrame = navigationAction.targetFrame {
                if !myTargetFrame.isMainFrame {
                    print("myTargetFrame.isMainFrame is false")
                } else {
                    print("myTargetFrame.isMainFrame is true")
                }
            } else {
                print("navigationAction.targetFrame = nil")
            }

            return self.newWK
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        //        print("###2 sourceFrame = \(navigationAction.sourceFrame)")
        //        print("#### targetFrame = \(navigationAction.targetFrame)")
        if !TaipeiWebConf {
            print("#### navigationAction.request.url = \(navigationAction.request.url!)")
            if blankURL != "" {
                //            print("### blankURL = \(blankURL)")
                if (!blankURL.lowercased().hasPrefix("http://")) && (!blankURL.lowercased().hasPrefix("https://")) {
                    let alert = UIAlertController(title: "网站开启错误", message: "无法开启网站，如有任何问题请联系在线客服", preferredStyle: .alert)
                    let action = UIAlertAction(title: "确认", style: .default, handler: nil)
                    alert.addAction(action)
                    present(alert, animated: true, completion: nil)
                } else {
                    if let url = URL(string: self.blankURL) {
                        if #available(iOS 10.3, *) {
                            if checkGameContent() {
                                WebData.shared.setOther(string: self.blankURL)
                                performSegue(withIdentifier: "show", sender: self)
                            } else {
                                if url.absoluteString.contains("v66") {
                                    //客服系統
                                    UIApplication.shared.openURL(url)
                                } else {
                                    let svc = SFSafariViewController(url: url)
                                    svc.delegate = self
                                    present(svc, animated: true, completion: nil)
                                }
                            }
                        } else {
                            //10.2 以下
                            if checkGameContent() {
                                if self.blankURL.contains("-pt-") || self.blankURL.contains("/pt") {
                                    let svc = SFSafariViewController(url: url)
                                    svc.delegate = self
                                    present(svc, animated: true, completion: nil)
                                } else {
                                    WebData.shared.setOther(string: self.blankURL)
                                    performSegue(withIdentifier: "show", sender: self)
                                }
                            } else {
                                if url.absoluteString.contains("v66") {
                                    //客服系統
                                    UIApplication.shared.openURL(url)
                                } else {
                                    let svc = SFSafariViewController(url: url)
                                    svc.delegate = self
                                    present(svc, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                }
            }
            decisionHandler(self.blankURL != "" ? WKNavigationActionPolicy.cancel : WKNavigationActionPolicy.allow)

            self.blankURL = ""
        } else {
            if webView == self.newWK {
                print("$$$$ 1 newWK navigationAction.request.url = \(navigationAction.request.url!)")
                if let blankURL = navigationAction.request.url?.absoluteString {
                    if(blankURL.lowercased().contains("loading") || (!blankURL.lowercased().hasPrefix("http://")) && (!blankURL.lowercased().hasPrefix("https://"))) {
                        decisionHandler(WKNavigationActionPolicy.cancel)
                    } else {
                        if WebData.shared.nowOpenGame {
                            WebData.shared.setOther(string: blankURL)
                            performSegue(withIdentifier: "show", sender: self)
                        } else {
                            if let url = URL(string: blankURL) {
                                let svc = SFSafariViewController(url: url)
                                svc.delegate = self
                                present(svc, animated: true, completion: nil)
                            }
                        }

                        decisionHandler(WKNavigationActionPolicy.cancel)
                    }
                }
            } else {
                print("#### 1 webView navigationAction.request.url = \(navigationAction.request.url!)")
                if let blankURL = navigationAction.request.url?.absoluteString {
                    if (!blankURL.lowercased().hasPrefix("http://")) && (!blankURL.lowercased().hasPrefix("https://")) {

                        //                    let scheme1 = "itmss"
                        //                    let scheme2 = "itms-services"
                        if let scheme = navigationAction.request.url!.scheme {
                            if scheme != "http" && scheme != "https" {
                                //                            if UIApplication.shared.canOpenURL(navigationAction.request.url!){
                                print("open app")
                                UIApplication.shared.openURL(navigationAction.request.url!)
                                //                            }
                            }
                        }

                        decisionHandler(WKNavigationActionPolicy.cancel)
                    } else {
                        decisionHandler(WKNavigationActionPolicy.allow)
                    }
                }
            }
        }
    }

    @objc dynamic func checkGameContent() -> Bool {
        //old & new 介面
        if self.blankURL.contains("ot/MbProxy") || self.blankURL.contains("game/proxy") || self.blankURL.contains("game/page/html") {
            return true
        } else {
            return false
        }
    }

    func getDeviceIP() {
        APIManager.shared.getConnectionIP(urlString: CHECKIP_URL) { (str) in
            if let str = str {
                self.deviceIp = str.replacingOccurrences(of: "\n", with: "")
            }
        }
    }

    func showAlert(result: String) {
        var message = "Device OS: iOS \(self.deviceVersion)\nHostName: \(self.hostDomain)\nConnection mode: \(self.ReachableVia)\nDevice IP: \(self.deviceIp)"
        message += result

        let alert = UIAlertController(title: "没有网路 或 系统错误\n请重新尝试", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "重新尝试", style: .destructive, handler: { (action) in
            if let urlString = self.web_url {
                if let url = URL(string: urlString) {
                    let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 60)
                    self.wk.load(request)
                }
            }
        })
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }

    func pingAction(completionHandler: @escaping (String) -> Void) {
        self.service = PPSPingServices.service(withAddress: self.hostDomain, maximumPingTimes: 4)
        self.service.start { (summary, pingItems) in
            self.pingCount += 1
            if let result = summary {
                let res = "\(result)"

                self.failString += "\n\(res)"

                if self.pingCount == 4 {
                    self.service = nil
                    //                    print("#6 failstring = \(self.failString)")
                    print("Stop ping")
                    completionHandler("Stop")
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Start!!!")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Fail!!!")

        /* 連線異常 Ping Alert 暫時用不到了
        self.failString = "\n\n\(error.localizedDescription)\n"

        let reachability = Reachability(hostName: "www.apple.com")
        if reachability?.currentReachabilityStatus().rawValue == 0 {
            self.deviceIp = ""
            self.ReachableVia = "No Network"
        } else {
            getDeviceIP()

            switch reachability?.currentReachabilityStatus() {
            case ReachableViaWWAN?:
                self.ReachableVia = "3G/4G"
                break
            case ReachableViaWiFi?:
                self.ReachableVia = "WiFi"
                break
            default:
                self.ReachableVia = "WiFi/4G"
                break
            }
        }

        self.pingCount = 0
        self.pingAction { (res) in
            if res == "Stop" {
                self.showAlert(result: self.failString)
            }
        }
         */
        
        let langDic = DeviceData.current.getDeviceLang()
        
        let alert = UIAlertController(title: langDic["webDidLoadFail"], message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: langDic["retry"], style: .default, handler: { _ in
            self.wk.reload()
        }))
        present(alert, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Finish!!!")
        self.screenImg.isHidden = true
        self.wk.isHidden = false
        self.progressView.setProgress(0.0, animated: false)
        statusBarStyle = .lightContent

        //        self.wk.evaluateJavaScript(getSiteTitle()) { (any, error) in
        //            if error == nil{
        //                print("Success")
        //            }else{
        //                print(error?.localizedDescription ?? "evaluateJavaScript Fail")
        //            }
        //        }
    }

    @objc dynamic func getSiteTitle() -> String {
        return "setInterval(chk, 1e3);function chk() {var lis = document.querySelectorAll('.lobbygame li');for(var i=0;i<lis.length;i++){var li = lis[i];if (li.__webview_click){continue}li.onclick=(function(li){return function(){var text = (li.getElementsByTagName('p')[0].textContent);console.log(text);window.webkit.messageHandlers.CallApp.postMessage({title:text})}}(li));li . __webview_click = true};}"
    }

    //add screen image and UUIDLabel, progressview
    fileprivate func configScreenLoadingView() {
        screenImg = UIImageView()
        screenImg.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(screenImg)
        NSLayoutConstraint(item: screenImg, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: screenImg, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: screenImg, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
        NSLayoutConstraint(item: screenImg, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        screenImg.image = UIImage(named: "launch image-1")
        screenImg.contentMode = UIView.ContentMode.scaleAspectFill

        showUUID()
        addProgressView()
    }

    fileprivate func addProgressView() {
        let langDic = DeviceData.current.getDeviceLang()
        progressLabel = UILabel()
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        screenImg.addSubview(progressLabel)
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([progressLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50.0), progressLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50.0), progressLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10.0 + progressYOffset), progressLabel.heightAnchor.constraint(equalToConstant: 30.0)])
        }
        else {
            NSLayoutConstraint(item: progressLabel, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 50.0).isActive = true
            NSLayoutConstraint(item: progressLabel, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -50.0).isActive = true
            NSLayoutConstraint(item: progressLabel, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -10.0 + progressYOffset).isActive = true
            NSLayoutConstraint(item: progressLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 30.0).isActive = true
        }
        progressLabel.textAlignment = .center
        progressLabel.text = langDic["resourceLoading"]
        progressLabel.textColor = AppData.isWhiteBackground ? .black : .white

        progressView = UIProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        screenImg.addSubview(progressView)
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([progressView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50.0), progressView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50.0), progressView.bottomAnchor.constraint(equalTo: progressLabel.topAnchor, constant: 0.0)])
        } else {
            NSLayoutConstraint(item: progressView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 50.0).isActive = true
            NSLayoutConstraint(item: progressView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -50.0).isActive = true
            NSLayoutConstraint(item: progressView, attribute: .bottom, relatedBy: .equal, toItem: progressLabel, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
        }
        progressView.trackTintColor = .clear
        progressView.progressTintColor = AppData.isWhiteBackground ? .black : .white
        self.wk.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            let langDic = DeviceData.current.getDeviceLang()
            let text = langDic["resourceLoading"]!
            //            print("estimatedProgress = \(Int(self.wk.estimatedProgress * 100))")
            self.progressLabel.text = "\(text) \(Int(self.wk.estimatedProgress * 100))%"
            progressView.isHidden = self.wk.estimatedProgress == 1
            progressView.setProgress(Float(self.wk.estimatedProgress), animated: true)
        }
    }

    fileprivate func showUUID() {
        let uuid = DeviceData.current.uuid
        //        print("uuid = \(uuid)")
        let index = uuid.index(uuid.endIndex, offsetBy: -6)
        let subStr = String(uuid[index...])
        //        print("subStr = \(subStr)")

        uuidLabel = UILabel()
        uuidLabel.translatesAutoresizingMaskIntoConstraints = false
        screenImg.addSubview(uuidLabel)
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([uuidLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10 + progressYOffset), uuidLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10), uuidLabel.widthAnchor.constraint(equalToConstant: 80), uuidLabel.heightAnchor.constraint(equalToConstant: 30)])
        } else {
            NSLayoutConstraint(item: uuidLabel, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -10 + progressYOffset).isActive = true
            NSLayoutConstraint(item: uuidLabel, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -10).isActive = true
            NSLayoutConstraint(item: uuidLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 80).isActive = true
            NSLayoutConstraint(item: uuidLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 30).isActive = true
        }
        uuidLabel.text = "****\(subStr)"
        uuidLabel.textColor = AppData.isWhiteBackground ? .black : .white
        uuidLabel.adjustsFontSizeToFitWidth = true
    }
    //add screen image and UUIDLabel, progressview end

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //        print("### WebkitViewController viewWillAppear")

        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.setToolbarHidden(true, animated: false)

        isStatusBarHidden = false
        
        // 還沒進首頁的 statusBarStyle 根據背脊設置顏色，進入後為白色
        if isViewAppeared {
            statusBarStyle = .lightContent
        }
        else {
            statusBarStyle = AppData.isWhiteBackground ? .default : .lightContent
        }

        AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        WebData.shared.setBlankTitle(blankTitle: "游戏大厅")

        WebData.shared.nowOpenGame = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //        print("### WebkitViewController viewDidAppear")

        if TaipeiWebConf {
            self.newWKClose()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //        print("### WebkitViewController viewWillDisappear")

        self.navigationController?.setNavigationBarHidden(false, animated: false)
        statusBarStyle = .default

        AppUtility.lockOrientation(.allButUpsideDown)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("### WebkitViewController viewDidDisappear")

        self.wk.scrollView.delegate = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.edgesForExtendedLayout = []

        WebData.shared.setIsHiddenToolBar(isHiddenToolBar: true)
        WebData.shared.setIsHiddenReloadButton(isHiddenReloadButton: true)

        if let urlString = WebData.shared.mainWeb_url {
            print("####1 self.web_url == \(urlString)")
            self.web_url = urlString

            let splitArray = urlString.components(separatedBy: "//")
            let newSplitArray = splitArray[1].components(separatedBy: "/")
            self.hostDomain = newSplitArray[0]
        } else {
            if let hcode_url = UserDefaults.standard.string(forKey: "hcode_url") {
                print("####2 self.web_url == \(hcode_url)")
                self.web_url = hcode_url

                let splitArray = hcode_url.components(separatedBy: "//")
                let newSplitArray = splitArray[1].components(separatedBy: "/")
                self.hostDomain = newSplitArray[0]
            }
        }

        //test only
        //        UserDefaults.standard.set(self.web_url!, forKey: "lastURL")
        //        UserDefaults.standard.synchronize()
        //test only

        if let pinCode = UserDefaults.standard.string(forKey: "ping_code") {
            let path = NSString(string: self.web_url!)
            self.web_url = path.appendingPathComponent(pinCode)
        }

        //        self.web_url = "http://www.mu1.bck-mu-dbp.lorde1721.rdgs.team/mb/index/app"
        //        getCookies()

        setWKWebview()

        configScreenLoadingView()

        if !WebData.shared.isUseHardURL {
            repeatAction()
        }

        //        addButtons()
    }

    func repeatAction() {
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.feedbackThreadAPI), userInfo: nil, repeats: true)
    }

    @objc func feedbackThreadAPI() {
        if LogData.shared.checklinkLogID != "" && LogData.shared.checklinkURLFinal != "" {
            self.timer.invalidate()
            APIManager.shared.postAppThreadAPI(domain: LogData.shared.dBDomainFinal, deviceID: DeviceData.current.uuid, startTime: LogData.shared.checklinkStartTime, endTime: LogData.shared.checklinkEndTime, requestURL: LogData.shared.checklinkURLFinal, response: LogData.shared.checklinkResponse, sessID: LogData.shared.sessID, logID: LogData.shared.checklinkLogID, status: "2", userAgent: WebData.shared.userAgent, cpu: DeviceData.current.showCPU(), memUsed: DeviceData.current.showAppUsedMemory(), memory: DeviceData.current.showMemory(), space: DeviceData.current.space, radioTech: DeviceData.current.showCarrierRadioTech(), carrierName: DeviceData.current.showCarrierName(), deviceModel: DeviceData.current.deviceModel) { (json) in
                if let json = json {
                    //                    print(json)
                    if let _ = json["success"].int {
                        print("##### Checklink feedback success #####")
                    }
                }
            }
        }
    }

    func addButtons() {
        let aButton = UIButton(type: .system)
        aButton.translatesAutoresizingMaskIntoConstraints = false
        self.wk.addSubview(aButton)
        NSLayoutConstraint(item: aButton, attribute: .top, relatedBy: .equal, toItem: self.wk, attribute: .top, multiplier: 1.0, constant: 50).isActive = true
        NSLayoutConstraint(item: aButton, attribute: .trailing, relatedBy: .equal, toItem: self.wk, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: aButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100).isActive = true
        NSLayoutConstraint(item: aButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 30).isActive = true
        aButton.setTitle("showCache", for: UIControl.State.normal)
        aButton.titleLabel?.adjustsFontSizeToFitWidth = true
        aButton.backgroundColor = AppData.isWhiteBackground ? .black : .white
        aButton.addTarget(self, action: #selector(self.showCache), for: UIControl.Event.touchUpInside)

        let bButton = UIButton(type: .system)
        bButton.translatesAutoresizingMaskIntoConstraints = false
        self.wk.addSubview(bButton)
        NSLayoutConstraint(item: bButton, attribute: .top, relatedBy: .equal, toItem: self.wk, attribute: .top, multiplier: 1.0, constant: 100).isActive = true
        NSLayoutConstraint(item: bButton, attribute: .trailing, relatedBy: .equal, toItem: self.wk, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: bButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100).isActive = true
        NSLayoutConstraint(item: bButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 30).isActive = true
        bButton.setTitle("cleanCache", for: UIControl.State.normal)
        bButton.titleLabel?.adjustsFontSizeToFitWidth = true
        bButton.backgroundColor = AppData.isWhiteBackground ? .black : .white
        bButton.addTarget(self, action: #selector(self.cleanCache), for: UIControl.Event.touchUpInside)
    }

    @objc func printHttpCookieStorage() {
        let cookieStorage = HTTPCookieStorage.shared
        if let cookieArr = cookieStorage.cookies {
            for cookie in cookieArr {
                print("cookie.name = \(cookie.name), cookie.value = \(cookie.value)")
            }
        }
    }

    @objc func printWKCookieStorage() {
        if #available(iOS 11.0, *) {
            let storage = self.wk.configuration.websiteDataStore.httpCookieStore
            storage.getAllCookies { (cookies) in
                for cookie in cookies {
                    print("cookie.name = \(cookie.name), cookie.value = \(cookie.value)")
                }
            }
        } else {
            // Fallback on earlier versions
            print(" old version")
        }
    }

    func getCookies() {
        self.cookieTmp = ""
        let cookieStorage = HTTPCookieStorage.shared
        if let cookieArr = cookieStorage.cookies {
            for cookie in cookieArr {
                //                print(" cookie = \(cookie)")
                print("cookie.name = \(cookie.name), cookie.value = \(cookie.value)")
                let a_cookie = "\(cookie.name)=\(cookie.value);"
                self.cookieTmp += a_cookie
            }
        }
    }

    //JavaScript handle start
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let langDic = DeviceData.current.getDeviceLang()
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: langDic["confirm"], style: .default) { (action) in
            completionHandler()
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let langDic = DeviceData.current.getDeviceLang()
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: langDic["confirm"], style: .default) { (action) in
            completionHandler(true)
        }
        let cancelAction = UIAlertAction(title: langDic["cancel"], style: .cancel) { (action) in
            completionHandler(false)
        }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let langDic = DeviceData.current.getDeviceLang()
        let alert = UIAlertController(title: prompt, message: nil, preferredStyle: .alert)
        alert.addTextField { (textfield) in
            textfield.text = defaultText
        }
        let okAction = UIAlertAction(title: langDic["confirm"], style: .default) { (action) in
            let input = alert.textFields?.first?.text
            completionHandler(input)
        }
        let cancelAction = UIAlertAction(title: langDic["cancel"], style: .cancel) { (action) in
            completionHandler(nil)
        }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    //javaScript handle end

    func setWKWebview() {
        let wkUserController = WKUserContentController()

        let js = "$('meta[name=description]').remove(); $('head').append( '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1,user-scalable=no\">' );"
        // 定義寬為裝置寬，禁止縮放

        let css = "body{-webkit-user-select:none;-webkit-user-drag:none;}"
        let javascript = "var style = document.createElement('style');style.type = 'text/css';var cssContent = document.createTextNode('\(css)');style.appendChild(cssContent);document.body.appendChild(style);"
        // 不執行前端選取功能、拖曳功能

        let touchCalloutJS = "document.documentElement.style.webkitTouchCallout='none';"
        // 不执行前端弹出列表的JS代码

        let wkUserScript = WKUserScript(source: js, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
        let wkUserScript1 = WKUserScript(source: javascript, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
        let wkUserScript2 = WKUserScript(source: touchCalloutJS, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)

        //        wkUserController.addUserScript(wkUserScript)
        if !TaipeiWebConf {
            wkUserController.addUserScript(wkUserScript1)
        }
        wkUserController.addUserScript(wkUserScript2)
        //add scriptMessageHandler
        wkUserController.add(self, name: "CallApp")
        let conf = WKWebViewConfiguration()
        conf.userContentController = wkUserController
        conf.allowsInlineMediaPlayback = true

        self.wk = WKWebView(frame: CGRect.zero, configuration: conf)
        wk.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self.wk)

        if #available(iOS 11, *) {
            NSLayoutConstraint.activate([wk.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), wk.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)])

            NSLayoutConstraint.activate([wk.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor), wk.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)])
        } else {
            NSLayoutConstraint(item: wk, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: statusBarHeight).isActive = true
            NSLayoutConstraint(item: wk, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
            NSLayoutConstraint(item: wk, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
            NSLayoutConstraint(item: wk, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        }

        self.wk.customUserAgent = WebData.shared.userAgent

        self.wk.navigationDelegate = self
        self.wk.uiDelegate = self

        self.wk.isHidden = true

        self.view.backgroundColor = UIColor.black
        if KEY_CODE == "518" {
            self.wk.isOpaque = false
            let imageView = UIImageView(frame: self.wk.frame)
            imageView.image = UIImage(named: "background")
            imageView.contentMode = UIView.ContentMode.scaleAspectFill
            self.view.addSubview(imageView)
        } else {
            self.wk.backgroundColor = UIColor.black
        }

        self.wk.scrollView.delegate = self
        self.wk.scrollView.bounces = false

        if let urlString = self.web_url {
            if let url = URL(string: urlString) {
                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 60)
                //                request.addValue(self.cookieTmp, forHTTPHeaderField: "Cookie")
                self.wk.load(request)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension UINavigationController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? .default
    }
}
