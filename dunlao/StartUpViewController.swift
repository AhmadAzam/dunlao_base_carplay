
import UIKit
import GoogleMaps
class StartUpViewController: UIViewController , CLLocationManagerDelegate, GMSMapViewDelegate,   UISearchResultsUpdating{
 
    
    
    let reusableCellName = "ReusableCell"
    let sensorCellName = "SensorCell"
    let defaultFavName = "jsonFavs"
    var refreshimer:Timer? = nil
    
    var timer = Timer()
    
    var indicator = UIActivityIndicatorView()
    var pullControl = UIRefreshControl()

    @IBOutlet weak var lblNoFavMessage: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
   var filterByValueInTextBox : String?
   
   var listSensors: Welcome?
   var listSensorsBackUp: Welcome?
   var selectedSensor: SensorList?
   var sensorFavourites : Favourites?
   var selectedSensorIndex: IndexPath?
   var searchController: UISearchController!
    var countOfFavs : Int = 0
   
    let locationManager = CLLocationManager()
    var showTableSearch = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Menu"
        
        //testing debug settings
        #if DEBUG
        UserDefaults.standard.set(false, forKey: "shownAbout")
       UserDefaults.standard.set("" , forKey: K.defaultTokenGUID)//zero token
        #endif
        
        
        locationManager.delegate = self

