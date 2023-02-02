//
//  Favourites.swift
//  dunlao
//
//  Created by PhilipHayes on 03/10/2022.
//

import Foundation
struct Favourites{
    
    
    let defaultFavName = "jsonFavs"
    
    func GetSensorFavList() -> [SensorList] {
        let defaults = UserDefaults.standard
        let jsonListFavs = defaults.string(forKey: defaultFavName)
//print (jsonListFavs)
        if !(jsonListFavs ?? "").isEmpty
        {
            
         //   print("we have favs")
            let jsonDecoder = JSONDecoder()
            //lEt params = ["username":"john", "password":"123456"] as Dictionary<String, String>
            let jsonData = jsonListFavs!.data(using: .utf8)!
            var favList = try! JSONDecoder().decode([SensorList].self, from: jsonData)
            return favList
            
        }
        else
        {
            let jsonEncoder = JSONEncoder()
            var emptyList: [SensorList]
            emptyList = []
            SaveFavList(list: emptyList)
            print("saved empty favs")
            return emptyList
        }
    }
    
    func SaveFavList(list : [SensorList]){
        let jsonEncoder = JSONEncoder()
      //  sensorList.append(sensor)
        let jsonData = try! jsonEncoder.encode(list)
        let json = String(data: jsonData, encoding: .utf8)
        UserDefaults.standard.set(json ?? "", forKey: defaultFavName)
    }
    
    func IsInFavList(sensor: SensorList) -> Bool{
 
            for favSensor in GetSensorFavList(){
                if(sensor.sensorID == favSensor.sensorID)
                {
                   // print("-------Sensor is in LIST OF FAVS")
                    return true
                    
                }
            }
            return false
    }
    
    func RemoveSensorFromFavs(sensor: SensorList) -> Bool{
       
        var newFavList : [SensorList]
        newFavList = []
        for favSensor in GetSensorFavList(){
            if(sensor.sensorID != favSensor.sensorID)
            {
                newFavList.append(favSensor)
            }
            else
            {
                print("found and excluded from new list")
            }
        }
        
        SaveFavList(list: newFavList)
        
        return true
        
        
    }
    
    func AddSensorToList(sensor: SensorList) -> Bool{
     
        var newFavList  = GetSensorFavList()
        if(!IsInFavList(sensor: sensor)){
            newFavList.append(sensor)
            SaveFavList(list: newFavList)
            print("added to favs list")
        }
        else
        {
            print("all ready in the list")
        }
        
        return true
        
        
    }
    
}
