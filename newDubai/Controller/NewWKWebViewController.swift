//
//  NewWKWebViewController.swift
//  newDubai
//
//  Created by KevinLin on 2019/6/28.
//  Copyright © 2019 KevinLin. All rights reserved.
//

import UIKit
import WebKit
import SafariServices
import JJFloatingActionButton

class NewWKWebViewController: UIViewController, WKUIDelegate, UIGestureRecognizerDelegate, WKNavigationDelegate, SFSafariViewControllerDelegate, WKScriptMessageHandler {
    fileprivate let actionButton = JJFloatingActionButton()
    
    var wk: WKWebView!
    var web_url: String?
    var progressView: UIProgressView!
    let processPool = WKProcessPool()
    let statusBarHeight = UIApplication.shared.statusBarFrame.height
    
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
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.body)
        
        if let tag = message.body as? String{
            if tag == "windowClose"{
                print("window.close()")
                self.close()
            }
        }
        
        if let dic = message.body as? [String: Any]{
            
            if let registerString = dic["url"] as? String{
                if let url = URL(string: registerString){
                    if UIApplication.shared.canOpenURL(url){
                        //                        UIApplication.shared.openURL(url)
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            }
        }
    }
    
    func newWKClose(){
        if self.newWK != nil{
            self.newWK.stopLoading()
            self.newWK.removeFromSuperview()
            self.newWK = nil
        }
    }
    
    func callLogout(){
        print("#### callLogout")
        if #available(iOS 9.0, *){
            let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
            let date = NSDate(timeIntervalSince1970: 0)
            
            WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date as Date, completionHandler:{ })
        }else{
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
    
    func callReload(){
        print("#### callReload")
        if let urlString = self.web_url{
            if let url = URL(string: urlString){
                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 60)
                self.wk.load(request)
            }
        }
    }
    
    @objc func toBack() {
        if self.wk.canGoBack {
            self.wk.goBack()
        }
    }
    
    @objc func toForward() {
        if self.wk.canGoForward {
            self.wk.goForward()
        }
    }
    
    @objc func toSafari() {
        if let urlString = self.wk.url?.absoluteString{
            if let url = URL(string: urlString){
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    func setNavigationBarAndToolBarItems() {
        let backBarButtonItem = UIBarButtonItem(image: UIImage(named: "icons8-back_filled"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.back))
        let closeBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.stop, target: self, action: #selector(self.close))
        
        self.navigationItem.setLeftBarButtonItems([backBarButtonItem], animated: true)
        if !WebData.shared.isHiddenReloadButton{
            let reloadBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refresh))
            self.navigationItem.setRightBarButtonItems([closeBarButtonItem, reloadBarButtonItem], animated: true)
        }else{
            self.navigationItem.setRightBarButtonItems([closeBarButtonItem], animated: true)
        }
        
        //set toolbar
        let backBtn = UIBarButtonItem(image: UIImage(named: "icons8-back_filled"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(NewWKWebViewController.toBack))
        let forwardBtn = UIBarButtonItem(image: UIImage(named: "icons8-forward_filled"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(NewWKWebViewController.toForward))
        let safariBtn = UIBarButtonItem(image: UIImage(named: "icons8-compass"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(NewWKWebViewController.toSafari))
        let fixedSpaceBtn = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        let flexibleSpaceBtn = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.setToolbarItems([backBtn, flexibleSpaceBtn, forwardBtn, flexibleSpaceBtn, fixedSpaceBtn, flexibleSpaceBtn, safariBtn], animated: true)
    }
    
    func configureActionButton(){
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
    
    func addFloatingActionButton(){
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
        
        if(WebData.shared.refreshIsDisable){
            actionButton.items[0].isEnabled = false
            actionButton.items[0].buttonColor = UIColor.gray
            actionButton.items[0].buttonImageColor = UIColor.gray
        }
        if(WebData.shared.backIsDisable){
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
        
        if let urlString = WebData.shared.otherWeb_url{
            self.web_url = urlString
        }
        
        setNavigationBarAndToolBarItems()
        
        setWKWebview()
        
        addProgressView()
        
        if USEFLOATING{
            addFloatingActionButton()
        }else{
            setSwipeMethod()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let title = WebData.shared.blankTitle{
            self.navigationItem.title = title
        }
        
        if USEFLOATING{
            isStatusBarHidden = true
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            self.navigationController?.setToolbarHidden(true, animated: true)
        }else{
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            
            if WebData.shared.isHiddenToolBar{
                self.navigationController?.setToolbarHidden(true, animated: true)
            }else{
                self.navigationController?.setToolbarHidden(false, animated: true)
            }
            
            statusBarStyle = .lightContent
            
            if (UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight){
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                isStatusBarHidden = true
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //        print("### NewWKWebkitViewController viewDidAppear")
        
        if TaipeiWebConf{
            self.newWKClose()
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
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress"{
            self.progressView.isHidden = self.wk.estimatedProgress == 1
            self.progressView.setProgress(Float(self.wk.estimatedProgress), animated: true)
        }
    }
    
    func setSwipeMethod() {
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(NewWKWebViewController.swipe))
        swipeUp.delegate = self
        swipeUp.direction = .up
        swipeUp.numberOfTouchesRequired = 1
        self.wk.addGestureRecognizer(swipeUp)
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(NewWKWebViewController.swipe))
        swipeDown.delegate = self
        swipeDown.direction = .down
        swipeDown.numberOfTouchesRequired = 1
        self.wk.addGestureRecognizer(swipeDown)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func swipe(recognizer: UISwipeGestureRecognizer){
        //        if UIDevice.current.orientation != .portrait{
        //            // do nothing
        //            print("UIDevice.current.orientation != .portrait")
        //        }
        if UIApplication.shared.statusBarOrientation != .portrait{
            // do nothing
            print("UIApplication.shared.statusBarOrientation != .portrait")
        }else{
            if recognizer.direction == .up{
                print("......swipe up")
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.navigationController?.setToolbarHidden(true, animated: true)
                isStatusBarHidden = true
                
            }else{
                print("......swipe down")
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                if WebData.shared.isHiddenToolBar{
                    self.navigationController?.setToolbarHidden(true, animated: true)
                }else{
                    self.navigationController?.setToolbarHidden(false, animated: true)
                }
                isStatusBarHidden = false
            }
            
            //            self.wk.frame = UIScreen.main.bounds
            //            self.wk.frame = self.view.bounds
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if (UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight){
            print("UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight")
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            //            self.navigationController?.setToolbarHidden(true, animated: true)
            
            isStatusBarHidden = true
            
        }else{
            print("UIDevice.current.orientation != .landscapeLeft && UIDevice.current.orientation != .landscapeRight")
            //            self.navigationController?.setNavigationBarHidden(false, animated: true)
            //            self.navigationController?.setToolbarHidden(false, animated: true)
        }
        
        //        self.wk.frame = UIScreen.main.bounds
    }
    
    //new
    var newWK: WKWebView!
    var newWKIsOpened = false
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        if self.newWK == nil{
            self.newWK = WKWebView(frame: UIScreen.main.bounds, configuration: configuration)
            self.newWK.uiDelegate = self
            self.newWK.navigationDelegate = self
            self.newWKIsOpened = true
        }
        
        if let myTargetFrame = navigationAction.targetFrame{
            if !myTargetFrame.isMainFrame{
                print("myTargetFrame.isMainFrame is false")
            }else{
                print("myTargetFrame.isMainFrame is true")
            }
        }else{
            print("navigationAction.targetFrame = nil")
        }
        
        return self.newWK
        //        return nil
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        //        print("###2 sourceFrame = \(navigationAction.sourceFrame)")
        //        print("#### targetFrame = \(navigationAction.targetFrame)")
        if webView == self.newWK{
            print("$$$$ 2 newWK navigationAction.request.url = \(navigationAction.request.url!)")
            if let blankURL = navigationAction.request.url?.absoluteString{
                if(blankURL.lowercased().contains("loading") || (!blankURL.lowercased().hasPrefix("http://")) && (!blankURL.lowercased().hasPrefix("https://"))){
                    decisionHandler(WKNavigationActionPolicy.cancel)
                }else{
                    if blankURL.contains("v66"){
                        if let url = URL(string: blankURL){
                            UIApplication.shared.openURL(url)
                        }
                    }else{
                        WebData.shared.setNewWindow(string: blankURL)
                        performSegue(withIdentifier: "showNewWindow", sender: self)
                    }
                    decisionHandler(WKNavigationActionPolicy.cancel)
                }
            }
        }else{
            print("#### 2 webView navigationAction.request.url = \(navigationAction.request.url!)")
            
            if let blankURL = navigationAction.request.url?.absoluteString{
                if (!blankURL.lowercased().hasPrefix("http://")) && (!blankURL.lowercased().hasPrefix("https://")){
                    
                    //                    let scheme1 = "itmss"
                    //                    let scheme2 = "itms-services"
                    if let scheme = navigationAction.request.url!.scheme{
                        if scheme != "http" && scheme != "https"{
                            //                            if UIApplication.shared.canOpenURL(navigationAction.request.url!){
                            print("open app")
                            UIApplication.shared.openURL(navigationAction.request.url!)
                            //                            }
                        }
                    }
                    
                    decisionHandler(WKNavigationActionPolicy.cancel)
                }else{
                    decisionHandler(WKNavigationActionPolicy.allow)
                }
            }
        }
    }
    //new end
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNewWindow"{
            if let dvc = segue.destination as? NewWindowViewController{
                dvc.processPool = self.processPool
            }
        }
    }
    
    @objc func back(){
        if self.wk.canGoBack {
            self.wk.goBack()
        }else{
            self.close()
        }
    }
    
    @objc func close(){
        let langDic = DeviceData.current.getDeviceLang()
        let alert = UIAlertController(title: nil, message: langDic["exitMessage"], preferredStyle: .alert)
        let okAction = UIAlertAction(title: langDic["confirm"], style: .default) { (action) in
            WebData.shared.refreshIsDisable = false
            WebData.shared.backIsDisable = false
            self.wk.removeObserver(self, forKeyPath: "estimatedProgress", context: nil)
            self.wk.stopLoading()
            self.wk.removeFromSuperview()
            self.wk = nil
            if self.newWK != nil{
                self.newWK.stopLoading()
                self.newWK.removeFromSuperview()
                self.newWK = nil
            }
            self.progressView.removeFromSuperview()
            self.progressView = nil
            self.navigationController?.popViewController(animated: true)
        }
        let cancelAction = UIAlertAction(title: langDic["cancel"], style: .default, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    @objc func refresh(){
        self.wk.reload()
    }
    
    @objc dynamic func closeGestureScreen() -> String{
        return "setInterval(chkScreen, 1e3); function chkScreen() {var apContainer = document.querySelector(\"#alphaContainer\"); var touchIntro = document.querySelector(\"#touchIntro\"); var fullscreen = document.querySelector(\"#fullscreen\"); if( apContainer ) {apContainer.style.display =\"none\";} if( touchIntro ) {touchIntro.style.display =\"none\";} if( fullscreen ) {fullscreen.style.display =\"none\";}}"
    }
    
    //WK delegate method
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("##### Finish !!!")
        self.progressView.setProgress(0.0, animated: false)
        
        //加入關閉遮罩監聽
        self.wk.evaluateJavaScript(closeGestureScreen(), completionHandler: { (any, error) in
            if error == nil{
                print("do js success")
            }
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
    
    @objc dynamic func isNeedChangeUserAgent(url: String) -> Bool{
        if !url.contains("jbb_xfball") && !url.contains("jbb/sport"){
            return true
        }else{
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
        
        conf.processPool = self.processPool
        
        //        self.wk = WKWebView(frame: self.view.bounds, configuration: conf)
        self.wk = WKWebView(frame: CGRect.zero, configuration: conf)
        wk.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self.wk)
        
        if #available(iOS 11, *){
            //            NSLayoutConstraint.activate([wk.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), wk.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)])
            NSLayoutConstraint.activate([wk.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)])
            
            NSLayoutConstraint(item: wk, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
            
            NSLayoutConstraint.activate([wk.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor), wk.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)])
        }else{
            NSLayoutConstraint(item: wk, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: statusBarHeight).isActive = true
            NSLayoutConstraint(item: wk, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
            NSLayoutConstraint(item: wk, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
            NSLayoutConstraint(item: wk, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        }
        
        if let url = self.web_url{
            if isNeedChangeUserAgent(url: url){
                self.wk.customUserAgent = WebData.shared.userAgent
            }
        }
        
        self.wk.navigationDelegate = self
        self.wk.uiDelegate = self
        
        self.view.backgroundColor = .black
        self.wk.backgroundColor = .black
        
        //        self.wk.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if let urlString = web_url{
            if let url = URL(string: urlString){
                let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 60)
                self.wk.load(request)
                //                self.view.addSubview(self.wk)
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