        if CLLocationManager.locationServicesEnabled(){
            locationManager.requestLocation()
        }else {
            locationManager.requestWhenInUseAuthorization()
        }
        LoadTableViewSettings()
        ShowTableHideLabel(_showTable: true)
        
     
        //seperate timer every 30 seconds
        self.timer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true, block: { _ in
            self.updateToken()//update token and refresh the favs list statuses
        })
        
    }
    
    //MARK: - kill timer TO STOP IT SPAWNING LEGIONS OF TIMERS.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let timer = refreshimer {
            timer.invalidate()
        }
    }
    
    func ShowTableHideLabel(_showTable: Bool)
    {
        tableView.isHidden = !_showTable
        lblNoFavMessage.isHidden = _showTable
        print("showlabel")
        print(!_showTable)
        self.indicator.isHidden = true //hide indictor on this view as it's constantly going
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        #if DEBUG
       UserDefaults.standard.set("" , forKey: K.aboutContent)//zero about
        #endif
    }
    
    //MARK: - VIEW DID APPEAR
    override func viewDidAppear(_ animated: Bool) {
       
        
        
        updateToken()
         
        
        FavAsyncLoadData()
        CheckShowTable()
        SendToAboutPageInitially()


       
    }
    //MARK: - update api token
    func updateToken(){
        let date = Date()
        print("Grabbing token...")
        print(date)
        
        let db = SensorData()
        let grabAToken = db.GetDBToken()
        print(grabAToken)
        FavAsyncLoadData()//refresh list sure why not
    }
    
    
    func CheckShowTable()
    {
        
            print("checking table show")
            ShowTableHideLabel(_showTable: !(countOfFavs == 0))//hide table show no favs label
        
       
        

    }
     
    
    func LoadTableViewSettings(){
        tableView.delegate = self
        tableView.dataSource = self
        
        activityIndicator()//just load this once
        sensorFavourites = Favourites()
        
        if(showTableSearch){
            filterByValueInTextBox = ""
            searchController = UISearchController(searchResultsController: nil)
            searchController.searchResultsUpdater = self
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.searchBar.placeholder = "Search:"
            /*  searchController.dimsBackgroundDuringPresentation = false*/
            searchController.searchBar.sizeToFit()
            
            tableView.tableHeaderView = searchController.searchBar
            
            navigationItem.searchController = searchController
            
            definesPresentationContext = true // sets controller as presenting view controller for search interface
        }
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: reusableCellName)
        tableView.register(UINib(nibName: sensorCellName, bundle: nil), forCellReuseIdentifier: reusableCellName)

        
        pullControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        pullControl.addTarget(self, action: #selector(self.pulledRefreshControl), for: UIControl.Event.valueChanged)
          tableView.addSubview(pullControl) // not required when using UITableViewController
        
        
        FavAsyncLoadData()
      
       
    }
    
    //MARK: - Pull refreshh table
    @objc func pulledRefreshControl(sender:AnyObject) {
        
        FavAsyncLoadData()
        
        self.tableView.reloadData()
        self.pullControl.endRefreshing()
    }

    
    func updateSearchResults(for searchController: UISearchController) {
        
        print("update")
        listSensors = listSensorsBackUp

        if let searchText = searchController.searchBar.text {
            if !searchText.isEmpty {
                let cleanedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanedText.count > 0   {
                   // filterByValueInTextBox = cleanedText
                    print (cleanedText)
                    //AsyncLoadData(cleanedText : cleanedText)//update search and filter
                    if(!cleanedText.isEmpty && cleanedText.count > 0){
                        let sSearchString = cleanedText
                        let filterBy = sSearchString.trimmingCharacters(in: .whitespacesAndNewlines)
                        if filterBy.count > 0
                        {
                           
                            var newList = listSensors
                            
                            newList?.sensorList.removeAll() //clear out list so it can be filled by the filter code based on text search below
                            
                            
                            for sensor in listSensors!.sensorList{
                                if(sensor.sensorExtraInformation.title.lowercased().contains((filterBy.lowercased())))
                                {
                                    newList!.sensorList.append(sensor)
                                }
                            }
                            self.listSensors = newList
                            
                        }
                        
                        
                    }
                    
                    
                }
                else
                {
                    print("search text is empty")
                    listSensors = listSensorsBackUp
                    //tableView.reloadData()
                }
                
            }
        }else{
            print("herejhjjvjvj")
                listSensors = listSensorsBackUp
                
        }
        tableView.reloadData()
        
    }
          /*
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if !searchText.isEmpty {
            let cleanedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanedText.count > 0   {
                AsyncLoadData()//update search and filter
            }
            
        }
    }*/
    
    func activityIndicator() {
        
    indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        indicator.style = UIActivityIndicatorView.Style.medium
        indicator.center = self.view.center
        self.view.addSubview(indicator)
    }
    
    //MARK: - LOAD FAV SENSORS
    @objc func FavAsyncLoadData(){
        let dispatchGroup = DispatchGroup()
        let db = SensorData()      /*  if let countCurrentList = (listSensors?.sensorList.count){
            if(countCurrentList == 0){
                activityIndicator()
                indicator.startAnimating()
            }
            else
            {
                //dont show as it doesmt turn off
            }
                
        }*/
       
 
        dispatchGroup.enter()
        
        indicator.startAnimating()

        if let token = db.GetDBToken(){
            if !token.isEmpty{
                
            
            db.fetchSensors(completion: {
                result in
                switch result {
                case .failure(let error):
                    self.ShowDialog(title: "Sensor Data", msg: error.localizedDescription)
                case .success(let welcomecls):
                        self.listSensors = welcomecls
                        self.listSensorsBackUp = welcomecls
                    
                    //swap initial connection timer to refresh data every 60 seconds instead
                   /* self.refreshimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.FavAsyncLoadData), userInfo: nil, repeats: true)
                    */
                    
                }
                
                self.indicator.stopAnimating()
                self.indicator.hidesWhenStopped = true
                dispatchGroup.leave()
            })
            }
        }
         else
        {
             
             self.indicator.stopAnimating()
             self.indicator.hidesWhenStopped = true
             dispatchGroup.leave()
             
             
         }//
            
            
       
        
        dispatchGroup.notify(queue: DispatchQueue.main){ [self] in
            
          /*  let count = self.tableView(self.tableView, numberOfRowsInSection: 0)
            if count > 0 {
                self.tableView.deleteRows(at: (0..<count).map({(i) in IndexPath(row: i, section: 0)}), with: .automatic)
                            }
          */
            
            
            var sortedSensors = self.listSensors
            
            if(sortedSensors != nil){
                
                if(sortedSensors?.sensorList.count == 0)
                {
                    ShowDialog(title: "Sensor Outage", msg: "Sorry, there is no sensor information available, please try again later.")
                }
                
                
            print("sensor count then fav count---------------------")
            print(sortedSensors?.sensorList.count)
            var favSensors = sortedSensors
            favSensors?.sensorList.removeAll()
            for s in sortedSensors!.sensorList{
                if(sensorFavourites!.IsInFavList(sensor: s)){
                    favSensors?.sensorList.append(s)
                }
            }
            
            print("my fav count---------------------")
            print(favSensors?.sensorList.count)
            sortedSensors = favSensors
            
            self.listSensors?.sensorList = (sortedSensors?.sensorList.sorted(by: {(!$0.sensorStatus.isOccupied && $0.sensorStatus.isOnline) && ($1.sensorStatus.isOccupied || !$1.sensorStatus.isOnline)}))!
            self.listSensorsBackUp = self.listSensors
             
            
            self.tableView.reloadData()
            
            
            self.indicator.stopAnimating()
            self.indicator.hidesWhenStopped = true
            print("Tasks complete")
            countOfFavs = (favSensors?.sensorList.count)!
            }
            else
            {
                countOfFavs = 0
            }
            
            CheckShowTable()
            
        }
    }
    
     
    
     
    
    //MARK: - SHOW DIALOG
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
    

   

    //MARK: - Send to about page
    func SendToAboutPageInitially()
    {
        let defaults = UserDefaults.standard
        let hasSeenAbout = defaults.bool(forKey: "shownAbout")
        print (hasSeenAbout)
        if(!hasSeenAbout)
        {
            performSegue(withIdentifier: "AboutViewSegue", sender: self)
            UserDefaults.standard.set(true, forKey: "shownAbout")
            print("saved has seen")
        }
    }
    
    func locationManager(
      _ manager: CLLocationManager,
      didFailWithError error: Error
    ) {
      print(error)
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

 
    }

    // 6
    //MARK: - STORE LOCATION
    func locationManager(
      _ manager: CLLocationManager,
      didUpdateLocations locations: [CLLocation]) {
      guard let location = locations.first else {
        return
      }

          //todo store in session for distance calc
          var myLocationCoOrdinate = location.coordinate
          
          print ("my location")
          print (myLocationCoOrdinate)
          //UserDefaults.standard.set(myLocationCoOrdinate, forKey: "myLocation")
          UserDefaults.standard.set(Double(myLocationCoOrdinate.longitude), forKey: "myLocationLong")
          UserDefaults.standard.set(Double(myLocationCoOrdinate.latitude), forKey: "myLocationLat")
          
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

        // 4
        UIView.animate(withDuration: 0.25) {
          self.view.layoutIfNeeded()
        }
      }
    }
    
}
        
