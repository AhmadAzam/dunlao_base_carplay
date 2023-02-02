//
//  OnStreetPOIDelegate.swift
//  dunlao
//
//  Created by PhilipHayes on 11/11/2022.
//

import Foundation
import CarPlay
internal class OnStreetPOIDelegate : CPPointOfInterestTemplateDelegate {
    var description: String
    
    func isEqual(_ object: Any?) -> Bool {
       return true
    }
    
    var hash: Int
    
    var superclass: AnyClass?
    
    func `self`() -> Self {
        return self
    }
    
    func perform(_ aSelector: Selector!) -> Unmanaged<AnyObject>! {
      return nil
    }
    
    func perform(_ aSelector: Selector!, with object: Any!) -> Unmanaged<AnyObject>! {
        return nil
    }
    
    func perform(_ aSelector: Selector!, with object1: Any!, with object2: Any!) -> Unmanaged<AnyObject>! {
        return nil
    }
    
    func isProxy() -> Bool {
        return true
    }
    
    func isKind(of aClass: AnyClass) -> Bool {
        return true
    }
    
    func isMember(of aClass: AnyClass) -> Bool {
        return true
    }
    
    func conforms(to aProtocol: Protocol) -> Bool {
        return true
    }
    
    func responds(to aSelector: Selector!) -> Bool {
        return true
    }
    
    
    
    var listSensors: Welcome?
    
    var CPH = CarPlayHelper()
    var SDW = SensorDataWindow()
    var SDATA = SensorData()
    
    func pointOfInterestTemplate(_ pointOfInterestTemplate: CPPointOfInterestTemplate, didChangeMapRegion region: MKCoordinateRegion) {
        do {
            //  Re-use existing view model
            AsyncLoadData()
            
            if(listSensors == nil || listSensors?.sensorList == nil || listSensors?.sensorList.count == 0)
            {
                listSensors = SDATA.GetSensorList()
            }
            //  Populate the on street points of interest
            var pointsOfInterestList =  PopulateOnStreetLocations(self.listSensors, region)
            //  Check for rows
            if pointsOfInterestList.count > 0 {
                pointOfInterestTemplate.setPointsOfInterest(pointsOfInterestList, selectedIndex: 0)
            }
        }
        catch {
            //  Show friend excpetion error on the ui
            print("Unexpected error: \(error).")
            var CPH = CarPlayHelper()
            CPH.ShowAlert(_interfaceController, error.localizedDescription)
        }
    }
    
    
    func AsyncLoadData(){
        let dispatchGroup = DispatchGroup()
        let db = SensorData()
         
        dispatchGroup.enter()
        
         
            db.fetchSensors(completion: {
                result in
                switch result {
                case .failure(let error):
                    //self.ShowDialog(title: "Sensor Data", msg: error.localizedDescription)
                    print (error.localizedDescription)
                    self.listSensors = db.GetSensorList()//hopefully we have a back up stored here
                     
                    print("HAD TO USE STORED CLASS DATA AS API NON RESPONSIVE=================================")
                case .success(let welcomecls):
                        self.listSensors = welcomecls
                        
                        db.SaveSensorList(cls: welcomecls)//STORE IT IN CASE API BECOMES NON RESPONSIVE
                        
                    
                }
                
                dispatchGroup.leave()
            })
            
            
       
        
        dispatchGroup.notify(queue: DispatchQueue.main){ [self] in
            
          /*  let count = self.tableView(self.tableView, numberOfRowsInSection: 0)
            if count > 0 {
                self.tableView.deleteRows(at: (0..<count).map({(i) in IndexPath(row: i, section: 0)}), with: .automatic)
                            }
          */
            
            var sortedSensors = self.listSensors
            self.listSensors?.sensorList = (sortedSensors?.sensorList.sorted(by: {(!$0.sensorStatus.isOccupied && $0.sensorStatus.isOnline) && ($1.sensorStatus.isOccupied || !$1.sensorStatus.isOnline)}))!
           
             
            
             
            print("Tasks complete")
            
            
        }
    }
     
     
    
    public var _interfaceController: CPInterfaceController!
    public var _uiScence: CPTemplateApplicationScene!

    // Pass in the scene and cp interface controller and store it for use inside this delegage
    public init(_ UIScene: CPTemplateApplicationScene!, _ interfaceController: CPInterfaceController!) {
        //  Assign values globally
        _uiScence = UIScene
        _interfaceController = interfaceController
        description = ""
        hash = 0 //no idea
        superclass = nil //no idea
    }

  

    public func PopulateOnStreetLocations(_ zonesResponse: Welcome!, _ region: MKCoordinateRegion!) -> [CPPointOfInterest] {
        //  The returned class
        var list = [CPPointOfInterest]()
        
        //  Check that the api call was successful
        if zonesResponse.status.success {
            
            
            //  Loop around each row
            //  order by closest distance to current region
            //  only need the top 12 closest
            //  exlude zones where lat and lng are empty
            for item in zonesResponse.sensorList {
                //  Perform mapkit actions on the ui thread - crash otherwise
                DispatchQueue.main.async (execute: {
                    //  Set the location for the poi
                    var loc = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: Double(item.sensorGPSPosition.latititude), longitude: Double(item.sensorGPSPosition.longitude))))
                    //  Used for google map directions when used
                    loc.name = item.sensorExtraInformation.title
                    var v = MKPointOfInterestCategory(rawValue: "Parking")
                   
                    loc.pointOfInterestCategory = v
                    //  Set the info for the poi
                    var poi = CPPointOfInterest(location: loc, title: item.sensorExtraInformation.title, subtitle: self.SDW.LabelStatusContent(s: item), summary: self.SDW.LabelTypeContent(s: item), detailTitle: item.sensorExtraInformation.title, detailSubtitle: self.SDW.LabelLastUpdatedContent(s: item), detailSummary: "", pinImage: nil)
                    // pin image
                    //  Each poi will have a primary button and an action handler
                   /* var primaryBtn: CPTextButton! = CPTextButton("Park 1 Hour", CPTextButtonStyle.Confirm, { (s) in
                        CPH.ProcessParkingPayment(_interfaceController, _uiScence, item.zone.zoneID, loc)
                    })*/
                    //  Each poi will have a secondary button and an action handler
                    var secondaryBtn: CPTextButton! = CPTextButton(title: "Get Directions", textStyle: CPTextButtonStyle.normal, handler: { (s) in
                        //  Show Directions in carplay map app
                        loc.openInMaps(launchOptions: nil, from: self._uiScence, completionHandler: { (s) in
                        })
                    })
                    //  Assign the primary button action
                   // poi.PrimaryButton = primaryBtn
                    //  Assign the secondary button
                    poi.secondaryButton = secondaryBtn
                    //  Add the poi to the master list
                    list.append(poi)
                })
            }
        } else {
            CPH.ShowAlert(_interfaceController, zonesResponse.status.response)
        }
        return list
    }
}
