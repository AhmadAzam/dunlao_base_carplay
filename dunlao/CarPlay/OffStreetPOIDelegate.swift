import CarPlay
internal class OffStreetPOIDelegate : CPPointOfInterestTemplateDelegate {
    
    
    var description: String
    
    public var _interfaceController: CPInterfaceController!
    public var _uiScence: CPTemplateApplicationScene!

    
    func pointOfInterestTemplate(_ pointOfInterestTemplate: CPPointOfInterestTemplate, didChangeMapRegion region: MKCoordinateRegion) {
        <#code#>
    }
    
    func isEqual(_ object: Any?) -> Bool {
        <#code#>
    }
    
    var hash: Int
    
    var superclass: AnyClass?
    
    func `self`() -> Self {
        <#code#>
    }
    
    func perform(_ aSelector: Selector!) -> Unmanaged<AnyObject>! {
        <#code#>
    }
    
    func perform(_ aSelector: Selector!, with object: Any!) -> Unmanaged<AnyObject>! {
        <#code#>
    }
    
    func perform(_ aSelector: Selector!, with object1: Any!, with object2: Any!) -> Unmanaged<AnyObject>! {
        <#code#>
    }
    
    func isProxy() -> Bool {
        <#code#>
    }
    
    func isKind(of aClass: AnyClass) -> Bool {
        <#code#>
    }
    
    func isMember(of aClass: AnyClass) -> Bool {
        <#code#>
    }
    
    func conforms(to aProtocol: Protocol) -> Bool {
        <#code#>
    }
    
    func responds(to aSelector: Selector!) -> Bool {
        <#code#>
    }
    
    public init(_ UIScene: CPTemplateApplicationScene!, _ interfaceController: CPInterfaceController!) {
        //  Assign values globally
        _uiScence = UIScene
        _interfaceController = interfaceController
    }

    open override func DidChangeMapRegion(_ pointOfInterestTemplate: CPPointOfInterestTemplate!, _ region: MKCoordinateRegion!) {
        var list = List<CPPointOfInterest!>()
        __try {
            //  Re-use existing view model
            var vm = CarPlayOffStreetParkingViewModel()
            //  Call the viewmodel which calls the api to return a list of off street parking locations
            var r = __await vm.GetOffStreetParkingLocations()
            //  Check that the api call was successful
            if r.status.success {
                //  check off street locations were found
                if r.locationData.Count > 0 {
                    //  Loop around each carpark and calculate the distance
                    for item in r.locationData {
                        //  The distance in km based upon the carpark position to the current map region position
                        var distanceInKms = CarPlayHelper.CalculateDistanceToRegion(item.gpsPosition.latitude, item.gpsPosition.longitude, region.Center.Latitude, region.Center.Longitude)
                        //  Assign the distance to the class property
                        item.distanceInKms = distanceInKms
                    }
                    //  Loop around each carpark
                    //  order by closest distance to current region
                    for item in r.locationData.OrderBy({ (x) in
                        x.distanceInKms
                    }).ToList() {
                        //  Perform mapkit actions on the ui thread - crash otherwise
                        InvokeOnMainThread({
                            //  Set the location for the poi
                            var loc = MKMapItem(MKPlacemark(CLLocationCoordinate2D(item.gpsPosition.latitude, item.gpsPosition.longitude)))
                            //  Used for google map directions when used
                            loc.Name = item.OffStreetName
                            loc.PointOfInterestCategory = "Parking"
                            //  Set the info for the poi
                            var poi = CPPointOfInterest(loc, item.OffStreetName, CarPlayHelper.OnlineOfflineHelper(item.isOnline), item.distanceInKms + "km", item.OffStreetName, item.locationType.OffStreetType + " - " + item.distanceInKms + "km", "TollTag Auto Entry", nil)
                            //  pin image
                            var secondaryBtn: CPTextButton! = CPTextButton("Get Directions", CPTextButtonStyle.Normal, { (s) in
                                //  Show Directions in carplay map app
                                loc.OpenInMaps(nil, _uiScence, { (s) in
                                })
                            })
                            //  Assign the secondary button
                            poi.SecondaryButton = secondaryBtn
                            //  Add the poi to the master list
                            list.Add(poi)
                        })
                    }
                }
            } else {
                __await CarPlayHelper.ShowAlert(_interfaceController, r.status.response)
            }
        }
        __catch ex: Exception {
            __await CarPlayHelper.ShowAlert(_interfaceController, ex.Message)
        }
        if list.Count > 0 {
            pointOfInterestTemplate.SetPointsOfInterest(list.ToArray(), 0)
        }
    }
}
