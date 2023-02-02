//
//  SensorDataWindow.swift
//  dunlao
//
//  Created by PhilipHayes on 03/10/2022.
//

import Foundation
import UIKit
import CoreLocation

struct SensorDataWindow{
    
  
    
    //MARK: - Distance calc
    func GetDistanceFromLocationInMeters(destLat: Double, destLong: Double) -> Double{
        
        let myLoc = GetStoredLocation()
        let coordinate₀ = CLLocation(latitude: myLoc.lat, longitude: myLoc.long)
        let coordinate₁ = CLLocation(latitude: destLat, longitude: destLong)
        let distanceInMeters = coordinate₀.distance(from: coordinate₁)
        // result is in meters
        return distanceInMeters
    }

    //MARK: - Get string text distance
    func StringDistanceText(destLat: Double, destLong: Double) -> String{
        // we may not yet have permission on their location so it'll say 5k kms away from sydney if not, in that case return empty string
        let doubDistanceKM = GetDistanceFromLocationInMeters(destLat: destLat, destLong: destLong) / 1000
       
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
                case .notDetermined, .restricted, .denied:
                    return ""// print("No access")
                case .authorizedAlways, .authorizedWhenInUse:
                    return  String(format: "%.2f",doubDistanceKM ) + "km" // print("Access")
                @unknown default:
                    return  String(format: "%.2f",doubDistanceKM ) + "km"
            }
        } else {
            return ""
        }
     
    }
    
    //MARK: - Nav btn design
    func CreateNavButton() -> UIButton{
        let btnNav = UIButton()
        btnNav.setTitle(" Directions", for: .normal)
        btnNav.titleLabel?.font = UIFont(name: (K.fontName), size: 18)!
        btnNav.setImage(UIImage(systemName: "location"), for: .normal)
        btnNav.setTitleColor(UIColor(named: K.blue), for: .normal)
        btnNav.frame = CGRect(x: 15, y: 115, width: 300, height: 120)
         
        btnNav.titleLabel?.font = UIFont(name: (btnNav.titleLabel?.font.fontName)!, size: 22)!
        return btnNav
    }
    
    //MARK: - close window button design
    func CreateCloseButton()->UIButton{
        let btnClose = UIButton()
        btnClose.setTitle("", for: .normal)
        btnClose.setImage(UIImage(systemName: "pip.remove"), for: .normal)
        btnClose.setTitleColor(UIColor(named: K.blue), for: .normal)
        let window = UIApplication.shared.windows.last!
        btnClose.frame = CGRect(x: window.frame.size.width - 80, y: 7, width: 120, height: 20)
        
        //btnClose.addTarget(self, action: #selector(self.close_btn_pressed), for: .touchUpInside)
        
        btnClose.titleLabel?.font = UIFont(name: (K.fontName), size: 22)!
        //viewToShow.addSubview(btnClose)
        
        return btnClose
    }
    
    //MARK: - Fav btn design
    func CreateFavButton(isFav: Bool) -> UIButton{
        let btnFav = UIButton()
        
        btnFav.setTitle(" Favourite", for: .normal)
     
        
        btnFav.titleLabel?.font = UIFont(name: (K.fontName), size: 18)!
        if(isFav)
        {
            btnFav.setImage(UIImage(systemName: "star.fill"), for: .normal)
        }
        else
        {
            btnFav.setImage(UIImage(systemName: "star"), for: .normal)
        }
       // btnFav.tintColor = UIColor.systemYellow
        btnFav.tintColor = UIColor(named: K.gold)
      
        // btnFav.setTitleColor(.systemYellow, for: .normal)
        btnFav.setTitleColor(UIColor(named: K.gold), for: .normal)
        btnFav.frame = CGRect(x: 210, y: 95, width: 180, height: 30)
        btnFav.imageView?.contentMode = .scaleAspectFit
        
        //btnFav.addTarget(self, action: #selector(self.fav_btn_pressed), for: .touchUpInside)
        //viewToShow.addSubview(btnFav)
        return btnFav
    }
    
    //MARK: - Get space type label content
    func LabelTypeContent(s: SensorList) -> String
    {
        var r = ""
        
        
        var sDistance = StringDistanceText(destLat: s.sensorGPSPosition.latititude, destLong: s.sensorGPSPosition.longitude)
        var awayText = " away"
        if(sDistance == ""){
            awayText = ""
        }
        
        r = s.sensorType.sensorType + " Space " + sDistance + awayText
        
        return r
    }
    
    //MARK: - Get status label content
    func LabelStatusContent(s: SensorList) -> String
    {
        var r = ""
        
        
        var onlineString = "Online"
        var availableString = " & Available"
        if s.sensorStatus.isOccupied {
            availableString = " & Occupied"
        }
        if !s.sensorStatus.isOnline{
            onlineString = "Offline"
            availableString = ""
        }
        r = onlineString + "" + availableString
        
        return r
    }
    
    
    
    //MARK: - Get last updated label content
    func LabelLastUpdatedContent(s: SensorList) -> String
    {
        var r = ""
        
        var timeDescPrefix = "Last updated"
        if(!s.sensorStatus.isOnline){
            timeDescPrefix = "Offline since"
        }
        else {
          
            
            if(s.sensorStatus.isOccupied){
                timeDescPrefix = "In use since"
            }else{
                timeDescPrefix = "Available since"
            }
        }
        
        
        r = "\(timeDescPrefix): " + s.sensorStatus.lastChangedState.replacingOccurrences(of: "T", with: " ")
        
         
        
        return r
    }
    
  
   
    //MARK: - Popup window layout and design (remeber to handle dark mode)
    func showMapPinDetails(s: SensorList) -> UIView
    {
        
        //removeMapPinLabelView()//clear any view if already showing used in favs for reopening view
        let window = UIApplication.shared.windows.last!
        let viewToShow = UIView(frame: CGRect(x: 0, y: window.frame.size.height - 205, width: window.frame.size.width, height: 205))
       // viewToShow.backgroundColor = UIColor.white
        viewToShow.tag = 0xDEADBEEF
        viewToShow.backgroundColor = UIColor.systemBackground //this allows the text to change for dark mode and the background to change also.
        viewToShow.alpha = 0.95
        
        let labelIndicationColour = UILabel(frame: CGRect(x: 0, y: 0, width: window.frame.size.width, height: 5))
        labelIndicationColour.text = " "
        labelIndicationColour.alpha = 0.60
        let labelTitle = UILabel(frame: CGRect(x: 10, y: 10, width: window.frame.size.width - 5, height:50))
        
        //labelTitle.text = GMSMarker.markerImage(with: UIColor.blue)
        labelTitle.text =  s.sensorExtraInformation.title//)
        //labelTitle.textAlignment = .center
        labelTitle.font = UIFont(name: K.fontName, size: 28)
       // let imageAttachment = NSTextAttachment()
        let parkingLargeConfig = UIImage.SymbolConfiguration(pointSize: UIFont.systemFontSize + 10, weight: .bold, scale: .large)
        let boldLargeConfig = UIImage.SymbolConfiguration(pointSize: UIFont.systemFontSize + 5, weight: .bold, scale: .large)
        //let config2 = UIImage.SymbolConfiguration(paletteColors: <#T##[UIColor]#>)
        if !s.sensorStatus.isOccupied
        {
            labelIndicationColour.backgroundColor = UIColor(named: K.green)
        }
        else
        {
            labelIndicationColour.backgroundColor = UIColor(named: K.red)// UIColor.red
        }
        // if offline completely make it gray
        if(!s.sensorStatus.isOnline){
            labelIndicationColour.backgroundColor = UIColor(named: K.blue)
        }
      
        let textAfterIcon = NSAttributedString(string: "  " + s.sensorExtraInformation.title)
       // completeText.append(NSAttributedString(string: "  ")
      //  completeText.append(textAfterIcon)
        labelTitle.attributedText = textAfterIcon //OLDER PHONES CAN NOT DISPLAY THESE ICONS, SO I AM REMOVING THEM// completeText
        labelTitle.textColor = UIColor(named: K.blue)

       let labelDesc = UILabel(frame: CGRect(x: 20, y: 52, width: window.frame.size.width, height: 20))
        
        labelDesc.text = ""
            labelDesc.textColor = UIColor(named: K.blue)
        

       let labelType = UILabel(frame: CGRect(x: 20, y: 74, width: window.frame.size.width, height: 21))
        
         
        labelType.text = LabelTypeContent(s: s)
        labelType.textColor = UIColor(named: K.blue)

        labelType.font = UIFont(name: K.fontName, size: 16)
        
        
        let labelStatus = UILabel(frame: CGRect(x: 20, y: 102, width: window.frame.size.width, height: 21))
        
  
        labelStatus.text = LabelStatusContent(s: s)
        
        labelStatus.textColor = UIColor(named: K.blue)
        labelStatus.font = UIFont(name: K.fontName, size: 16)
        
 
        
       let labelUpdated = UILabel(frame: CGRect(x: -20, y: 130, width: window.frame.size.width, height: 18))
       
        
        labelUpdated.text = LabelLastUpdatedContent(s: s)
        labelUpdated.font = UIFont(name: K.fontName, size: 14)
        labelUpdated.textAlignment = .center
        labelUpdated.textColor = UIColor(named: K.blue)
        
        
      //  let imageView = UIImageView(image: imgTick)
    
        
        
       //     label.backgroundColor = UIColor.blue
        viewToShow.addSubview(labelIndicationColour)
        viewToShow.addSubview(labelTitle)
        viewToShow.addSubview(labelDesc)
        viewToShow.addSubview(labelType)
        viewToShow.addSubview(labelStatus)
        viewToShow.addSubview(labelUpdated)       // viewToShow.addSubview(imgTick)
    
       return viewToShow
     
    }
    
    //MARK: - Get STORED location
    func GetStoredLocation() -> MyLatLong {
        
            let defaults = UserDefaults.standard
            var long = defaults.double(forKey: "myLocationLong")
            var lat = defaults.double(forKey: "myLocationLat")
         
        if(long == nil){
            long = 0.0
            lat = 0.0
        }
        
        
        
        var r = MyLatLong()
        r.lat = lat
        r.long = long
        
        return r
    }
    
    
    
}

struct MyLatLong{
    var lat : Double = 0.0
    var long: Double = 0.0
    
 }
