

import Foundation
import UIKit
import PDFKit

class AboutViewController: UIViewController {
    
    @IBOutlet weak var btnPrivacyPolicy: UIButton!
    @IBOutlet weak var lblVersion: UILabel!
    
    @IBOutlet weak var btnTerms: UIButton!
    @IBOutlet weak var txtViewAbout: UITextView!
    
    var aboutPageResponse : InformationContentResponse?
    var privacyURLResponse : InformationContentResponse?
    var termsURLResponse : InformationContentResponse?
    var refreshimer:Timer? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "About"
        
        lblVersion.text = Bundle.main.releaseVersionNumberPretty
        PopulateTextViewContent()
        
        //once the text field gets filled this timer is triggered to invalidate until then run it every second
        refreshimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.FetchAboutContent), userInfo: nil, repeats: true)
       
    }
    
    
    @IBAction func btnTermsClicked(_ sender: Any) {
         
        let urlString = self.termsURLResponse?.content
        OpenURLOrPDFFromStringURL(urlString: urlString!)
        
    }
    
    @IBAction func btnPrivacyPolicyClick(_ sender: Any) {
         
        let urlString = self.privacyURLResponse?.content
        OpenURLOrPDFFromStringURL(urlString: urlString!)
        
    }
    
    func OpenURLOrPDFFromStringURL(urlString : String)
    {
        if(!urlString.isEmpty) && (urlString != ""){
            
            if(urlString.contains(".pdf")){
                // pdfView = PDFView(frame: view.bounds.)
                
                let rect = view.bounds
                print (rect)
                let smallerPDFView =  PDFView(frame: view.bounds) //PDFView(frame: CGRect(x: rect.maxX + 10, y: rect.maxY + 10, width: rect.width - 20,  height: rect.height - 50))
                
                
                
                view.addSubview(smallerPDFView)
                
                if let url = URL(string: urlString), let document = PDFDocument(url: url) {
                    smallerPDFView.document = document
                }
                
            }
            else{
                print("trying to open url")
                print(urlString)
                guard let url = URL(string: urlString) else { // else will be called when url is nil
                    print("url is nil")
                    
                    return
                }
                
               OpenURL(url: url)
                
            }
            
            
        }
    }
    func  OpenURL(url: URL){
        
        if url.description.lowercased().starts(with: "http://") ||
            url.description.lowercased().starts(with: "https://")  {
            print(url)//use extension to escapre the character encoding so it can be used
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            print(url)
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        var content = UserDefaults.standard.string(forKey: K.aboutContent)
        
        txtViewAbout.text = "Loading..."
        
        if(content != nil){
            txtViewAbout.attributedText = content?.htmlToAttributedString
        }
         
        FetchAboutContent()
        
        
    }
    override func viewDidAppear(_ animated: Bool) {
        
        FetchAboutContent()
    }
    
    func PopulateTextViewContent()
    {
        //FetchAboutContent()
        if((self.aboutPageResponse?.isHTML) != nil) {
            
            if (self.aboutPageResponse!.isHTML){
                
                txtViewAbout.text = self.aboutPageResponse?.content.htmlToString
                txtViewAbout.attributedText = self.aboutPageResponse?.content.htmlToAttributedString
            }
            else
            {
                txtViewAbout.text = self.aboutPageResponse?.content
            }
            
            refreshimer?.invalidate() //stop the timer running every second we finally have something to show
        }
       
    txtViewAbout.textColor = UIColor(named: K.blue)
        
        txtViewAbout.font = UIFont(name: K.fontName, size: 16)
        txtViewAbout.sizeToFit()
    }
    
    //MARK: - kill timer
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let timer = refreshimer {
            timer.invalidate()
        }
    }
    
    
   @objc   func FetchAboutContent(){
        let dispatchGroup = DispatchGroup()
        let db = SensorData()
       
        print("fetch content")
       print(Date())
       
        dispatchGroup.enter()
        
        if let token = db.GetDBToken(){
            if !token.isEmpty{
                var status = Status(rc: 0, response: "", success: true)
                var content = ""
                var isHTML = false
                var defaultErr = InformationContentResponse(status: status, content: content, isHTML: isHTML)

                db.ReturnInformationContentResponse(theEndPoint: K.endpoint_privacy, completion: {
                    result in
                    switch result {
                    case .failure(let error):
                        status = Status(rc: 1, response: error.localizedDescription, success: false)
                          content = ""
                          isHTML = false
                          defaultErr = InformationContentResponse(status: status, content: content, isHTML: isHTML)
                        self.privacyURLResponse = defaultErr
                    case .success(let infoResp):
                            self.privacyURLResponse = infoResp
                        
                    }
                })
                db.ReturnInformationContentResponse(theEndPoint: K.endpoint_about, completion: {
                    result in
                    switch result {
                    case .failure(let error):
                        status = Status(rc: 1, response: error.localizedDescription, success: false)
                        content = "About page content has not been retrieved, please try again later. Sorry about this!"
                        isHTML = false
                        defaultErr = InformationContentResponse(status: status, content: content, isHTML: isHTML)
                        self.aboutPageResponse = defaultErr
                        print("No about content - create timer")
                        self.refreshimer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(self.FetchAboutContent), userInfo: nil, repeats: false)
                    case .success(let infoResp):
                            self.aboutPageResponse = infoResp
                        
                    }
                    
                })
                
                db.ReturnInformationContentResponse(theEndPoint: K.endpoint_terms,  completion: {
                    result in
                    switch result {
                    case .failure(let error):
                        status = Status(rc: 1, response: error.localizedDescription, success: false)
                        content = "Terms And Conditions page content has not been retrieved, please try again later. Sorry about this!"
                        isHTML = false
                        defaultErr = InformationContentResponse(status: status, content: content, isHTML: isHTML)
                        self.termsURLResponse = defaultErr
                    case .success(let infoResp):
                            self.termsURLResponse = infoResp
                        
                    }
                    
                })
           
                
                
                dispatchGroup.leave()
                
            }
        }
         else
        {
           
             dispatchGroup.leave()
         
             
             
         }//
            
            
       
        
        dispatchGroup.notify(queue: DispatchQueue.main){ [self] in
            
          /*  let count = self.tableView(self.tableView, numberOfRowsInSection: 0)
            if count > 0 {
                self.tableView.deleteRows(at: (0..<count).map({(i) in IndexPath(row: i, section: 0)}), with: .automatic)
                            }
          */
            PopulateTextViewContent()
            
        }
    }
    
     
    
    
    
    
}

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return nil
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}


extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    var releaseVersionNumberPretty: String {
        return "version \(releaseVersionNumber ?? "1.0.0")"
    }
}
//important for privacy and terms urls
extension String
{
    func encodeUrl() -> String?
    {
        return self.addingPercentEncoding( withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
    }
    func decodeUrl() -> String?
    {
        return self.removingPercentEncoding
    }
}
