import Foundation

struct SensorData{
    

    var authID = Bundle.main.infoDictionary?["API_AuthID"] as? String  
    var staticCredentials = Bundle.main.infoDictionary?["API_Credentials"] as? String
    
   
  
    func GetSensorList() -> Welcome{
        let defaults = UserDefaults.standard
        let jsonAccessClass = defaults.string(forKey: K.defaultSensorClassName)
      
        if(jsonAccessClass != nil){
            let jsonDecoder = JSONDecoder()
            
            let jsonData = jsonAccessClass!.data(using: .utf8)!
            print("we have sensors, check present")
           
            var sensorClass = try! JSONDecoder().decode(Welcome.self, from: jsonData)
            return sensorClass
        }
        else
        {
            return Welcome(status: Status(rc: 1, response: "", success: false), sensorList: [])
        }
      
         
    }
    
    func SaveSensorList(cls : Welcome){
        let jsonEncoder = JSONEncoder()
      //  sensorList.append(sensor)
        let jsonData = try! jsonEncoder.encode(cls)
        let json = String(data: jsonData, encoding: .utf8)
        UserDefaults.standard.set(json ?? "", forKey: K.defaultSensorClassName)
         
    }
    
    
    
    //MARK: - GET TOKEN
    func GetDBToken() -> String? {
        let defaults = UserDefaults.standard
        let jsonAccessToken = defaults.string(forKey: K.defaultTokenGUID)
        print("authID")
        print(authID)
       // print(staticCredentials)
        print(K.baseURLString)
        var token = ""
        print (jsonAccessToken)
        if jsonAccessToken != nil && !(jsonAccessToken ?? "").isEmpty
        {
            let jsonAccessClass = defaults.string(forKey: K.defaultTokenClassName)
          
            let jsonDecoder = JSONDecoder()
            
            let jsonData = jsonAccessClass!.data(using: .utf8)!
            print("we have token, check is expired?")
           
            var accessClass = try! JSONDecoder().decode(ManagementTokenResponse.self, from: jsonData)
            let date = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            
            let newTDateString = accessClass.expiryDate.replacingOccurrences(of: " ", with: "T", options: .literal, range: nil)
            let expirydate = dateFormatter.date(from: newTDateString)
            print("expiry date")
            print (expirydate)
            print("cur date")
            print (date)
            if(expirydate! <= date){
                
                UserDefaults.standard.set("" , forKey: K.defaultTokenGUID)//zero token
                //fetch it again
                print("token expired!!!!!!!!!!! try again")
                return GetDBToken()
            }
            
            
            
            return jsonAccessToken//.token
            
        }
        else
        {
            ManagementLogin(completion: {
                result in
                switch result {
                case .failure(let error):
                    print("token errror")
                    print( error)
                case .success(let mantoken):
                   // cls = mantoken
                       SaveAccessToken(cls: mantoken)
                    token = mantoken.token
                    print("token success ------------------------------")
                //    print(mantoken.token)
                   // return mantoken
                }
                
                 
            })
           
            return token
        }
    }
    
    //MARK: - SAVE TOKEN
    func SaveAccessToken(cls : ManagementTokenResponse){
        let jsonEncoder = JSONEncoder()
      //  sensorList.append(sensor)
        let jsonData = try! jsonEncoder.encode(cls)
        let json = String(data: jsonData, encoding: .utf8)
        UserDefaults.standard.set(json ?? "", forKey: K.defaultTokenClassName)
        
        UserDefaults.standard.set(cls.token , forKey: K.defaultTokenGUID)
    }
    
     
 
