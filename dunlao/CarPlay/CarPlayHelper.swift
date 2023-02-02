//
//  CarPlayHelper.swift
//  dunlao
//
//  Created by PhilipHayes on 11/11/2022.
//

import Foundation
import CarPlay
open class CarPlayHelper {
    // CPInterfaceController _interfaceController;
    // public CarPlayAlertHelper(CPInterfaceController interfaceController)
    //   {
    //      _interfaceController = interfaceController;
    //   }
    public func ShowAlert(_ _interfaceController: CPInterfaceController!, _ alertTxt1: String!, _ alertTxt2: String! = "")  {
        //  Create the list of alert text strings
        var info = [String]()
        info.append(alertTxt1)
        info.append(alertTxt2)
        //  Create the list of alert actions
        //  The only one we want to use is the cancel
        var alertActions = [CPAlertAction]()
        alertActions.append(CPAlertAction(title: "Close", style: CPAlertAction.Style.destructive, handler: { (t) in
            //  Close the alert
            _interfaceController.dismissTemplate(animated: false)
        }))
        //  Put together the alert
        
        var alertTemplate: CPAlertTemplate! = CPAlertTemplate(titleVariants: info, actions: alertActions)
        //  Actually show the alert on the ui
        _interfaceController.presentTemplate(alertTemplate, animated: false)
    }

    public func CalculateDistanceToRegion(_ lat1: Float64, _ lng1: Float64, _ lat2: Float64, _ lng2: Float64) -> Float64 {
        var loc1 = CLLocation(latitude: lat1, longitude: lng1)
        var loc2 = CLLocation(latitude: lat2, longitude: lng2)
        var distance: Float64 =  loc1.distance(from: loc2)
        return distance
        //var SDW = SensorDataWindow()
        //return SDW.GetDistanceFromLocationInMeters(destLat: <#T##Double#>, destLong: <#T##Double#>)
         
    }

    /*public func ProcessParkingPayment(_ _interfaceController: CPInterfaceController!, _ _uiScence: CPTemplateApplicationScene!, _ selectedZoneID: Int32, _ loc: MKMapItem!) -> Task! {
        //  Init the view model
        var vm = CarPlayParkVehicleViewModel()
        //  Call the vm which calls the api to park vehicle
        var r = __await vm.ParkStoredCredit(selectedZoneID)
        //  Check for api success
        if r.status.success {
            //  Log - just to see analytics
            Analytics.TrackEvent("Parked Via CarPlay", Dictionary<String!,String!>(nil.("UserAuthenticaionToken", Settings.UserAuthenticationToken), nil.("ZoneName", r.parked.zoneName)))
            //  Two Column information
            var infoitems = List<CPInformationItem!>()
            infoitems.Add(CPInformationItem("Zone", r.parked.zoneName))
            infoitems.Add(CPInformationItem("VRN", r.parked.userReference))
            infoitems.Add(CPInformationItem("Expiry Time", r.parked.expiryTime))
            //  List of action buttons
            var actionButtonList = List<CPTextButton!>()
            //  Home button
            var btnHome: CPTextButton! = CPTextButton("Close", CPTextButtonStyle.Cancel, { (s) in
                _interfaceController.PopToRootTemplate(true)
            })
            //  Directions button
            var btnDirections: CPTextButton! = CPTextButton("Get Directions", CPTextButtonStyle.Normal, { (s) in
                //  Show Directions in carplay map app
                loc.OpenInMaps(nil, _uiScence, { (s) in
                })
            })
            //  Add the buttons to the list
            actionButtonList.Add(btnHome)
            actionButtonList.Add(btnDirections)
            //  Create the info template
            var infoTemplate = CPInformationTemplate("Successfully Parked", CPInformationTemplateLayout.TwoColumn, infoitems.ToArray(), actionButtonList.ToArray())
            //  Show the info template
            _interfaceController.PushTemplate(infoTemplate, true)
        } else {
            __await ShowAlert(_interfaceController, r.status.response)
        }
    }*/

    // Helper
    public func OnlineOfflineHelper(_ isOnline: Bool) -> String! {
        if isOnline {
            return "Online"
        } else {
            return "Offline"
        }
    }
}
