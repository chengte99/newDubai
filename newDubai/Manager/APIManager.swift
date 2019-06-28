//
//  APIManager.swift
//  newDubai
//
//  Created by KevinLin on 2019/6/28.
//  Copyright © 2019 KevinLin. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class APIManager{
    
    static let shared = APIManager()
    
    var alamofireManager: SessionManager?
    
    func setupManager(){
        let conf = URLSessionConfiguration.default
        conf.timeoutIntervalForResource = 8
        conf.timeoutIntervalForRequest = 8
        alamofireManager = Alamofire.SessionManager(configuration: conf)
    }
    
    func jUpdateAPI(urlStringDB: String, uuid: String, completionHandler: @escaping (JSON?) -> Void){
        let buildVersion = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        
        let urlString = "\(urlStringDB)/mob_controller/judgeUpdate.php"
        
        let params: [String: Any] = [
            "app_version": buildVersion,
            "OS": "1",
            "App": KEY_CODE,
            "IsDev": ISDEV,
            "device_id": uuid
        ]
        
        if let url = URL(string: urlString){
            //            Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding(), headers: nil).responseJSON { (response) in
            //                switch response.result{
            //                case .success(let value):
            //                    let jsonData = JSON(value)
            //                    completionHandler(jsonData)
            //                    break
            //                case .failure:
            //                    completionHandler(nil)
            //                    break
            //                }
            //            }
            
            alamofireManager?.request(url, method: .post, parameters: params, encoding: URLEncoding(), headers: nil).responseJSON { (response) in
                switch response.result{
                case .success(let value):
                    let jsonData = JSON(value)
                    completionHandler(jsonData)
                    break
                case .failure:
                    completionHandler(nil)
                    break
                }
            }
        }
        
        //        if let url = URL(string: urlString){
        //            alamofireManager?.request(url, method: .post, parameters: params, encoding: URLEncoding(), headers: nil).response(completionHandler: { (response) in
        //
        //                print(response)
        //            })
        //        }
    }
    
    func getConnectionIP(urlString: String, CompletionHandler: @escaping (String?) -> Void){
        if let url = URL(string: urlString){
            Alamofire.request(url, method: .get, parameters: nil, encoding: URLEncoding(), headers: nil).responseString(completionHandler: { (response) in
                //                print(response)
                switch response.result{
                case .success(let value):
                    CompletionHandler(value)
                    break
                case .failure:
                    CompletionHandler(nil)
                    break
                }
            })
        }
    }
    
    func postAppThreadAPI(domain: String, deviceID: String, startTime: String, endTime: String, requestURL: String, response: String, sessID: String, logID: String, status: String, userAgent: String, cpu: String, memUsed: String, memory: String, space: String, radioTech: String, carrierName: String, deviceModel: String, completionHandler: @escaping (JSON?) -> Void){
        let urlString = "\(domain)/app_log/apl_insertweilog.php"
        
        let content: [String: Any] = [
            "datas": [
                "appapp": KEY_CODE,
                "device_id": deviceID,
                "phone_start_time": startTime,
                "phone_end_time": endTime,
                "request_url": requestURL,
                "response": response,
                "sess_id": sessID,
                "log_id": logID,
                "status": status,
                "user_agent": userAgent
            ],
            "useful": [
                "cpu_used": cpu,
                "mem_used": memUsed,
                "mem_free": memory,
                "useful_space": space,
                "access": radioTech,
                "nt_operator_name": carrierName,
                "device_name": deviceModel
            ]
        ]
        
        let params: [String: Any] = [
            "crlMode": "app_log",
            "content": JSON(content)
        ]
        
        if let url = URL(string: urlString){
            Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding(), headers: nil).responseJSON { (res) in
                switch res.result{
                case .success(let value):
                    let jsonData = JSON(value)
                    //                    print(jsonData)
                    completionHandler(jsonData)
                    break
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(nil)
                    break
                }
            }
        }
    }
    
    func postAccountAsync(domain: String, sessID: String, account: String, completionHandler: @escaping (JSON?) -> Void){
        let urlString = "\(domain)/app_log/apl_insertweilog.php"
        
        let content = [
            "sess_id": sessID,
            "web_acc": account
        ]
        
        let params: [String: Any] = [
            "crlMode": "update_account",
            "content": JSON(content)
        ]
        
        if let url = URL(string: urlString){
            Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding(), headers: nil).responseJSON { (response) in
                switch response.result{
                case .success(let value):
                    let jsonData = JSON(value)
                    //                    print(jsonData)
                    completionHandler(jsonData)
                    break
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(nil)
                    break
                }
            }
        }
    }
    
    func fastLoginAPI(host: String, account: String, password: String, type: String, completionHandler: @escaping (JSON?) -> Void){
        let urlString = "\(host)app/getMemLoginToken"
        
        let params: [String: Any] = [
            "acc": account,
            "pwd": password,
            "type": type
        ]
        
        if let url = URL(string: urlString){
            Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding(), headers: nil).responseJSON { (res) in
                switch res.result{
                case .success(let value):
                    let jsonData = JSON(value)
                    //                    print(jsonData)
                    completionHandler(jsonData)
                    break
                case .failure(let error):
                    print(error.localizedDescription)
                    completionHandler(nil)
                    break
                }
            }
        }
    }
}