    //MARK: - Generoc information content response request
    func ReturnInformationContentResponse(theEndPoint : String, completion: @escaping (Result<InformationContentResponse, Error>) -> Void)
    {
        
        let stringSensorURL = K.baseURLString + theEndPoint
        let apiurl = URL(string: stringSensorURL)

        guard let url = apiurl else { return }

        let tokenString = GetDBToken()
        
        
        print (stringSensorURL)
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields?.removeAll()
        request.httpMethod = "GET"
   
            if let tkn = tokenString{
                if !tkn.isEmpty {
                    
                     request.setValue(tkn, forHTTPHeaderField: "x-credentials-auth")
                
                    request.setValue(authID, forHTTPHeaderField: "x-access-ID")
                }
            }
         
 
        URLSession.shared.dataTask(with: request) { (data, response, error) in
               guard let data = data else {
                   if let error = error {
                       DispatchQueue.main.async {
                           completion(.failure(error))
                           print("err1---------------------------")
                        print(error)
                       }
                   }
                   return
               }
               do {
                   
                   print ("data returned")
                   print (data)
                    
                   
                  // print (String(str))
                   let decoder = JSONDecoder()
                   decoder.keyDecodingStrategy = .convertFromSnakeCase
                   let result = try decoder.decode(InformationContentResponse.self, from: data)
                   print ("result -> terms URL")
                   print (result.content)
                    
                   UserDefaults.standard.set(result.content , forKey: K.privacyURL)
                   DispatchQueue.main.async {
                       completion(.success(result))
                   }
               } catch {
                   DispatchQueue.main.async {
                       completion(.failure(error))
                       print("err2---------------------------")
                       print(error)
                   }
               }
           }.resume()
               
    }
    
    
   //MARK: - FETCH SENSORS
    func fetchSensors(completion: @escaping (Result<Welcome, Error>) -> Void) {
        
        let stringSensorURL = K.baseURLString + "SpacefinderSensors/Accessible/List/All"
        let apiurl = URL(string: stringSensorURL)

        guard let url = apiurl else { return }

        var tokenString = GetDBToken()
        
        
print (stringSensorURL)
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields?.removeAll()
        request.httpMethod = "GET"
        
        do {
            
            if let tkn = tokenString{
                if !tkn.isEmpty {
                    
                     request.setValue(tkn, forHTTPHeaderField: "x-credentials-auth")
                  
                
                 request.setValue(authID, forHTTPHeaderField: "x-access-ID")
                }
            }
           
           // abc == nil ? () : abc = "string"
        } catch {
            
                print("NILL---------------------------")
                print(error)
             
        }
           
 
        URLSession.shared.dataTask(with: request) { (data, response, error) in
               guard let data = data else {
                   if let error = error {
                       DispatchQueue.main.async {
                           completion(.failure(error))
                           print("err1---------------------------")
                        print(error)
                       }
                   }
                   return
               }
               do {
                   
                   print ("data returned")
                   print (data)
                   
                   let str = String(decoding: data, as: UTF8.self)
                   
                  // print (String(str))
                   let decoder = JSONDecoder()
                   decoder.keyDecodingStrategy = .convertFromSnakeCase
                   let result = try decoder.decode(Welcome.self, from: data)
                   print ("result -> sensorlist count")
                   print (result.sensorList.count)
                   DispatchQueue.main.async {
                       completion(.success(result))
                   }
               } catch {
                   DispatchQueue.main.async {
                       completion(.failure(error))
                       print("err2---------------------------")
                       print(error)
                   }
               }
           }.resume()
               
       }
    
    func ReturnCurrentDateTimeString() -> String{
        //var date
        let dateFormatter : DateFormatter = DateFormatter()
        //  dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        
        return dateString
    }
    
    //MARK: - Management login
    func ManagementLogin(completion: @escaping (Result<ManagementTokenResponse, Error>) -> Void) {
      
        let dateString = ReturnCurrentDateTimeString()
        print(dateString)
        let newTDateString = dateString.replacingOccurrences(of: " ", with: "T", options: .literal, range: nil)
        print (newTDateString)
        
        let stringSensorURL = K.baseURLString + "Management/Login/External"
        let apiurl = URL(string: stringSensorURL)

        guard let url = apiurl else { return }

       
        
         
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
      
        components.queryItems = [
            URLQueryItem(name: "authID", value: authID),
            URLQueryItem(name: "credentials", value: staticCredentials! + newTDateString)
        ]

        let query = components.url!.query
        
print (stringSensorURL)
        var request = URLRequest(url: url)
      //  request.allHTTPHeaderFields?.removeAll()
       // request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
       // request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        
        
        /*let parameters: [String: Any] = [
            "authID": authID,
            "credentials": "334C5BBE-5776-dunlao-BiosC-BB9B2FAA4122|C136833B-AD63-479B-9E27-E6EC32DD6C16#4|" + newTDateString
        ]*/
        
        do {
           // convert parameters to Data and assign dictionary to httpBody of request
            request.httpBody = Data(query!.utf8)//try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            
            print ("http body -------------------")
            print (query?.utf8)
         } catch let error {
           print(error.localizedDescription)
           return
         }
       // request.httpBody = parameters.percentEncoded()
 
        URLSession.shared.dataTask(with: request) { (data, response, error) in
               guard let data = data else {
                   if let error = error {
                       DispatchQueue.main.async {
                           completion(.failure(error))
                           print("post err1---------------------------")
                        print(error)
                       }
                   }
                   return
               }
               do {
                   
                   print ("post data returned")
                   print (data)
                   
                   let str = String(decoding: data, as: UTF8.self)
                   
//print (String(str))
                   let decoder = JSONDecoder()
                   decoder.keyDecodingStrategy = .convertFromSnakeCase
                   let result = try decoder.decode(ManagementTokenResponse.self, from: data)
                   print ("post result")
                  // print (result)
                   DispatchQueue.main.async {
                       completion(.success(result))
                   }
               } catch {
                   DispatchQueue.main.async {
                       completion(.failure(error))
                       print("post err2---------------------------")
                       print(error)
                   }
               }
           }.resume()
               
       }
    
    
}
extension Dictionary {
    func percentEncoded() -> Data? {
        map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed: CharacterSet = .urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
