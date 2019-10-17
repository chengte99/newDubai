//
//  ViewController.swift
//  newDubai
//
//  Created by KevinLin on 2019/6/28.
//  Copyright © 2019 KevinLin. All rights reserved.
//

import UIKit
import PPSPing
import DeviceKit
import CryptoSwift
import Crashlytics
import FirebasePerformance

class ViewController: UIViewController {
    
    @IBOutlet weak var myLabel: UILabel!
    var feedback: Int = 1
    var sessid = ""
    var logid: String = ""
    var domain_url: String = ""
    var appUpdate_url: String = ""
    var app: String = ""
    var web_url: String = ""
    var isDev: String = ""
    var check_link: String = ""
    var jsonConfigStr = ""
    
    let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    let buildVersion = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
    let systemVersion = UIDevice.current.systemVersion
    
    var timer = Timer()
    var retryTimes = 1
    
    var service: PPSPingServices!
    var pingCount = 0
    
    var isGotJSON = false
    var dBFailCount = 0
    var dbDomainCount = 0
    var dbDomainFinal = ""
    
    func repeatAction(){
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.printInfo), userInfo: nil, repeats: true)
    }
    
    @objc func printInfo(){
        let appMemUsed = DeviceData.current.showAppUsedMemory()
        print("appUsed: \(appMemUsed)")
        let memUsed = DeviceData.current.showMemory()
        print("memor: \(memUsed)")
        let cpu = DeviceData.current.showCPU()
        print("cpu: \(cpu)")
        //        let space_total = Float(UIDevice().totalDiskSpaceInBytes) / Float(1024 * 1024)
        //        let space_used = Float(UIDevice().usedDiskSpaceInBytes) / Float(1024 * 1024)
        let space_percent = Float(UIDevice().usedDiskSpaceInBytes) / Float(UIDevice().totalDiskSpaceInBytes) * 100.0
        //        print("space: \(Int(space_used)) / \(Int(space_total))")
        print("space: \(Int(space_percent))%")
        //        let virtual = DeviceData.current.showVirtualMemory()
        //        print("virtual: \(virtual)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //test only
        //        let newPW = "\(Date().timeStamp)*kevintest99"
        //        let enStr = AESHelp.shared.aes_en(str: newPW)
        //        print("enStr = \(enStr)")
        //        let deStr = AESHelp.shared.aes_de(str: enStr)
        //        print("deStr = \(deStr)")
        
        //        repeatAction()
        //        print("Carrier: \(DeviceData.current.showCarrierName()), RadioTech: \(DeviceData.current.showCarrierRadioTech())")
        //        print(NSLocale.preferredLanguages.first!)
        
        //        AppTouchID.shared.checkBiometrics()
        //        AppTouchID.shared.authenticateUser { (bool) in
        //            print(bool)
        //        }
        //test only end
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        view.backgroundColor = UIColor.black
        self.myLabel.numberOfLines = 0
        
        let device = Device.current
        //        DeviceData.current.deviceModel = device.description
        let isJBDevice = TTJBDetect().detechJB()
        if isJBDevice{
            DeviceData.current.deviceModel = "\(device.description) (JBDevice)"
        }else{
            DeviceData.current.deviceModel = device.description
        }
        
        DeviceData.current.uuid = AppKey().getUUID()
        if let udid = UIDevice.current.identifierForVendor?.uuidString{
            DeviceData.current.udid = udid
        }
        //        DeviceData.current.space = "\(UIDevice().usedDiskSpaceInMB)/\(UIDevice().totalDiskSpaceInMB)"
        let space_percent = Float(UIDevice().usedDiskSpaceInBytes) / Float(UIDevice().totalDiskSpaceInBytes) * 100.0
        DeviceData.current.space = "\(Int(space_percent))%"
        Crashlytics.sharedInstance().setUserIdentifier(DeviceData.current.uuid)
        
        setUserAgent()
        checkDefaultWebIsExist()
        APIManager.shared.setupManager()
        getDBURLsAndRequest()
    }
    
    func getLanguage(){
        if let language = NSLocale.preferredLanguages.first{
            print(language)
            let dic = NSLocale.components(fromLocaleIdentifier: language)
            if let language = dic["kCFLocaleLanguageCodeKey"]{
                print(language)
            }
            if let script = dic["kCFLocaleScriptCodeKey"]{
                print(script)
            }
            if let contry = dic["kCFLocaleCountryCodeKey"]{
                print(contry)
            }
        }
    }
    
    @objc func getDBURLsAndRequest(){
        self.showRetryText()
        self.showUUID()
        if let db_urls = UserDefaults.standard.string(forKey: "db_url"){
            //            print("## db_urls exist")
            if db_urls.contains(","){
                //multiple url
                let urlArray = db_urls.components(separatedBy: ",")
                self.dbDomainCount = urlArray.count
                for item in urlArray{
                    self.getAPI(urlString: item)
                }
            }else{
                //single url
                self.dbDomainCount = 1
                self.getAPI(urlString: db_urls)
            }
        }
    }
    
    func setUserAgent(){
        var userAgent = (UIWebView().stringByEvaluatingJavaScript(from: "navigator.userAgent") ?? "")
        //        print(userAgent)
        WebData.shared.defaultUserAgent = userAgent
        //        print(self.systemVersion)
        let versionSplit = self.systemVersion.components(separatedBy: ".")
        //        print("Major version : \(versionSplit[0])")
        
        var uaSplit = userAgent.components(separatedBy: "Gecko)")
        
        switch versionSplit[0] {
        case "13":
            userAgent = "\(uaSplit[0])Gecko) Version/13.0\(uaSplit[1]) Safari/604.1 AppiOS:\(self.buildVersion)"
        case "12":
            userAgent = "\(uaSplit[0])Gecko) Version/12.0\(uaSplit[1]) Safari/604.1 AppiOS:\(self.buildVersion)"
        case "11":
            userAgent = "\(uaSplit[0])Gecko) Version/11.0\(uaSplit[1]) Safari/604.1 AppiOS:\(self.buildVersion)"
        case "10":
            userAgent = "\(uaSplit[0])Gecko) Version/10.0\(uaSplit[1]) Safari/602.1 AppiOS:\(self.buildVersion)"
        case "9":
            userAgent = "\(uaSplit[0])Gecko) Version/9.0\(uaSplit[1]) Safari/601.1 AppiOS:\(self.buildVersion)"
        default:
            print("nothing change")
        }
        
        WebData.shared.userAgent = userAgent
    }
    
    func checkDefaultWebIsExist(){
        if let _ = UserDefaults.standard.string(forKey: "hcode_url"){
            print("## hcode_url exist")
        }else{
            print("## hcode_url empty")
            UserDefaults.standard.setValue(HardCodeURL, forKey: "hcode_url")
            UserDefaults.standard.synchronize()
        }
        
        if let _ = UserDefaults.standard.string(forKey: "db_url"){
            print("## db_url exist")
        }else{
            print("## db_url empty")
            if ISDEV == "1"{
                UserDefaults.standard.setValue(API_TestSite_URL, forKey: "db_url")
            }else{
                UserDefaults.standard.setValue(API_FormalSite_URL, forKey: "db_url")
            }
            UserDefaults.standard.synchronize()
        }
    }
    
    @objc func getAPI(urlString: String){
        print(" urlString = \(urlString)")
        
        APIManager.shared.jUpdateAPI(urlStringDB: urlString, uuid: DeviceData.current.uuid) { (json) in
            if let json = json{
                if !self.isGotJSON{
                    print(json)
                    self.jsonConfigStr = json.rawString()!
                    if let check_link = json["check_link"].string{
                        if check_link == "({\"foo\":\"bar\"})"{
                            self.isGotJSON = true
                            self.dbDomainFinal = urlString
                            LogData.shared.dBDomainFinal = urlString
                            self.check_link = check_link
                            
                            if let json_feedback = json["feedback"].int{
                                self.feedback = json_feedback
                            }
                            if let json_sessid = json["sess_id"].string{
                                self.sessid = json_sessid
                                LogData.shared.sessID = json_sessid
                            }
                            if let json_logid = json["log_id"].string{
                                self.logid = json_logid
                            }
                            if let json_isDev = json["isDev"].string{
                                self.isDev = json_isDev
                            }
                            if let json_domain_url = json["domain_url"].string{
                                self.domain_url = json_domain_url
                                UserDefaults.standard.setValue(json_domain_url, forKey: "db_url")
                                UserDefaults.standard.synchronize()
                                print("db_url replace")
                            }
                            if let json_appUpdate_url = json["appUpDate_url"].string{
                                self.appUpdate_url = json_appUpdate_url
                            }
                            if let json_app = json["app"].string{
                                self.app = json_app
                            }
                            if let json_web_url = json["web_url"].string{
                                self.web_url = json_web_url
                            }
                            
                            self.postSession()
                            self.checkUpdate()
                        }
                    }else{
                        print("json check_link is empty")
                    }
                }else{
                    print("some db already provide json")
                }
            }else{
                print("#### json == nil")
                print(" fail urlString = \(urlString)")
                
                self.dBFailCount += 1
                
                print(" DBFailCount = \(self.dBFailCount)")
                if self.dBFailCount == self.dbDomainCount{
                    // all db fail
                    self.dBFailCount = 0
                    
                    if self.retryTimes < 2{
                        //                        self.doRetry()
                        self.getDBURLsAndRequest()
                        self.retryTimes += 1
                    }
                    else{
                        print("#### goto HardcodeURL")
                        WebData.shared.isUseHardURL = true
                        
                        self.performSegue(withIdentifier: "goToWeb", sender: nil)
                    }
                }
            }
        }
    }
    
    func postSession(){
        //        print("cpu = \(DeviceData.current.showCPU())")
        //        print("dbDomainFinal = \(self.dbDomainFinal)")
        //        print("sessid = \(self.sessid)")
        var dbHost = ""
        if let url = URL(string: self.dbDomainFinal){
            if let host = url.host{
                dbHost = host
            }
        }
        
        APIManager.shared.postAppThreadAPI(domain: self.dbDomainFinal, deviceID: DeviceData.current.uuid, startTime: "", endTime: "", requestURL: dbHost, response: "", sessID: self.sessid, logID: self.logid, status: "2", userAgent: WebData.shared.userAgent, cpu: DeviceData.current.showCPU(), memUsed: DeviceData.current.showAppUsedMemory(), memory: DeviceData.current.showMemory(), space: DeviceData.current.space, radioTech: DeviceData.current.showCarrierRadioTech(), carrierName: DeviceData.current.showCarrierName(), deviceModel: DeviceData.current.deviceModel) { (json) in
            if let json = json{
                //                print(json)
                if let _ = json["success"].int{
                    print("##### Config server feedback success #####")
                }
            }
        }
    }
    
    func doRetry(){
        let date = Date()
        print("connectTimes = \(self.retryTimes)")
        print("Date = \(date)")
        timer = Timer.scheduledTimer(timeInterval: 8, target: self, selector: #selector(self.getDBURLsAndRequest), userInfo: nil, repeats: false)
    }
    
    func finishConnectText(){
        let langDic = DeviceData.current.getDeviceLang()
        let text = langDic["connectionSuccess"]!
        self.myLabel.text = "Version: \(self.buildVersion) \n\(text)"
        self.myLabel.adjustsFontSizeToFitWidth = true
    }
    
    func showRetryText(){
        let langDic = DeviceData.current.getDeviceLang()
        let text = langDic["serverConnection"]!
        self.myLabel.text = "Version: \(self.buildVersion) \n\(text)...\(self.retryTimes)"
        self.myLabel.adjustsFontSizeToFitWidth = true
    }
    
    func webCheckLinkText(){
        let langDic = DeviceData.current.getDeviceLang()
        let text = langDic["verifyWebsite"]!
        self.myLabel.text = "Version: \(self.buildVersion) \n\(text)"
        self.myLabel.adjustsFontSizeToFitWidth = true
    }
    
    fileprivate func showUUID() {
        let uuid = DeviceData.current.uuid
        //        print("uuid = \(uuid)")
        let index = uuid.index(uuid.endIndex, offsetBy: -6)
        let subStr = String(uuid[index...])
        //        print("subStr = \(subStr)")
        
        let uuidLabel = UILabel()
        uuidLabel.text = "****\(subStr)"
        uuidLabel.textColor = UIColor.white
        uuidLabel.adjustsFontSizeToFitWidth = true
        view.addSubview(uuidLabel)
        uuidLabel.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([uuidLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),uuidLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),uuidLabel.widthAnchor.constraint(equalToConstant: 80),uuidLabel.heightAnchor.constraint(equalToConstant: 30)])
        } else {
            NSLayoutConstraint(item: uuidLabel, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -10).isActive = true
            NSLayoutConstraint(item: uuidLabel, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -10).isActive = true
            NSLayoutConstraint(item: uuidLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 80).isActive = true
            NSLayoutConstraint(item: uuidLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 30).isActive = true
        }
    }
    
    fileprivate func goPresentSegue() {
        self.finishConnectText()
        if isDev == "1"{
            let langDic = DeviceData.current.getDeviceLang()
            let alert = UIAlertController(title: "", message: "isDev", preferredStyle: .alert)
            let okAction = UIAlertAction(title: langDic["confirm"], style: .default, handler: { (action) in
                //pass web_url to wkwebview
                self.performSegue(withIdentifier: "goToWeb", sender: nil)
            })
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }else{
            //pass web_url to wkwebview
            self.performSegue(withIdentifier: "goToWeb", sender: nil)
        }
    }
    
    func checkUpdate(){
        if feedback == -1{
            let langDic = DeviceData.current.getDeviceLang()
            var message = ""
            
            if appUpdate_url.lowercased().hasPrefix("http://") || appUpdate_url.lowercased().hasPrefix("https://"){
//                message = "版本更新"
                message = langDic["verUpdate"]!
            }
            else{
                message = appUpdate_url
                print("#### message = \(message), appUpdate_url = \(appUpdate_url)")
            }
            
            let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: langDic["confirm"], style: .default, handler: { (action) in
                if self.appUpdate_url.lowercased().hasPrefix("http://") || self.appUpdate_url.lowercased().hasPrefix("https://"){
                    if let url = URL(string: self.appUpdate_url){
                        UIApplication.shared.openURL(url)
                    }
                }
            })
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }else{
            //            sleep(1)
            //            //ping method
            //            if self.web_url != ""{
            //                if self.web_url.contains(","){
            //                    print(" multiple url")
            //                    self.urlList = self.web_url.components(separatedBy: ",")
            //                    self.checkURLsSpeedNew(indexN: 0)
            //                }else{
            //                    print(" single url")
            //                    WebData.shared.set(string: self.web_url)
            //                    UserDefaults.standard.setValue(self.web_url, forKey: "hcode_url")
            //                    UserDefaults.standard.synchronize()
            //                    print("hcode_url replace")
            //                    self.goPresentSegue()
            //                }
            //            }else{
            //                print(" json_web_url is empty")
            //                self.goPresentSegue()
            //            }
            //            //end
            
            //new check hack method
            if self.web_url != ""{
                self.createQueue(urlString: self.web_url)
            }else{
                print(" json_web_url is empty")
                self.goPresentSegue()
            }
            //end
        }
    }
    
    // kevin線路檢測
    var isSegueActionDone = false
    var failCount = 0
    var myURLString = "https://www.518maicai.com/mobile/app,https://www.188522.com/mobile/app,https://www.518111.info/mobile/app"
    
    func createQueue(urlString: String) {
        self.webCheckLinkText()
        if urlString != ""{
            
            LogData.shared.checklinkStartTime = Date().milliStamp
            APIManager.shared.postAppThreadAPI(domain: self.dbDomainFinal, deviceID: DeviceData.current.uuid, startTime: LogData.shared.checklinkStartTime, endTime: "", requestURL: "", response: "", sessID: self.sessid, logID: "", status: "1", userAgent: WebData.shared.userAgent, cpu: DeviceData.current.showCPU(), memUsed: DeviceData.current.showAppUsedMemory(), memory: DeviceData.current.showMemory(), space: DeviceData.current.space, radioTech: DeviceData.current.showCarrierRadioTech(), carrierName: DeviceData.current.showCarrierName(), deviceModel: DeviceData.current.deviceModel) { (json) in
                if let json = json{
                    //                    print(json)
                    if let _ = json["success"].int{
                        print("##### Checklink request success #####")
                        if let checklinkLogID = json["log_id"].string{
                            LogData.shared.checklinkLogID = checklinkLogID
                        }
                    }
                }
            }
            
            if urlString.contains(","){
                //multiple url
                let urlArray = urlString.components(separatedBy: ",")
                
                //test only
                //                if let lastURL = UserDefaults.standard.string(forKey: "lastURL"){
                //                    let queue = DispatchQueue(label: "queueForMultipleURL", qos: DispatchQoS.utility, attributes: DispatchQueue.Attributes.concurrent)
                //                    for item in urlArray{
                //                        queue.async {
                //                            //do get content
                //                            if item != lastURL{
                //                                self.checkWebContent(urlString: item, retimes: 2, urlArrayCount: urlArray.count)
                //                            }
                //                        }
                //                    }
                //                }else{
                //                    let queue = DispatchQueue(label: "queueForMultipleURL", qos: DispatchQoS.utility, attributes: DispatchQueue.Attributes.concurrent)
                //                    for item in urlArray{
                //                        queue.async {
                //                            //do get content
                //                            self.checkWebContent(urlString: item, retimes: 2, urlArrayCount: urlArray.count)
                //                        }
                //                    }
                //                }
                //test only end
                
                let queue = DispatchQueue(label: "queueForMultipleURL", qos: DispatchQoS.utility, attributes: DispatchQueue.Attributes.concurrent)
                for item in urlArray{
                    queue.async {
                        //do get content
                        self.checkWebContent(urlString: item, retimes: 2, urlArrayCount: urlArray.count)
                    }
                }
            }else{
                //single url
                let queue = DispatchQueue(label: "queueForSingleURL", qos: DispatchQoS.utility)
                queue.async {
                    //do get content
                    self.checkWebContent(urlString: urlString, retimes: 2, urlArrayCount: 1)
                }
            }
        }
    }
    
    func getHostAddress(urlString: String, completionHandler: @escaping (String) -> Void){
        if let url = URL(string: urlString){
            if let domain = url.host{
                let host = CFHostCreateWithName(nil,domain as CFString).takeRetainedValue()
                CFHostStartInfoResolution(host, .addresses, nil)
                var success: DarwinBoolean = false
                if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?,
                    let theAddress = addresses.firstObject as? NSData {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(theAddress.length),
                                   &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                        let numAddress = String(cString: hostname)
                        print("###########", urlString, numAddress)
                        completionHandler(numAddress)
                    }
                }
            }
        }
    }
    
    func checkWebContent(urlString: String, retimes: Int, urlArrayCount: Int){
        var newURLString = ""
        var content = ""
        var pingIPRes = ""
        
        //        print(" url = \(urlString), retimes = \(retimes)")
        
        getHostAddress(urlString: urlString) { (address) in
            pingIPRes = address
        }
        
        if let url = URL(string: urlString){
            if let host = url.host{
                //                print(" host = \(host)")
                
                var prefix = ""
                if urlString.lowercased().hasPrefix("https://"){
                    prefix = "https"
//                    newURLString = "https://\(host)/check_link/"
                }else{
                    prefix = "http"
//                    newURLString = "http://\(host)/check_link/"
                }
                
                if let portNum = url.port{
                    newURLString = "\(prefix)://\(host):\(portNum)/check_link/"
                }else{
                    newURLString = "\(prefix)://\(host)/check_link/"
                }
                
                //                print(" newURLString = \(newURLString)")
                if let newURL = URL(string: newURLString){
                    do{
                        let htmlString = try String(contentsOf: newURL, encoding: String.Encoding.utf8)
                        //                        print(" newURLString = \(newURLString), htmlString = \(htmlString)")
                        content = htmlString.replacingOccurrences(of: "\n", with: "")
                        LogData.shared.checklinkEndTime = Date().milliStamp
                    }catch{
                        print(error.localizedDescription)
                        LogData.shared.checklinkEndTime = Date().milliStamp
                    }
                }
                
                if content == self.check_link{
                    //                    print(" \(urlString) normal, time1 = \(startTime), time2 = \(endTime)")
                    if isSegueActionDone{
                        // some url is normal, go segue action is done.
                        print(" some url is normal, go segue action is done.")
                    }else{
                        isSegueActionDone = true
                        LogData.shared.checklinkURLFinal = "\(host): \(pingIPRes)"
                        LogData.shared.checklinkResponse = content
                        
                        //do segue
                        print(" go segue action, url = \(urlString)")
                        WebData.shared.set(string: urlString)
                        UserDefaults.standard.setValue(urlString, forKey: "hcode_url")
                        UserDefaults.standard.synchronize()
                        DispatchQueue.main.async {
                            self.goPresentSegue()
                        }
                    }
                }else{
                    print(" content is \(content)")
                    if retimes > 0{
                        checkWebContent(urlString: urlString, retimes: retimes - 1, urlArrayCount: urlArrayCount)
                    }else{
                        print(" \(urlString) has been hacked")
                        self.failCount += 1
                        if self.failCount == urlArrayCount{
                            print(" all url has been hacked")
                            //show alert
                            self.showConnectFailAlert()
                        }
                    }
                }
            }
        }
    }
    
    func showConnectFailAlert() {
        let langDic = DeviceData.current.getDeviceLang()
        let alert = UIAlertController(title: langDic["checklinkFailed"], message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: langDic["confirm"], style: .default) { (action) in
            exit(0)
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    //ping func
    var urlList = [String]()
    var speedList = [Double]()
    var myFinnalURL = ""
    func checkURLsSpeedNew(indexN: Int){
        let speedFail: Double = 30000.00
        
        if indexN == urlList.count{
            if speedList.count > 0{
                if let speedMin = speedList.min(){
                    if speedMin == speedFail{
                        print("all domain ping error, jump to hardcode url")
                        self.goPresentSegue()
                    }else{
                        print(" speedMin = \(speedMin)")
                        var speedCount = 0
                        for speed in self.speedList{
                            if speed == speedMin{
                                self.myFinnalURL = self.urlList[speedCount]
                            }
                            speedCount += 1
                        }
                        
                        if self.myFinnalURL != ""{
                            WebData.shared.set(string: self.myFinnalURL)
                            UserDefaults.standard.setValue(self.myFinnalURL, forKey: "hcode_url")
                            UserDefaults.standard.synchronize()
                            print("hcode_url replace")
                            self.goPresentSegue()
                        }else{
                            print("self.myFinnalURL is empty, will open last url in hcode_url")
                            self.goPresentSegue()
                        }
                    }
                }
            }
        }else{
            if let url = URL(string: urlList[indexN]){
                if let domain = url.host{
                    self.pingAction(urlStr: domain) { (double) in
                        print("first ping finish")
                        if let double = double{
                            self.speedList.append(double)
                        }else{
                            print("ping first domain error")
                            self.speedList.append(speedFail)
                        }
                        self.checkURLsSpeedNew(indexN: indexN + 1)
                    }
                }
            }
        }
    }
    
    func pingAction(urlStr: String, completionHandler: @escaping (Double?) -> Void) {
        var speedNum: Double?
        self.pingCount = 0
        self.service = PPSPingServices.service(withAddress: urlStr, maximumPingTimes: 2)
        self.service.start { (summary, pingItems) in
            self.pingCount += 1
            if let result = summary{
                var res = "\(result)"
                
                if res.contains("bytes"){
                    res = res.replacingOccurrences(of: " ", with: "")
                    res = res.replacingOccurrences(of: "ms", with: "")
                    let splitArray = res.components(separatedBy: "time=")
                    let speed = splitArray[1]
                    if let doubleNum = Double(speed){
                        speedNum = doubleNum
                    }
                }
                
                if self.pingCount == 2{
                    self.service = nil
                    //                    print("Stop ping")
                    if speedNum != nil{
                        completionHandler(speedNum)
                    }else{
                        completionHandler(nil)
                    }
                }
            }
        }
    }
    //ping func end
}

extension Date{
    var timeStamp: String{
        let timeInterval = self.timeIntervalSince1970
        let second = Int(timeInterval)
        return "\(second)"
    }
    
    var milliStamp: String{
        let timeInterval = self.timeIntervalSince1970
        let milliSecond = CLongLong(round(timeInterval*1000))
        return "\(milliSecond)"
    }
}

extension UIDevice{
    func MBFormatter(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = ByteCountFormatter.Units.useMB
        formatter.countStyle = ByteCountFormatter.CountStyle.decimal
        formatter.includesUnit = false
        return formatter.string(fromByteCount: bytes) as String
    }
    
    //MARK: Get String Value
    var totalDiskSpaceInGB:String {
        return ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var freeDiskSpaceInGB:String {
        return ByteCountFormatter.string(fromByteCount: freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var usedDiskSpaceInGB:String {
        return ByteCountFormatter.string(fromByteCount: usedDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.decimal)
    }
    
    var totalDiskSpaceInMB:String {
        return MBFormatter(totalDiskSpaceInBytes)
    }
    
    var freeDiskSpaceInMB:String {
        return MBFormatter(freeDiskSpaceInBytes)
    }
    
    var usedDiskSpaceInMB:String {
        return MBFormatter(usedDiskSpaceInBytes)
    }
    
    //MARK: Get raw value
    var totalDiskSpaceInBytes:Int64 {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
            let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value else { return 0 }
        return space
    }
    
    /*
     Total available capacity in bytes for "Important" resources, including space expected to be cleared by purging non-essential and cached resources. "Important" means something that the user or application clearly expects to be present on the local system, but is ultimately replaceable. This would include items that the user has explicitly requested via the UI, and resources that an application requires in order to provide functionality.
     Examples: A video that the user has explicitly requested to watch but has not yet finished watching or an audio file that the user has requested to download.
     This value should not be used in determining if there is room for an irreplaceable resource. In the case of irreplaceable resources, always attempt to save the resource regardless of available capacity and handle failure as gracefully as possible.
     */
    var freeDiskSpaceInBytes:Int64 {
        if #available(iOS 11.0, *) {
            if let space = try? URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
                return space ?? 0
            } else {
                return 0
            }
        } else {
            if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
                let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value {
                return freeSpace
            } else {
                return 0
            }
        }
    }
    
    var usedDiskSpaceInBytes:Int64 {
        return totalDiskSpaceInBytes - freeDiskSpaceInBytes
    }
}
