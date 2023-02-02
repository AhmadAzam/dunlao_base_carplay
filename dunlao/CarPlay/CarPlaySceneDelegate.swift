//
//  CarPlaySceneDelegate.swift
//  dunlao
//  https://paulpeelen.com/SettingUpCarPlay
//  Created by PhilipHayes on 02/11/2022.
//

import CarPlay

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    public var _interfaceController: CPInterfaceController!
    public var _uiScence: CPTemplateApplicationScene!
    var listSensors: Welcome?
    
    var timer = Timer()
    
    var CPH = CarPlayHelper()
    var SDW = SensorDataWindow()
    var SDATA = SensorData()

    func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didConnect interfaceController: CPInterfaceController
    ) {
    // 2
    self._interfaceController = interfaceController
    
        //  Assign the ui scene for use later on
        _uiScence = templateApplicationScene
        //  Assign the interface controller for use later on
        _interfaceController = interfaceController
        updateToken()
        //  Create the root template
        var rootTemplate = CreateGridTemplate() ?? nil
        //  Set the root template to be the grid template
        interfaceController.setRootTemplate(rootTemplate!, animated: true)
       
        //seperate timer every 30 seconds
        self.timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { _ in
            self.updateToken()//update token and refresh the favs list statuses
        })
    }
    
    //MARK: - update api token
    func updateToken(){
        let date = Date()
        print("Grabbing token...")
        print(date)
        
        let db = SensorData()
        let grabAToken = db.GetDBToken()
        print(grabAToken)
        AsyncLoadData()//refresh list sure why not
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {
      
    }
  
    // #region Create Grid Menu
    public func CreateGridTemplate() -> CPGridTemplate! {
        //  OnStreet
        var titleOneList = [String]()
        titleOneList.append("Sensor List")
        var onStreetImage = UIImage(named: "list.bullet") ?? UIImage(systemName: "list.bullet")
        var btnOne = CPGridButton(titleVariants: titleOneList, image: onStreetImage!, handler: { (s) in
            self.ShowOnStreetTemplate()
        })
      
        //  Add the buttons to the list
        var buttonList = [CPGridButton]()
        buttonList.append(btnOne)
        var gridTemplate = CPGridTemplate(title: K.appTitle, gridButtons: buttonList)
        return gridTemplate
    }

    // #endregion
   

    private func ShowOnStreetTemplate() {
        //  Populate list of on street poi
        let poiList =  PopulateOnStreetPOI()
        //  Put the template together
        var onStreetPOITemplate = CPPointOfInterestTemplate(title: "Sensor List", pointsOfInterest: poiList, selectedIndex: 0)
        //  You need to assign the delegate whcih is responsible for map changes
        onStreetPOITemplate.pointOfInterestDelegate = OnStreetPOIDelegate(_uiScence, _interfaceController)
        //  Show the on street poi template
        _interfaceController.pushTemplate(onStreetPOITemplate, animated: false)
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

    // #region Polulate On Street
    public func PopulateOnStreetPOI() -> [CPPointOfInterest] {
        //  The returned class
        var masterList = [CPPointOfInterest]() 
        do {
            //  Call the viewmodel which calls the api to return a list all parkmagic zones
            var r = listSensors
            //  Check api call was successful
            if ((r?.status.success) != nil) {
                //  Loop around each item in the array
                //  Skip out zones where lat and lng are empty
                for item in r!.sensorList {
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
                        masterList.append(poi)
                    })
                }
            } else {
                CPH.ShowAlert(_interfaceController, r?.status.response)
            }
        }
        catch {
            //  Show friendly exception error alert on the ui
            
            CPH.ShowAlert(_interfaceController, error.localizedDescription)
        }
        return masterList
    }

    // #endregion
   
}

    
    
    
    
    /*private var interfaceController: CPInterfaceController?
     
     /// 1. CarPlay connected
     func templateApplicationScene(
     _ templateApplicationScene: CPTemplateApplicationScene,
     didConnect interfaceController: CPInterfaceController
     ) {
     // 2
     self.interfaceController = interfaceController
     
     // 3
     setInformationTemplate()
     }
     
     /// 4. Information template
     private func setInformationTemplate() {
     // 5 - Setting the content for the template
     if #available(iOS 14.0, *) {
     
     
     do {
     
     
     let items: [CPInformationItem] = [
     CPInformationItem(
     title: "Template type",
     detail: "Information Template (CPInformationTemplate)"
     )
     ]
     
     // 6 - Selecting the template
     let infoTemplate = CPInformationTemplate(title: "My first template",
     layout: .leading,
     items: items,
     actions: [])
     // 7 - Setting the information template as the root template
     interfaceController?.setRootTemplate(infoTemplate,
     animated: true,
     completion: { success, error in
     debugPrint("Success: \(success)")
     
     if let error = error {
     debugPrint("Error: \(error)")
     }
     })
     
     
     } catch let error {
     print(error.localizedDescription)
     }
     
     } else {
     // Fallback on earlier versions
     }
     
     
     }
     }
     */