extension StartUpViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows = 0
        
        if let count = listSensors?.sensorList.count {
            numberOfRows = count
        }
        return numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reusableCellName, for: indexPath) as! SensorCell
        if let sensor = listSensors?.sensorList[indexPath.row] {
            
            cell.label.text = sensor.sensorExtraInformation.title
            let winControl = SensorDataWindow()
            cell.lblDistance.text = winControl.StringDistanceText(destLat: sensor.sensorGPSPosition.latititude, destLong: sensor.sensorGPSPosition.longitude)
          
            if sensor.sensorStatus.isOnline{
                
                
                if  sensor.sensorStatus.isOccupied {
                    //cell.underLineLabel.backgroundColor = UIColor.red
                    cell.leftImageView.tintColor = UIColor(named: K.red) //UIColor.red                   // cell.label.textColor = UIColor.white
                }
                else{
                    
                   // cell.underLineLabel.backgroundColor = UIColor.green
                    //cell.rightImageView.image = UIImage(systemName: "star.fill")
                    cell.leftImageView.tintColor = UIColor(named: K.green) //UIColor.systemGreen
                   // cell.label.textColor = UIColor.white
                    
                }
            }else{
//cell.underLineLabel.backgroundColor = UIColor.lightGray
                cell.leftImageView.tintColor = UIColor(named: K.warmGrey) // UIColor.lightGray
            }
            
            
            if(sensorFavourites!.IsInFavList(sensor: sensor))//the default is not in favs
            {
                cell.rightImageView.image = UIImage(systemName: "star.fill")
            }
            else
            {
                cell.rightImageView.image = UIImage(systemName: "star")
            }
            
        }
        
        return cell
    }
    
    
}

