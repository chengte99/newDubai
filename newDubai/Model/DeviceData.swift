//
//  DeviceData.swift
//  newDubai
//
//  Created by KevinLin on 2019/6/28.
//  Copyright © 2019 KevinLin. All rights reserved.
//

import Foundation
import CoreTelephony

class DeviceData {
    var space = ""
    var uuid = ""
    var deviceModel = ""
    
    static let current = DeviceData()
    
    internal typealias MemoryUsageTuple = (usedMemory: UInt64, totalMemory: UInt64)
    
    func showCarrierRadioTech() -> String{
        var reachableVia = ""
        
        if let reachability = Reachability(hostName: "www.weibo.com"){
            if reachability.currentReachabilityStatus().rawValue == 0{
                reachableVia = "No Network"
            }else{
                switch reachability.currentReachabilityStatus() {
                case ReachableViaWWAN:
                    reachableVia = getNetworkType()
                case ReachableViaWiFi:
                    reachableVia = "WiFi"
                default:
                    break
                }
            }
        }
        
        return reachableVia
    }
    
    func showCarrierName() -> String{
        let networkInfo = CTTelephonyNetworkInfo()
        if let _ = networkInfo.subscriberCellularProvider?.isoCountryCode{
            //            print("countryCode = \(countryCode)")
            return networkInfo.subscriberCellularProvider?.carrierName ?? ""
        }else{
            return "No SIM Card"
        }
    }
    
    func showCPU() -> String{
        let cpu = self.cpuUsage()
        //        return String(format: "%.1f%%", cpu)
        return "\(Int(cpu))%"
    }
    
    func showAppUsedMemory() -> String{
        let memory = self.memoryUseage()
        let used = Float(memory.usedMemory) / Float(1024 * 1024)
        //        return String(format: "memory used : %.1f, allused: %.1f, total : %.0f", used, allUsed, total)
        let allUsedMemory = self.allUsedMemory()
        let allUsed = Float(allUsedMemory[1]) / Float(1024 * 1024)
        
        let percent = used / allUsed * 100.0
        
        return "\(Int(percent))%"
    }
    
    func showMemory() -> String{
        //        let memory = self.memoryUseage()
        let allUsedMemory = self.allUsedMemory()
        //        let used = Float(memory.usedMemory) / Float(1024 * 1024)
        //        let total = Float(memory.totalMemory) / Float(1024 * 1024)
        //        let allUsed = Float(allUsedMemory) / Float(1024 * 1024)
        
        let allUsed = Float(allUsedMemory[0]) / Float(1024 * 1024)
        let all = Float(allUsedMemory[1]) / Float(1024 * 1024)
        
        let percent = allUsed / all * 100.0
        
        //        return String(format: "memory used : %.1f, allused: %.1f, total : %.0f", used, allUsed, total)
        return "\(Int(percent))%"
    }
    
    func showVirtualMemory() -> String{
        let allUsedMemory = self.allUsedMemory()
        let allUsed = Float(allUsedMemory[0]) / Float(1024 * 1024)
        return String(format: "memory : %.1f", allUsed)
    }
    
    private func getNetworkType() -> String{
        var networkType = ""
        
        let networkInfo = CTTelephonyNetworkInfo()
        if let radioType = networkInfo.currentRadioAccessTechnology{
            switch radioType {
            case CTRadioAccessTechnologyGPRS:
                networkType = "2G"
            case CTRadioAccessTechnologyEdge:
                networkType = "2G"
            case CTRadioAccessTechnologyCDMA1x:
                networkType = "2G"
            case CTRadioAccessTechnologyCDMAEVDORev0:
                networkType = "3G"
            case CTRadioAccessTechnologyCDMAEVDORevA:
                networkType = "3G"
            case CTRadioAccessTechnologyCDMAEVDORevB:
                networkType = "3G"
            case CTRadioAccessTechnologyWCDMA:
                networkType = "3G"
            case CTRadioAccessTechnologyHSDPA:
                networkType = "3G"
            case CTRadioAccessTechnologyHSUPA:
                networkType = "3G"
            case CTRadioAccessTechnologyeHRPD:
                networkType = "3G"
            case CTRadioAccessTechnologyLTE:
                networkType = "4G"
            default:
                break
            }
        }
        
        return networkType
    }
    
