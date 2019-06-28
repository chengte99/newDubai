//
//  AESHelp.swift
//  newDubai
//
//  Created by KevinLin on 2019/6/28.
//  Copyright © 2019 KevinLin. All rights reserved.
//

import Foundation
import CryptoSwift

class AESHelp {
    static let shared = AESHelp()
    
    func aes_en(str: String) -> String{
        var enStr = ""
        do{
            let aes = try AES(key: AES_KEY, iv: AES_IV, padding: .zeroPadding)
            
            let encrypted = try aes.encrypt(str.bytes)
            //            enStr = encrypted.toBase64()!
            enStr = encrypted.toHexString()
        }catch{
            print(error.localizedDescription)
        }
        
        return enStr
    }
    
    func aes_de(str: String) -> String{
        var deStr = ""
        //        let encrypted = Array<UInt8>(base64: str)
        let encrypted = Array<UInt8>(hex: str)
        
        do{
            let aes = try AES(key: AES_KEY, iv: AES_IV, padding: .zeroPadding)
            
            let decrypted = try aes.decrypt(encrypted)
            if let deTmp = String(data: Data(bytes: decrypted), encoding: String.Encoding.utf8){
                deStr = deTmp
            }
            //            deStr = String(data: Data(bytes: decrypted), encoding: String.Encoding.utf8)!
        }catch{
            print(error.localizedDescription)
        }
        
        return deStr
    }
}
