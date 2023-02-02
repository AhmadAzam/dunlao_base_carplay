import UIKit
 
 
class SensorTableViewController: UIViewController , UISearchResultsUpdating{
 
    
     
    let reusableCellName = "ReusableCell"
    let sensorCellName = "SensorCell"
    let defaultFavName = "jsonFavs"
    var indicator = UIActivityIndicatorView()
    var pullControl = UIRefreshControl()

    @IBOutlet weak var tableView: UITableView!
    
     
    var filterByValueInTextBox : String?
    
    var listSensors: Welcome?
    var listSensorsBackUp: Welcome?
    var selectedSensor: SensorList?
    var sensorFavourites : Favourites?
    var selectedSensorIndex: IndexPath?
    var searchController: UISearchController!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Live List"
        
       // self.ShowDialog(title: "WELCOME", msg: "HI THERE")
        
        LoadTableViewSettings()
      
       
        
        
    }
    
    func LoadTableViewSettings(){
        tableView.delegate = self
        tableView.dataSource = self
        
        sensorFavourites = Favourites()
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
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: reusableCellName)
        tableView.register(UINib(nibName: sensorCellName, bundle: nil), forCellReuseIdentifier: reusableCellName)

        
        pullControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        pullControl.addTarget(self, action: #selector(self.pulledRefreshControl), for: UIControl.Event.valueChanged)
          tableView.addSubview(pullControl) // not required when using UITableViewController
        
        
        AsyncLoadData()
      
       
    }
    
    
    @objc func pulledRefreshControl(sender:AnyObject) {
       AsyncLoadData()
        
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
    
    func AsyncLoadData(){
        let dispatchGroup = DispatchGroup()
        let db = SensorData()
        
        activityIndicator()
        indicator.startAnimating()
        indicator.backgroundColor = .white
        
        dispatchGroup.enter()
        
         
            db.fetchSensors(completion: {
                result in
                switch result {
                case .failure(let error):
                    //self.ShowDialog(title: "Sensor Data", msg: error.localizedDescription)
                    print (error.localizedDescription)
                    self.listSensors = db.GetSensorList()//hopefully we have a back up stored here
                    self.listSensorsBackUp = self.listSensors
                    print("HAD TO USE STORED CLASS DATA AS API NON RESPONSIVE=================================")
                case .success(let welcomecls):
                        self.listSensors = welcomecls
                        self.listSensorsBackUp = welcomecls
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
            self.listSensorsBackUp = self.listSensors
             
            
            self.tableView.reloadData()
            
            
            self.indicator.stopAnimating()
            self.indicator.hidesWhenStopped = true
            print("Tasks complete")
            
            
        }
    }
    
    
    
    
    
    func ShowNavQDialog(title : String, msg : String){
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
            action in
            switch action.style {
            case .default:
                self.DirectionToLocationAction()
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
    
}
   



extension SensorTableViewController: UITableViewDataSource{
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
                    cell.leftImageView.tintColor = UIColor(named: K.red)                  // cell.label.textColor = UIColor.white
                }
                else{
                    
                   // cell.underLineLabel.backgroundColor = UIColor.green
                    //cell.rightImageView.image = UIImage(systemName: "star.fill")
                    cell.leftImageView.tintColor = UIColor(named: K.green)  //UIColor.systemGreen
                   // cell.label.textColor = UIColor.white
                    
                }
            }else{
//cell.underLineLabel.backgroundColor = UIColor.lightGray
                cell.leftImageView.tintColor = UIColor(named: K.warmGrey)// UIColor.lightGray
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

extension SensorTableViewController: UITableViewDelegate{
  
    
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

    completeAction.backgroundColor = UIColor(named: K.gold)//.systemOrange
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
        var isInList = sensorFavourites!.IsInFavList(sensor: selectedSensor!)
        
        if(isInList){
            var removed =  sensorFavourites!.RemoveSensorFromFavs(sensor: selectedSensor!)
            if(removed)
            {
                updateStarOnFavButtonClick(sender: sender, systemNamedImage: "star")
            }
            
        }
        else{
            var added =  sensorFavourites!.AddSensorToList(sensor: selectedSensor!)
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