extension StartUpViewController: UITableViewDelegate{
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //print(indexPath.row)
        
      //  let cell = tableView.dequeueReusableCell(withIdentifier: reusableCellName, for: indexPath) as! SensorCell
        let sensor = listSensors?.sensorList[indexPath.row]
        print( (sensor?.sensorExtraInformation.title ?? "Unknown title") + " " + (sensor?.sensorStatus.lastChangedState ?? "1900-01-01 00:00"))
        
        StoreSelectedIndexSensorOnSelection(indexPath: indexPath)
        self.view.addSubview(showMapPinDetails(s: sensor!))        //return cell
        
        
    }
    
    func StoreSelectedIndexSensorOnSelection(indexPath: IndexPath){
        
        if(indexPath != nil && indexPath.row >= 0){
            let sensor = listSensors?.sensorList[indexPath.row]
            
            selectedSensor = sensor
            selectedSensorIndex = indexPath
        }
       
    }
    
    //MARK: - NAV swipe
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        self.SwipeActionHappened(indexPath: indexPath)
     
        let completeAction = UIContextualAction(style: .normal, title: "Directions") { (_, _, completionHandler) in
            // action the item here
            
            print("do nav dirs here")
            
            self.DirectionToLocationAction()
            completionHandler(true)
        }
        completeAction.image =  UIImage(systemName: "location.fill")

        completeAction.backgroundColor = UIColor(named: K.blue) //.systemBlue
        let configuration = UISwipeActionsConfiguration(actions: [completeAction])
        configuration.performsFirstActionWithFullSwipe = false //stops the full swipe sending them off, makes them click the button
        return configuration

    }

    
    
    //MARK: - FAV SWIPE
