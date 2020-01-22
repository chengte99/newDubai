//
//  NewWindowViewController.swift
//  newDubai
//
//  Created by KevinLin on 2019/6/28.
//  Copyright © 2019 KevinLin. All rights reserved.
//

import UIKit
import WebKit
import SafariServices
import JJFloatingActionButton

enum Racing128AccountLoad {
    case never
    case prepare
    case ready
    case executed
}

class NewWindowViewController: UIViewController, WKUIDelegate, UIGestureRecognizerDelegate, WKNavigationDelegate, SFSafariViewControllerDelegate, WKScriptMessageHandler {
    fileprivate let actionButton = JJFloatingActionButton()

    var wk: WKWebView!
    var web_url: String?
    var progressView: UIProgressView!
    var processPool: WKProcessPool?
    let statusBarHeight = UIApplication.shared.statusBarFrame.height
    var racing128AccountReload: Racing128AccountLoad = .never

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

        if let tag = message.body as? String {
            // 收到網頁呼叫windowClose，關閉頁面 / 賽馬狗投注記錄頁面會一直call windowClose，忽略它
            if tag == "windowClose" && racing128AccountReload != .executed {
                print("window.close()")
                self.close()
            }
        }
    }

    func callLogout() {
        print("#### callLogout")
        if #available(iOS 9.0, *) {
            let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
            let date = NSDate(timeIntervalSince1970: 0)

            WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date as Date, completionHandler: { })
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
        if let urlString = self.web_url {
            if let url = URL(string: urlString) {
                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 60)
                self.wk.load(request)
            }
        }
    }

    func setNavigationBarAndToolBarItems() {
        let backBarButtonItem = UIBarButtonItem(image: UIImage(named: "icons8-back_filled"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.back))
        let closeBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.stop, target: self, action: #selector(self.close))

        self.navigationItem.setLeftBarButtonItems([backBarButtonItem], animated: true)
        if !WebData.shared.isHiddenReloadButton {
            let reloadBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refresh))
            self.navigationItem.setRightBarButtonItems([closeBarButtonItem, reloadBarButtonItem], animated: true)
        } else {
            self.navigationItem.setRightBarButtonItems([closeBarButtonItem], animated: true)
        }
    }

    @objc func back() {
        if self.wk.canGoBack {
            self.wk.goBack()
        } else {
            self.close()
        }
    }

    @objc func close() {
        let langDic = DeviceData.current.getDeviceLang()
        let alert = UIAlertController(title: nil, message: langDic["exitMessage"], preferredStyle: .alert)
        let okAction = UIAlertAction(title: langDic["confirm"], style: .default) { (action) in
            self.wk.removeObserver(self, forKeyPath: "estimatedProgress", context: nil)
            self.wk.stopLoading()
            self.wk.removeFromSuperview()
            self.wk = nil
            self.progressView.removeFromSuperview()
            self.progressView = nil
            self.navigationController?.popViewController(animated: true)
        }
        let cancelAction = UIAlertAction(title: langDic["cancel"], style: .default, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }

    @objc func refresh() {
        self.wk.reload()
    }

    func configureActionButton() {
        actionButton.overlayView.backgroundColor = UIColor(hue: 0.31, saturation: 0.37, brightness: 0.10, alpha: 0.30)
        actionButton.buttonImage = #imageLiteral(resourceName: "icons8-menu")
        actionButton.buttonColor = .white
        actionButton.buttonImageColor = .white

        //        actionButton.itemAnimationConfiguration = .circularSlideIn(withRadius: 90)
        actionButton.itemAnimationConfiguration = .circularPopUp(withRadius: 90)
        actionButton.buttonAnimationConfiguration = .rotation(toAngle: .pi)
        //        actionButton.buttonAnimationConfiguration = .transition(toImage: #imageLiteral(resourceName: "right"))
        //        actionButton.buttonAnimationConfiguration.opening.duration = 0.8
        //        actionButton.buttonAnimationConfiguration.closing.duration = 0.6
    }

    func addFloatingActionButton() {
        configureActionButton()

        actionButton.addItem(image: UIImage(named: "icons8-refresh")) { item in
            self.refresh()
        }

        actionButton.addItem(image: UIImage(named: "icons8-reply_arrow")) { item in
            self.back()
        }

        actionButton.addItem(image: UIImage(named: "icons8-home")) { item in
            self.close()
        }

        if WebData.shared.refreshIsDisable {
            actionButton.items[0].isEnabled = false
            actionButton.items[0].buttonColor = UIColor.gray
            actionButton.items[0].buttonImageColor = UIColor.gray
        }
        if WebData.shared.backIsDisable {
            actionButton.items[1].isEnabled = false
            actionButton.items[1].buttonColor = UIColor.gray
            actionButton.items[1].buttonImageColor = UIColor.gray
        }

        //        actionButton.display(inViewController: self)
        view.addSubview(actionButton)

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        actionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        if #available(iOS 11.0, *) {
            actionButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 30).isActive = true
            actionButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        } else {
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 25).isActive = true
            actionButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.edgesForExtendedLayout = []

        if let urlString = WebData.shared.openNewWindow {
            self.web_url = urlString
        }

        setNavigationBarAndToolBarItems()

        setWKWebview()

        addProgressView()

        if USEFLOATING {
            addFloatingActionButton()
        } else {
            setSwipeMethod()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let title = WebData.shared.blankTitle {
            self.navigationItem.title = title
        }

        if USEFLOATING {
            isStatusBarHidden = true
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            self.navigationController?.setToolbarHidden(true, animated: true)
        } else {
            self.navigationController?.setNavigationBarHidden(false, animated: true)

            if WebData.shared.isHiddenToolBar {
                self.navigationController?.setToolbarHidden(true, animated: true)
            } else {
                self.navigationController?.setToolbarHidden(false, animated: true)
            }

            statusBarStyle = .lightContent
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        statusBarStyle = .default
    }

    fileprivate func addProgressView() {
        self.progressView = UIProgressView()
        self.wk.addSubview(progressView)
        self.progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: self.progressView, attribute: .top, relatedBy: .equal, toItem: self.wk, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self.progressView, attribute: .leading, relatedBy: .equal, toItem: self.wk, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self.progressView, attribute: .trailing, relatedBy: .equal, toItem: self.wk, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true

        self.progressView.progressTintColor = .white
        self.progressView.trackTintColor = .clear
        self.wk.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            self.progressView.isHidden = self.wk.estimatedProgress == 1
            self.progressView.setProgress(Float(self.wk.estimatedProgress), animated: true)
        }
    }

    func setSwipeMethod() {
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.swipe))
        swipeUp.delegate = self
        swipeUp.direction = .up
        swipeUp.numberOfTouchesRequired = 1
        self.wk.addGestureRecognizer(swipeUp)
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.swipe))
        swipeDown.delegate = self
        swipeDown.direction = .down
        swipeDown.numberOfTouchesRequired = 1
        self.wk.addGestureRecognizer(swipeDown)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    @objc func swipe(recognizer: UISwipeGestureRecognizer) {
        //        if UIDevice.current.orientation != .portrait{
        //            // do nothing
        //            print("UIDevice.current.orientation != .portrait")
        //        }
        if UIApplication.shared.statusBarOrientation != .portrait {
            // do nothing
            print("UIApplication.shared.statusBarOrientation != .portrait")
        } else {
            if recognizer.direction == .up {
                print("......swipe up")
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.navigationController?.setToolbarHidden(true, animated: true)
                isStatusBarHidden = true

            } else {
                print("......swipe down")
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                if WebData.shared.isHiddenToolBar {
                    self.navigationController?.setToolbarHidden(true, animated: true)
                } else {
                    self.navigationController?.setToolbarHidden(false, animated: true)
                }
                isStatusBarHidden = false
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if (UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight) {
            print("UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight")
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            //            self.navigationController?.setToolbarHidden(true, animated: true)

            isStatusBarHidden = true

        } else {
            print("UIDevice.current.orientation != .landscapeLeft && UIDevice.current.orientation != .landscapeRight")
            //            self.navigationController?.setNavigationBarHidden(false, animated: true)
            //            self.navigationController?.setToolbarHidden(false, animated: true)
        }
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        if let myTargetFrame = navigationAction.targetFrame {
            if !myTargetFrame.isMainFrame {
                webView.load(navigationAction.request)
            }
        } else {
            webView.load(navigationAction.request)
        }

        return nil
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        //        print("###2 sourceFrame = \(navigationAction.sourceFrame)")
//                print("#### targetFrame = \(navigationAction.targetFrame)")
        print("#### navigationAction.request.url = \(navigationAction.request.url!)")

        if let myTargetFrame = navigationAction.targetFrame {
            if !myTargetFrame.isMainFrame {
                webView.evaluateJavaScript("var a = document.getElementsByTagName('a');for(var i=0;i<a.length;i++){a[i].setAttribute('target','');}", completionHandler: nil)
                
                // 修正 賽馬狗無法檢視下注記錄，會顯示白畫面 的問題：讀取成功，重新讀取旗標改為false
                if let url = navigationAction.request.url, url.absoluteString.contains("www.racing128.com/account/account_data.aspx") {
                    print("#### racing128 account reload success")
                }
            } else {
                // 修正 賽馬狗無法檢視下注記錄，會顯示白畫面 的問題：開啟記錄頁時標示重新讀取
                if let url = navigationAction.request.url, url.absoluteString.contains("www.racing128.com/account.aspx") {
                    if racing128AccountReload == .never {
                        racing128AccountReload = .prepare
                        print("#### racing128 account reload prepare")
                    }
                }
            }
        } else {
            webView.evaluateJavaScript("var a = document.getElementsByTagName('a');for(var i=0;i<a.length;i++){a[i].setAttribute('target','');}", completionHandler: nil)
        }

        //        let scheme1 = "itmss"
        //        let scheme2 = "itms-services"
        if let scheme = navigationAction.request.url!.scheme {
            if scheme != "http" && scheme != "https" {
                //                if UIApplication.shared.canOpenURL(navigationAction.request.url!){
                print("open app")
                UIApplication.shared.openURL(navigationAction.request.url!)
                //                }
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }

    @objc dynamic func closeGestureScreen() -> String {
        return "setInterval(chkScreen, 1e3); function chkScreen() {var apContainer = document.querySelector(\"#alphaContainer\"); var touchIntro = document.querySelector(\"#touchIntro\"); var fullscreen_div = document.querySelector(\"#fullscreen_div\"); var fullscreen = document.querySelector(\"#fullscreen\"); if( apContainer ) {apContainer.style.display =\"none\";} if( touchIntro ) {touchIntro.style.display =\"none\";} if( fullscreen_div ) {fullscreen_div.style.display =\"none\";} if( fullscreen ) {fullscreen.style.display =\"none\";}}"
    }
    
    /// 修正 賽馬狗無法檢視下注記錄，會顯示白畫面 的問題
    func fixRacing128AccountLoad() {
        // 刷新一次以修正此問題
        if racing128AccountReload == .prepare {
            racing128AccountReload = .ready
            print("#### racing128 account reload ready")

            // 等待1秒後刷新頁面才有效
            _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                if self.racing128AccountReload == .ready {
                    self.racing128AccountReload = .executed
                    print("#### racing128 account executed")
                    
                    // 重新讀取初始頁面以正確顯示頁面
                    self.callReload()
                }
            }
        }
    }

    /// WK delegate method
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("##### Finish !!!")
        self.progressView.setProgress(0.0, animated: false)

        // 加入關閉遮罩監聽
        self.wk.evaluateJavaScript(closeGestureScreen(), completionHandler: { (any, error) in
            if error == nil {
                print("do js success")
            }
            
            // 修正 賽馬狗無法檢視下注記錄，會顯示白畫面 的問題
            self.fixRacing128AccountLoad()
        })
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("##### Start !!!")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("##### Fail !!!")
    }
    //end

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

    @objc dynamic func isNeedChangeUserAgent(url: String) -> Bool {
        if !url.contains("jbb_xfball") && !url.contains("jbb/sport") {
            return true
        } else {
            return false
        }
    }

    fileprivate func setWKWebview() {
        let wkUserController = WKUserContentController()

        let touchCalloutJS = "document.documentElement.style.webkitTouchCallout='none';"
        // 不执行前端弹出列表的JS代码

        let wkUserScript2 = WKUserScript(source: touchCalloutJS, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)

        wkUserController.addUserScript(wkUserScript2)

        let windowCloseJS = "(function (){var _close = window.close;window.close = function () {webkit.messageHandlers.CallApp.postMessage('windowClose');_close();};})();"
        // 前端執行windo.close()時替換代碼

        let wkUserScript3 = WKUserScript(source: windowCloseJS, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)

        wkUserController.addUserScript(wkUserScript3)
        //add scriptMessageHandler
        wkUserController.add(self, name: "CallApp")
        let conf = WKWebViewConfiguration()
        conf.userContentController = wkUserController
        conf.allowsInlineMediaPlayback = true

        conf.processPool = self.processPool!

        self.wk = WKWebView(frame: self.view.bounds, configuration: conf)
        //        self.wk = WKWebView(frame: CGRect.zero, configuration: conf)
        //        wk.translatesAutoresizingMaskIntoConstraints = false
        //        view.addSubview(self.wk)
        //
        //        if #available(iOS 11, *){
        //            NSLayoutConstraint.activate([wk.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), wk.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)])
        //
        //            NSLayoutConstraint.activate([wk.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor), wk.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)])
        //        }else{
        //            NSLayoutConstraint(item: wk, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: statusBarHeight).isActive = true
        //            NSLayoutConstraint(item: wk, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
        //            NSLayoutConstraint(item: wk, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        //            NSLayoutConstraint(item: wk, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        //        }

        if let url = self.web_url {
            if isNeedChangeUserAgent(url: url) {
                self.wk.customUserAgent = WebData.shared.userAgent
            }
        }

        self.wk.navigationDelegate = self
        self.wk.uiDelegate = self

        self.view.backgroundColor = .black
        self.wk.backgroundColor = .black

        self.wk.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        if let urlString = web_url {
            if let url = URL(string: urlString) {
                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 60)
                self.wk.load(request)
                self.view.addSubview(self.wk)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

}
