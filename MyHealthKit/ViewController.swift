//
//  ViewController.swift
//  MyHealthKit
//
//  Created by apple on 2017/12/13.
//  Copyright © 2017年 lgw. All rights reserved.
//http://m.blog.csdn.net/w350981132/article/details/77358911
//http://blog.csdn.net/ls_xyq/article/details/50724522

import UIKit
import HealthKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        
        
        
    }

    
    
    @IBAction func click(_ sender: Any) {
        //判断当前设备是否支持 HeathKit
        if HKHealthStore.isHealthDataAvailable(){
            
            let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)
            let height = HKObjectType.quantityType(forIdentifier: .height)
            let weight = HKObjectType.quantityType(forIdentifier: .bodyMass)
            let temperature = HKObjectType.quantityType(forIdentifier: .bodyTemperature)
            let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
            
            
            let birthday = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)
            let sex = HKObjectType.characteristicType(forIdentifier: .biologicalSex)
            let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)
            
            let writeData:Set<HKObjectType> = [stepCountType!,height!,weight!,temperature!,activeEnergy!,birthday!,sex!,distance!]
            
            let readData:Set<HKObjectType> = [stepCountType!,height!,weight!,temperature!,activeEnergy!,birthday!,sex!,distance!]
            
            let healthStore = HKHealthStore.init()
  
        
            
            //请求连接 认证请求从HeathKit获取数据的权限。
            healthStore.requestAuthorization(toShare: writeData as? Set<HKSampleType>, read: readData, completion: {(s,e)in
                if s {
                    print("sucess")
                    
                    let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)
                    let time = NSSortDescriptor.init(key: HKSampleSortIdentifierEndDate, ascending: false)
                    //类型，时间区间,排序类型（HKSampleSortIdentifierEndDate 结束日期排序）
                    let query = HKSampleQuery.init(sampleType: stepType!, predicate: self.predicateForSamplesToday(), limit: HKObjectQueryNoLimit, sortDescriptors: [time], resultsHandler: {(q,s1,e) in
                        
                        if(e != nil){
                            print("查询失败：\(e.debugDescription)")
                        }else{
                            print("查询成功:\(String(describing: s1?.count))")
                            
                            
                            var deviceN = 0.0
                            var appN = 0.0
                            
                            for ob in s1!{
                                
                                let ver = ob.sourceRevision.source.name
                                let v = ob as! HKQuantitySample
                               let unit = HKUnit.count()
                                
                                let qt = v.quantity
                                
                               let d = qt.doubleValue(for: unit)
                               
                                let sd = ob.startDate
                                let ed = ob.endDate
                                print("sd==\(self.getLoaclDate(d: sd))==ed==\(self.getLoaclDate(d: ed))=====步数：\(d)")
                               
                                //UIDevice.current.name  设备账号名称
                                if ver == UIDevice.current.name{
                                   deviceN += d
                                }else{
                                    appN += d
                                }
                
                            }
                            
                           
                            print("实际步数：\(deviceN)====app改写:\(appN)")
                            
                        }
                        
                    })
                     healthStore.execute(query)
                    
                   
                    
                }
            })
            
           
        }
        
      getDistance()
        
    }
    
    
    /*
     *  @brief  当天时间段
     *
     *  @return 时间段
     */
    func predicateForSamplesToday() -> NSPredicate{
        let calendar = Calendar.current
        let now = NSDate()
        let componsssss :Set<Calendar.Component> = [Calendar.Component.day,Calendar.Component.month,Calendar.Component.year]
        var components = calendar.dateComponents(componsssss, from: now as Date)
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        let startDate = calendar.date(from: components)
        let endDate = calendar.date(byAdding: Calendar.Component.day, value: 1, to: startDate!)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .init(rawValue: 0))
        return predicate
        
    }
    
    
    
    
    
    @IBAction func wrireBtn(_ sender: Any) {
        
        
        addStep(stepNum: 1212)
        
        
        
    }
    
    func addStep(stepNum: Double){
        
        let stepCorrelationItem :HKQuantitySample = self.stepCorrelation(stepNum: stepNum)
        let healthStore = HKHealthStore.init()
        healthStore.save(stepCorrelationItem, withCompletion: { (success, error) in
            if success {
                //写入成功处理
                print("写入数据成功")
            }else {
                //写入失败处理
                print("写入数据失败")
            }
        })
        
        
    }
    //获取数据模型
    func stepCorrelation(stepNum: Double) -> HKQuantitySample{
        let endDate: NSDate = NSDate()
        let startDate : NSDate = NSDate.init(timeInterval: -300, since: endDate as Date)
        let stepQuantityConsumed = HKQuantity.init(unit: HKUnit.count(), doubleValue: stepNum)
        let stepConsumedType = HKQuantityType.quantityType(forIdentifier: .stepCount)
        let strName = UIDevice.current.name
        let strModel = UIDevice.current.model
        let strSysVersion = UIDevice.current.systemVersion
        let localeIdentifier = Locale.current.identifier
        let device = HKDevice.init(name: strName, manufacturer: "Apple", model: strModel, hardwareVersion: strSysVersion, firmwareVersion: strModel, softwareVersion: strSysVersion, localIdentifier: localeIdentifier, udiDeviceIdentifier: localeIdentifier)
        let stepConsumedSample = HKQuantitySample.init(type: stepConsumedType!, quantity: stepQuantityConsumed, start: startDate as Date, end: endDate as Date, device: device, metadata: nil)
        return stepConsumedSample
    }
    
    
    //获取卡路里
    fileprivate func getKilocalorieUnit(){
        
        let type = HKQuantityType.quantityType(forIdentifier: .stepCount)
        let option = HKStatisticsOptions.discreteMax
        
        let healStore = HKHealthStore.init()
        
        let query = HKStatisticsQuery.init(quantityType: type!, quantitySamplePredicate: self.predicateForSamplesToday(), options: [option], completionHandler: {(q,s,e)in
            let sum = s?.sumQuantity()
            let value = sum?.doubleValue(for: HKUnit.kilocalorie())
            
            print("获取到的卡路里==\(String(describing: value))")
            
            
        })
        
        healStore.execute(query)
        
    }
    
    
    //获取公里数
    fileprivate func getDistance(){
       let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)
        let timeSort = NSSortDescriptor.init(key: HKSampleSortIdentifierEndDate, ascending: false)
        let health = HKHealthStore.init()
        
        let query = HKSampleQuery.init(sampleType: distanceType!, predicate: self.predicateForSamplesToday(), limit: HKObjectQueryNoLimit, sortDescriptors: [timeSort], resultsHandler: {(q,r,e)in
            if e != nil{
                
            }else{
                
                for quantity in r!{
                    let qs = quantity as! HKQuantitySample
                    
                    let q = qs.quantity
                    let unit = HKUnit.meterUnit(with: .kilo)
                    let uh = q.doubleValue(for: unit)
                    
                    print("当天行走距离:\(uh)")
                }
                
            }
           
        })
         health.execute(query)
    }
    
    
    
    ///获取本地时间
    
    fileprivate func getLoaclDate(d:Date)->Date{
        let sourceTime = TimeZone.init(abbreviation: "UTC")
        let localTime  = TimeZone.current
        let s = sourceTime?.secondsFromGMT(for: d)
        let l = localTime.secondsFromGMT(for: d)
        let interval = l - s!
        
        let destinationDateNow = Date.init(timeInterval: TimeInterval(interval), since: d)
        return destinationDateNow
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

