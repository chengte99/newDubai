//
//  AppTouchID.swift
//  newDubai
//
//  Created by KevinLin on 2019/6/28.
//  Copyright © 2019 KevinLin. All rights reserved.
//

import Foundation
import LocalAuthentication

class AppTouchID {
    //    static let shared = AppTouchID()

    let context = LAContext()
    //    context.localizedFallbackTitle = "Use Passcode"
    var err: NSError?
    //    let reasonString = "Biometrics Login"
    var reasonString = ""

    func authenticateUser(completionHandler: @escaping (Int) -> Void) {
        var customCode = 0
        context.localizedFallbackTitle = ""

        let langDic = DeviceData.current.getDeviceLang()
        reasonString = langDic["touchDescription"] as! String

        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &err) {
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString) { (success, error) in
                if success {
                    print("call touchID success")
                    completionHandler(customCode)
                } else {
                    if let error = error {
                        customCode = self.evaluateAuthenticationPolicyMessageForLA(errorCode: error._code)
                        //                        print(self.evaluateAuthenticationPolicyMessageForLA(errorCode: error._code))
                    }
                    completionHandler(customCode)
                }
            }
        } else {
            if let error = err {
                customCode = self.evaluateAuthenticationPolicyMessageForLA(errorCode: error.code)
                //                print(self.evaluateAuthenticationPolicyMessageForLA(errorCode: error.code))
            }
            completionHandler(customCode)
        }
    }

    func checkBiometrics() -> Int {
        var customCode = 0
        //假設有支援
        UserDefaults.standard.set(true, forKey: "isSupportTouchID")

        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &err) {
            print("have touchID&FaceID")
            //有設置
            //            UserDefaults.standard.set(true, forKey: "isSupportTouchID")
            UserDefaults.standard.set(true, forKey: "hasTouchID")
        } else {
            if let error = err {
                customCode = self.evaluateAuthenticationPolicyMessageForLA(errorCode: error.code)
                //                print(self.evaluateAuthenticationPolicyMessageForLA(errorCode: error.code))
            }
        }

        return customCode
    }

    func evaluateAuthenticationPolicyMessageForLA(errorCode: Int) -> Int {
        var message = ""
        var customCode = 0

        switch errorCode {
        case LAError.authenticationFailed.rawValue:
            //辨識錯誤
            message = "The user failed to provide valid credentials"
            customCode = 201
        case LAError.appCancel.rawValue:
            message = "Authentication was cancelled by application"
        case LAError.invalidContext.rawValue:
            message = "The context is invalid"
        case LAError.notInteractive.rawValue:
            message = "Not interactive"
        case LAError.passcodeNotSet.rawValue:
            //未設置解鎖密碼
            message = "Passcode is not set on the device"
            customCode = 202
        case LAError.systemCancel.rawValue:
            message = "Authentication was cancelled by the system"
        case LAError.userCancel.rawValue:
            //用戶取消
            message = "The user did cancel"
            customCode = 199
        case LAError.userFallback.rawValue:
            message = "The user chose to use the fallback"
        default:
            customCode = evaluatePolicyFailErrorMessageForLA(errorCode: errorCode)
        }

        print(message)

        return customCode
    }

    func evaluatePolicyFailErrorMessageForLA(errorCode: Int) -> Int {
        var message = ""
        var customCode = 0

        if #available(iOS 11.0, macOS 10.13, *) {
            switch errorCode {
            case LAError.biometryLockout.rawValue:
                //辨識次數過多，已鎖住
                message = "Authentication could not continue because the user has been locked out of biometric authentication, due to failing authentication too many times."
                customCode = 204
            case LAError.biometryNotEnrolled.rawValue:
                //未設置
                //                UserDefaults.standard.set(true, forKey: "isSupportTouchID")
                UserDefaults.standard.set(false, forKey: "hasTouchID")
                message = "Authentication could not start because the user has not enrolled in biometric authentication."
                customCode = 205
            case LAError.biometryNotAvailable.rawValue:
                //未支援
                UserDefaults.standard.set(false, forKey: "isSupportTouchID")
                UserDefaults.standard.set(false, forKey: "hasTouchID")
                message = "Authentication could not start because the device does not support biometric authentication."
                customCode = 206
            default:
                message = "Did not find error code on LAError object"
            }
        } else {
            switch errorCode {
            case LAError.touchIDLockout.rawValue:
                message = "Too many failed attempts."
                customCode = 204
            case LAError.touchIDNotEnrolled.rawValue:
                //未設置
                //                UserDefaults.standard.set(true, forKey: "isSupportTouchID")
                UserDefaults.standard.set(false, forKey: "hasTouchID")
                message = "TouchID is not enrolled on the device"
                customCode = 205
            case LAError.touchIDNotAvailable.rawValue:
                //未支援
                UserDefaults.standard.set(false, forKey: "isSupportTouchID")
                UserDefaults.standard.set(false, forKey: "hasTouchID")
                message = "TouchID is not available on the device"
                customCode = 206
            default:
                message = "Did not find error code on LAError object"
            }
        }
        //        UserDefaults.standard.synchronize()
        print(message)

        return customCode;
    }
}