    private func cpuUsage() -> Float {
        let basicInfoCount = MemoryLayout<mach_task_basic_info_data_t>.size / MemoryLayout<natural_t>.size
        
        var kern: kern_return_t
        
        var threadList = UnsafeMutablePointer<thread_act_t>.allocate(capacity: 1)
        var threadCount = mach_msg_type_number_t(basicInfoCount)
        
        var threadInfo = thread_basic_info.init()
        var threadInfoCount: mach_msg_type_number_t
        
        var threadBasicInfo: thread_basic_info
        var threadStatistic: UInt32 = 0
        
        kern = withUnsafeMutablePointer(to: &threadList) {
            #if swift(>=3.1)
            return $0.withMemoryRebound(to: thread_act_array_t?.self, capacity: 1) {
                task_threads(mach_task_self_, $0, &threadCount)
            }
            #else
            return $0.withMemoryRebound(to: (thread_act_array_t?.self)!, capacity: 1) {
                task_threads(mach_task_self_, $0, &threadCount)
            }
            #endif
        }
        if kern != KERN_SUCCESS {
            return -1
        }
        
        if threadCount > 0 {
            threadStatistic += threadCount
        }
        
        var totalUsageOfCPU: Float = 0.0
        
        for i in 0..<threadCount {
            threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
            
            kern = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    thread_info(threadList[Int(i)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                }
            }
            if kern != KERN_SUCCESS {
                return -1
            }
            
            threadBasicInfo = threadInfo as thread_basic_info
            
            if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                totalUsageOfCPU = totalUsageOfCPU + Float(threadBasicInfo.cpu_usage) / Float(TH_USAGE_SCALE) * 100.0
            }
        }
        
        return totalUsageOfCPU
    }
    
    private func memoryUseage() -> MemoryUsageTuple {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        var used: UInt64 = 0
        if result == KERN_SUCCESS {
            used = UInt64(taskInfo.resident_size)
        }
        
        let total = ProcessInfo.processInfo.physicalMemory
        return (used, total)
    }
    
    func allUsedMemory() -> [UInt64] {
        var ret = [UInt64]()
        var usedMemory: UInt64 = 0
        var allMemory: UInt64 = 0
        let hostPort: mach_port_t = mach_host_self()
        var host_size: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        var pagesize:vm_size_t = 0
        host_page_size(hostPort, &pagesize)
        var vmStat: vm_statistics = vm_statistics_data_t()
        
        let status = withUnsafeMutablePointer(to: &vmStat) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
                host_statistics(mach_host_self(), Int32(HOST_VM_INFO), $0, &host_size)
            }
        }
        // Now take a look at what we got and compare it against KERN_SUCCESS
        if status == KERN_SUCCESS {
            //            usedMemory = (UInt64)((vm_size_t)(vmStat.active_count + vmStat.wire_count + vmStat.free_count + vmStat.inactive_count) * pagesize)
            usedMemory = (UInt64)((vm_size_t)(vmStat.active_count + vmStat.wire_count) * pagesize)
            allMemory = (UInt64)((vm_size_t)(vmStat.active_count + vmStat.wire_count + vmStat.free_count + vmStat.inactive_count) * pagesize)
            //            usedMemory = (UInt64)((vm_size_t)(vmStat.free_count + vmStat.inactive_count) * pagesize)
            
            ret.append(usedMemory)
            ret.append(allMemory)
        }
        else {
            print("Failed to get Virtual memory inforor")
        }
        
        return ret
    }
    
    func getDeviceLang() -> [String: String]{
        let lang = NSLocale.preferredLanguages.first!
        var langDic = [String: String]()
        if lang.contains("zh"){
            langDic = [
                "confirm": "确认",
                "cancel": "取消",
                "touchDescription": "请按压您的指纹",
                "exitMessage": "确定要离开吗？"
            ]
        }else{
            langDic = [
                "confirm": "Confirm",
                "cancel": "Cancel",
                "touchDescription": "Touch sensor",
                "exitMessage": "Are you sure to leave?"
            ]
        }
        
        return langDic
    }
}