func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    self.SwipeActionHappened(indexPath: indexPath)
 
    let completeAction = UIContextualAction(style: .normal, title: "Favourite") { (_, _, completionHandler) in
        // action the item here
        
        print("do fav here")
        
        let isInList = self.sensorFavourites!.IsInFavList(sensor: self.selectedSensor!)
        
        if(isInList){
            let removed =  self.sensorFavourites!.RemoveSensorFromFavs(sensor: self.selectedSensor!)
            if(removed)
            {
                self.updateTableCellsStar(systemNamedImage:  "star")
            }
            
        }
        else{
            let added =  self.sensorFavourites!.AddSensorToList(sensor: self.selectedSensor!)
            if(added)
            {
                self.updateTableCellsStar(systemNamedImage:  "star.fill")
            }
        }
        
        self.SwipeActionHappened(indexPath: indexPath)//refresh the popup windows star too

       // completionHandler(false)
        completionHandler(true)
    }
    completeAction.image =  UIImage(systemName: "star.fill")

    completeAction.backgroundColor = UIColor(named: K.gold) ////.systemOrange
    let configuration = UISwipeActionsConfiguration(actions: [completeAction])
    configuration.performsFirstActionWithFullSwipe = false //make them click the star button to alter favs not action on full swipe
    return configuration

    }

 
    //show the pop up window and update the selected sensors so it can be naved to or faved correctly if a previous tap had happened.
    func SwipeActionHappened(indexPath: IndexPath)
    {
        let sensor = self.listSensors?.sensorList[indexPath.row]
        print( (sensor?.sensorExtraInformation.title ?? "Unknown title") + " " + (sensor?.sensorStatus.lastChangedState ?? "1900-01-01 00:00"))
        
        self.StoreSelectedIndexSensorOnSelection(indexPath: indexPath)
        self.removeMapPinLabelView()
        self.view.addSubview(self.showMapPinDetails(s: sensor!))

    }
    //MARK: - Show location window
    func showMapPinDetails(s: SensorList) -> UIView
    {
      
        let sensorDataWindow = SensorDataWindow()
        let viewToShow = sensorDataWindow.showMapPinDetails(s: s) //gather the basic layout then add the buttons
        
        
        let btnNav = sensorDataWindow.CreateNavButton()
        btnNav.addTarget(self, action: #selector(self.navigation_btn_pressed), for: .touchUpInside)
        viewToShow.addSubview(btnNav)
        
        
        let btnClose =  sensorDataWindow.CreateCloseButton()
        btnClose.addTarget(self, action: #selector(self.close_btn_pressed), for: .touchUpInside)
        viewToShow.addSubview(btnClose)
        
        
        
        let btnFav = sensorDataWindow.CreateFavButton(isFav: sensorFavourites!.IsInFavList(sensor: s))        //TODO CHECK IF IS ON FAV LIST
        btnFav.addTarget(self, action: #selector(self.fav_btn_pressed), for: .touchUpInside)
        viewToShow.addSubview(btnFav)
        
        
       // label.tag = 0xDEADBEEF002
       return viewToShow
     
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
    
    
    
    //deselect
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        print(indexPath.row)
        removeMapPinLabelView()
        
        
    }
    
    @objc func fav_btn_pressed(sender : UIButton)
    {
        print ("nb: close window button")
        let isInList = sensorFavourites!.IsInFavList(sensor: selectedSensor!)
        
        if(isInList){
            let removed =  sensorFavourites!.RemoveSensorFromFavs(sensor: selectedSensor!)
            if(removed)
            {
                updateStarOnFavButtonClick(sender: sender, systemNamedImage: "star")
            }
            
        }
        else{
            let added =  sensorFavourites!.AddSensorToList(sensor: selectedSensor!)
            if(added)
            {
                updateStarOnFavButtonClick(sender: sender, systemNamedImage: "star.fill")
            }
        }
        
    }
    
    func DirectionToLocationAction()
    {
            
            // lat
            let latDouble = Double((selectedSensor?.sensorGPSPosition.latititude)!)
            
            let longDouble = Double((selectedSensor?.sensorGPSPosition.longitude)!)
           
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

    }
    
    
    
    func updateStarOnFavButtonClick(sender : UIButton, systemNamedImage : String){
        
        updateTableCellsStar(systemNamedImage: systemNamedImage)
        sender.setImage(UIImage(systemName: systemNamedImage), for: .normal)
        
    }
    
    func updateTableCellsStar(systemNamedImage : String)
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: reusableCellName, for: selectedSensorIndex!) as! SensorCell
        cell.rightImageView!.image = UIImage(systemName: systemNamedImage)
        tableView.reloadData()
    }
    
    
    
    
    @objc func close_btn_pressed(sender : UIButton)
    {
        print ("nb: close window button")
        removeMapPinLabelView()
        
    }
    
    @objc func navigation_btn_pressed(sender : UIButton)
    {
        print ("nb: pressed nav button")
       // print(curMarker.title)
        print(selectedSensor?.sensorGPSPosition.latititude as Any)
        print(selectedSensor?.sensorGPSPosition.longitude as Any)
        
        DirectionToLocationAction()
        
    }
}


