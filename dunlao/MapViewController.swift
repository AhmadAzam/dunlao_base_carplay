/*
 * Copyright 2020 Google Inc. All rights reserved.
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
 * file except in compliance with the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

import UIKit
import GoogleMaps 
 
class MapViewController: UIViewController , CLLocationManagerDelegate, GMSMapViewDelegate{
    
   // @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet weak var addressLabel: UILabel!
    var mapView: GMSMapView!
    var curMarker = GMSMarker()
let locationManager = CLLocationManager()
    var sensorResponse : Welcome?
    var sensorFavourites : Favourites?
    var selectedSensor: SensorList?
    
  //  @IBOutlet weak var AboutButton: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Live Map"
       
        
       // mapView.delegate = self
        let camera = GMSCameraPosition.camera(withLatitude: 53.294412, longitude: -6.133895, zoom: 15.0)
       // self.mapView.camera = camera
        mapView = GMSMapView.map(withFrame: self.view.frame, camera: camera)
        // USE SAFE AREA, IF NEEDED
        if #available(iOS 11.0, *){
            if let window = UIApplication.shared.keyWindow{
                let topMargin = window.safeAreaInsets.top + 50
                let leftMargin = window.safeAreaInsets.left
                let rightMargin =  window.safeAreaInsets.right
                let bottomMargin = window.safeAreaInsets.bottom
                
                mapView = GMSMapView.map(withFrame: CGRect(x: leftMargin, y: topMargin, width: self.view.frame.width - (leftMargin + rightMargin), height: self.view.frame.height - (topMargin + bottomMargin)), camera: camera)
            }
        }
        
        
        /*
        mapView = GMSMapView.map(withFrame: self.view.frame(forAlignmentRect: CGRect(x: 0, y: 80, width: self.view.frame.width, height: self.view.frame.height - 80)), camera: camera)
        */
        
        self.view.addSubview(mapView)
        sensorResponse = nil
        sensorFavourites = Favourites()
        
        let sensorData = SensorData()
        
        sensorData.fetchSensors{
            result in
            switch result {
            case .failure(let error):
                self.ShowDialog(title: "Sensor Data", msg: error.localizedDescription)
            case .success(let welcomecls):
                self.mapPins(self.mapView, cls: welcomecls)
                self.sensorResponse = welcomecls//set it here so we can use it to find selected sensor class item
            }
        }
            // custom click: http://kevinxh.github.io/swift/custom-and-interactive-googlemaps-ios-sdk-infowindow.html
            
            // https://www.raywenderlich.com/7363101-google-maps-ios-sdk-tutorial-getting-started
        
        locationManager.delegate = self
        mapView.settings.zoomGestures  = true
        mapView.settings.scrollGestures = true
        mapView.settings.compassButton = true
        mapView.settings.indoorPicker = true

        if CLLocationManager.locationServicesEnabled(){
            locationManager.requestLocation()
            
            mapView.isMyLocationEnabled = true
            mapView.settings.myLocationButton = true
           
        }else {
            locationManager.requestWhenInUseAuthorization()
        }
        
        
       
        
        mapView.delegate = self //for pin click events
        }
        
    
    func ShowDialog(title : String, msg : String){
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
            action in
            switch action.style {
            case .default:
                print ("default")
            case .cancel:
                print ("cancel")
            case .destructive:
                print ("destructive")
            default:
                print("default")
            }
        }))
        
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func isSpaceAvailabile(online : String, occupied : String) -> Bool{
        if(online.lowercased().contains("online") && occupied.lowercased().contains("available"))
        {
            return true
        }
        return false
    }
    
    func isSensorOnline(online : String) -> Bool {
        if(online.lowercased().contains("online") ){
            return true
        }
        return false
    }
    
    func showMapPinDetails(marker: GMSMarker)
    {
        curMarker = marker
        let userData = marker.userData as! [String:String]
        
        let window = UIApplication.shared.windows.last!
        var viewToShow = UIView(frame: CGRect(x: 0, y: window.frame.size.height - 205, width: window.frame.size.width, height: 205))
         
        if(sensorResponse != nil){
            for sensor in sensorResponse!.sensorList{
                if(String(sensor.sensorID) == userData["sensorID"])
                {
                    let sensorDataWindow = SensorDataWindow()
                    viewToShow = sensorDataWindow.showMapPinDetails(s: sensor)
                    selectedSensor = sensor
                                          
                      let btnNav = sensorDataWindow.CreateNavButton()
                      btnNav.addTarget(self, action: #selector(self.navigation_btn_pressed), for: .touchUpInside)
                      viewToShow.addSubview(btnNav)
                      
                      
                      let btnClose =  sensorDataWindow.CreateCloseButton()
                      btnClose.addTarget(self, action: #selector(self.close_btn_pressed), for: .touchUpInside)
                      viewToShow.addSubview(btnClose)
                      
                      
                      let btnFav = sensorDataWindow.CreateFavButton(isFav: sensorFavourites!.IsInFavList(sensor: sensor))        //TODO CHECK IF IS ON FAV LIST
                      btnFav.addTarget(self, action: #selector(self.fav_btn_pressed), for: .touchUpInside)
                      viewToShow.addSubview(btnFav)
                    
                    
                    break
                }
            }
        }
      
        
       // label.tag = 0xDEADBEEF002
         self.view.addSubview(viewToShow)
     
    }
    
    
    @objc func close_btn_pressed(sender : UIButton)
    {
        print ("nb: close window button")
        removeMapPinLabelView()
        
    }
    
    @objc func fav_btn_pressed(sender : UIButton)
    {
        var isInList = sensorFavourites!.IsInFavList(sensor: selectedSensor!)
        
        if(isInList){
            var removed =  sensorFavourites!.RemoveSensorFromFavs(sensor: selectedSensor!)
            if(removed)
            {
                sender.setImage(UIImage(systemName: "star"), for: .normal)               
                
            }
            
        }
        else{
            var added =  sensorFavourites!.AddSensorToList(sensor: selectedSensor!)
            if(added)
            {
                sender.setImage(UIImage(systemName: "star.fill"), for: .normal)
 
            }
        }
        
    }
    
    
    @objc func navigation_btn_pressed(sender : UIButton)
    {
        print ("nb: pressed nav button")
       // print(curMarker.title)
        print(curMarker.position.latitude)
        print(curMarker.position.longitude)
        
        // lat
      let latDouble = Double(curMarker.position.latitude)
        
                let longDouble = Double(curMarker.position.longitude)
       
        if(UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)){
            if let url = URL(string: "comgooglemaps-x-callback://?saddr=&daddr=\(latDouble),\(longDouble)&directionsmode=driving"){
                UIApplication.shared.open(url,options: [:])
                    
            }
        }else
        {
            //open in browser
            if let urlDestination = URL.init(string:"https://www.google.com/maps/dir/?saddr=&daddr=\(latDouble),\(longDouble)&directionsmode=driving"){
                UIApplication.shared.open(urlDestination)
            }
        }
      //  print("nb:" + self.mapView.selectedMarker!.title)
        
    }
        
 
        func mapPins(_ mapView: GMSMapView, cls: Welcome)
        {
            
            for item in cls.sensorList{
                // item.sensorGPSPosition.latititude
                let location = CLLocationCoordinate2D(latitude: item.sensorGPSPosition.latititude, longitude: item.sensorGPSPosition.longitude)
                print("location: \(location)")
                let marker = GMSMarker()
                marker.title = item.sensorExtraInformation.title
                
                var myData = Dictionary<String,String>()
                myData["title"] = item.sensorExtraInformation.title
                myData["type"] = item.sensorType.sensorType.rawValue
                myData["desc"] = "" //item.sensorExtraInformation./.title
                myData["date"] = item.sensorStatus.lastChangedState//.replacingCharacters(in: "T", with: " ")
                myData["sensorID"] = String(item.sensorID)
                if(item.sensorStatus.isOnline){
                    myData["online"] = "Sensor Online"
                    if(item.sensorStatus.isOccupied){
                        myData["occupied"] = "Space is Occupied"
                    }
                    else
                    {
                        myData["occupied"] = "Space is Available"
                    }                }
                else
                {
                    myData["online"] = "Sensor Offline"
                    myData["occupied"] = "Availability is Unknown"
                }
                 
                
                marker.userData = myData
                marker.icon = GMSMarker.markerImage(with: UIColor(named: K.blue))
                marker.position = location
                let jsonData = try! JSONEncoder().encode(item)
                let jsonString = String(data: jsonData, encoding:  .utf8)!
                
                //default
                marker.icon = GMSMarker.markerImage(with: UIColor(named: K.warmGrey))
                  marker.snippet = "This location is offline, status unknown"
                
              
                if !item.sensorStatus.isOccupied && item.sensorStatus.isOnline
                    {
                        
                       // mapView.selectedMarker = marker
                    marker.icon = GMSMarker.markerImage(with: UIColor(named: K.green))
                        marker.snippet = "This location is available" //[Tap for more info...]""
                    }
               
                if(item.sensorStatus.isOnline && item.sensorStatus.isOccupied){
                    marker.icon = GMSMarker.markerImage(with: UIColor(named: K.red))
                    
                    print("------------------------")
                    print("-----------red-------------")
                    print("------------------------")
                    
                    marker.snippet = "This location is occupied"// [Tap for more info...]""                        }
                    
                }
                 
                    
                    
               
                 //item.sensorExtraInformation.title.description
                marker.accessibilityLabel =  jsonString
                marker.map = mapView
                
            }
            
            
        }
    
    
   

    // 8
    func locationManager(
      _ manager: CLLocationManager,
      didFailWithError error: Error
    ) {
      print(error)
    }
    
    func removeMapPinLabelView()
    {
        for _ in 1...5{ //loop check as there may be more than one running at the time overlayed
            if let foundView = view.viewWithTag(0xDEADBEEF){
                foundView.removeFromSuperview()
                print("removed view")
            }else
            {
                print ("looped to remove but not found")
            }
        }
        
    }
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        
         print("map move!")
         removeMapPinLabelView()
        
    }

    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        removeMapPinLabelView()
        print ("show pin marker")
        showMapPinDetails(marker: marker)
    }
    
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        print ("marker tapped")
        
        /*if let selectedMarker = mapView.selectedMarker {
            selectedMarker.icon = GMSMarker.markerImage(with: nil)
        }*/
        
        mapView.selectedMarker = marker
       // marker.icon = GMSMarker.markerImage(with: UIColor.orange)
        removeMapPinLabelView()
      //  print ("show pin marker")
         showMapPinDetails(marker: marker)

        return true
    }
    func locationManager(
      _ manager: CLLocationManager,
      didChangeAuthorization status: CLAuthorizationStatus
      ) {
      // 3
      guard status == .authorizedWhenInUse else {
        return
      }
      // 4
      locationManager.requestLocation()

      //5
      mapView.isMyLocationEnabled = true
      mapView.settings.myLocationButton = true
    }

    // 6
    func locationManager(
      _ manager: CLLocationManager,
      didUpdateLocations locations: [CLLocation]) {
      guard let location = locations.first else {
        return
      }

      // 7
          mapView.camera = GMSCameraPosition(
        target: location.coordinate,
        zoom: 15,
        bearing: 0,
        viewingAngle: 0)
    }
    func reverseGeocode(coordinate: CLLocationCoordinate2D) {
      // 1
      let geocoder = GMSGeocoder()

      // 2
      geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
        guard
          let address = response?.firstResult(),
          let lines = address.lines
          else {
            return
        }

        // 3
        self.addressLabel.text = lines.joined(separator: "\n")

        // 4
        UIView.animate(withDuration: 0.25) {
          self.view.layoutIfNeeded()
        }
      }
    }
    
    @IBAction func AboutClicked(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "MainView", sender: self)
    }
     
    
    }

