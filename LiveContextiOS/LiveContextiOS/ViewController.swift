//
//  ViewController.swift
//  LiveContextiOS
//
//  Created by Pablo Garces on 11/16/17.
//

import UIKit
import Speech
import AVFoundation
import SCRecorder
import FBSDKLoginKit
import FBSDKCoreKit
import LFLiveKit
import SwiftyJSON

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, SFSpeechRecognizerDelegate, FBSDKLoginButtonDelegate, LFLiveSessionDelegate {
    

    @IBOutlet weak var goLiveBack: UIView!
    @IBOutlet weak var newsCollectionView: UICollectionView!
    @IBOutlet weak var profileImgVIew: UIImageView!
    @IBOutlet weak var personName: UILabel!
    @IBOutlet weak var goLiveLbl: UILabel!
    @IBOutlet weak var personInfoBack: UIView!
    @IBOutlet weak var goLiveBtn: UIButton!
    @IBOutlet weak var detectedTxt: UILabel!
    @IBOutlet var previewView: UIView!
    @IBOutlet weak var playView: UIView!
    
    var searchQuery = ""
    
    var articleTitles = ["Start Speaking to See Articles Related to your stream!"]
    var articleDescriptions = ["Articles will appear automatically"]
    var articleImageNames = ["placeholder"]
    
    var selectedNewsIndex = 0
    var currentNewsIndex = 0
    var firstTap = true
    var isRecording = false
    var recordedText = ""
    var tempTxt = ""
    var currentlySelectedImg: UIImageView = UIImageView()
    let imglayer = CALayer()
    
    lazy var indicator: UIPageControl = {
        let pc = UIPageControl()
        
        pc.pageIndicatorTintColor = UIColor(red: 241/255, green: 241/255, blue: 241/255, alpha: 1)
        pc.currentPageIndicatorTintColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        
        return pc
    }()
    
    lazy var session: LFLiveSession = {
        
        let audioConfiguration = LFLiveAudioConfiguration.default()
        let videoConfiguration = LFLiveVideoConfiguration.defaultConfiguration(for: LFLiveVideoQuality.default, outputImageOrientation: .portrait)
    
        let session = LFLiveSession(audioConfiguration: audioConfiguration, videoConfiguration: videoConfiguration)
        
        return session!
    }()
    
    // Speech Recognition
    let audioEngine: AVAudioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask = SFSpeechRecognitionTask()
    
    // Camera
//    let session = SCRecordSession()
//    let recorder = SCRecorder()
//    let player = SCPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        profileImgVIew.image = UIImage(named: "face")
        personName.text = "Robert Hernandez"
        
        session.delegate = self
        session.preView = self.view
        session.captureDevicePosition = .front
        
        self.requestAccessForAudio()
        self.requestAccessForVideo()
        
        newsCollectionView.delegate = self
        newsCollectionView.dataSource = self
        goLiveBack.layer.cornerRadius = 6
        personInfoBack.layer.cornerRadius = 6
        profileImgVIew.layer.cornerRadius = 17
        profileImgVIew.layer.masksToBounds = true
        profileImgVIew.contentMode = .scaleAspectFill
        playView.layer.cornerRadius = 6
        playView.layer.masksToBounds = true
        
        indicator.frame = CGRect(x: (view.frame.size.width / 2) - 50, y: newsCollectionView.frame.maxY, width: 100, height: 30)
        indicator.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        indicator.alpha = 0.0
        indicator.numberOfPages = articleTitles.count
        indicator.isHidden = true
        view.addSubview(indicator)
        
        detectedTxt.isHidden = true
        playView.isHidden = true
        
//        if (!recorder.startRunning()) {
//            debugPrint("Recorder error: ", recorder.error as Any)
//        }
//
//        recorder.session = session
//        recorder.device = AVCaptureDevice.Position.front
//        recorder.videoConfiguration.size = CGSize(width: view.frame.size.width, height: view.frame.size.height)
//        recorder.delegate = self
        
        // DEMO ADDING A CELL
//        let when = DispatchTime.now() + 5
//        DispatchQueue.main.asyncAfter(deadline: when) {
//
//            self.addArticle(title: "New Title", description: "New Description", imgName: "img")
//
//        }

    }
    
    override func viewDidLayoutSubviews() {
        
//        recorder.previewView = previewView
//
//        player.setItemBy(session.assetRepresentingSegments())
//        let playerLayer = AVPlayerLayer(player: player)
//        let bounds = playView.bounds
//        playerLayer.frame = bounds
//        playerLayer.addSublayer(imglayer)
//        playView.layer.addSublayer(playerLayer)
        
    }
    
    func requestAccessForVideo() -> Void {
        
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch status  {
            
        case AVAuthorizationStatus.notDetermined:
            
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
                
                if(granted){
                    
                    DispatchQueue.main.async {
                        
                        self.session.running = true
                        
                    }
                    
                }
                
            })
            
            break;
            
        case AVAuthorizationStatus.authorized:
            
            session.running = true;
            
            break
            
        case AVAuthorizationStatus.denied: break
            
        case AVAuthorizationStatus.restricted:break;
            
        default:
            
            break;
            
        }
        
    }
    
    func requestAccessForAudio() -> Void {
        
        let status = AVCaptureDevice.authorizationStatus(for:AVMediaType.audio)
        
        switch status  {
            
        case AVAuthorizationStatus.notDetermined:
            
            AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: { (granted) in
                
                
            })
            
            break
            
            
        case AVAuthorizationStatus.authorized:
            
            break
            
        case AVAuthorizationStatus.denied: break
            
        case AVAuthorizationStatus.restricted: break
            
        default:
            
            break
            
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    //MARK: - Event
    func startLive() -> Void {
        let stream = LFLiveStreamInfo()
        
        stream.url = "rtmp://live-api-a.facebook.com:80/rtmp/165708634021154?ds=1&a=ATgHypOkT41Tqh8P";
        //session.beautyFace = true
        session.warterMarkView = currentlySelectedImg
        session.warterMarkView?.frame = CGRectMake(20, view.frame.size.height - 320, view.frame.size.width - 60, 70)
        session.warterMarkView?.alpha = 0.9
        // session.warterMarkView?.isHidden = true
        session.beautyFace = true
        
        session.startLive(stream)
    }
    
    func stopLive() -> Void {
        session.stopLive()
    }
    
    //MARK: - Callback
    func liveSession(_ session: LFLiveSession?, debugInfo: LFLiveDebug?) {
        
        print("Live Debugger: \(debugInfo)")
        
    }
    func liveSession(_ session: LFLiveSession?, errorCode: LFLiveSocketErrorCode) {
        
        print("Live Error: \(errorCode)")
        
    }
    func liveSession(_ session: LFLiveSession?, liveStateDidChange state: LFLiveState) {
        
        print("State: \(state)")
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return articleTitles.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: newsCollectionView.frame.width - 40, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "newsCell", for: indexPath) as! NewsCell
        
        cell.alpha = 0.6
        cell.backView.layer.cornerRadius = 6
        cell.image.layer.cornerRadius = 6
        cell.image.layer.masksToBounds = true
        cell.backView.layer.masksToBounds = true
        cell.image.contentMode = .scaleAspectFill
        cell.btnBack.layer.cornerRadius = 15
        cell.btnBack.layer.masksToBounds = true
        
        if indexPath.row == selectedNewsIndex {
            cell.blueImg.image = UIImage(named: "stary")

        } else {
            cell.blueImg.image = UIImage(named: "add")
 
        }
        
        // SAMPLE VALUES
        cell.title.text = articleTitles[indexPath.row]
        cell.descrip.text = articleDescriptions[indexPath.row]
        cell.image.image = UIImage(named: articleImageNames[indexPath.row])
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        newsCollectionView.reloadData()
        
        selectedNewsIndex = indexPath.row
        
        let when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            
            self.currentlySelectedImg.image = self.screenShotView(index: indexPath)
            self.session.warterMarkView = self.currentlySelectedImg
        }

        print(selectedNewsIndex)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        currentNewsIndex = indexPath.row
        
    }
    
    func screenShotView(index: IndexPath) -> UIImage {
        
        // Create the UIImage
        UIGraphicsBeginImageContext(newsCollectionView.frame.size)
        newsCollectionView.cellForItem(at: index)?.contentView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Save it to the camera roll
        UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
        
        imglayer.contents = currentlySelectedImg.image?.cgImage
        imglayer.frame = CGRectMake(0, 0, 100, 100)
        imglayer.opacity = 0.6
        
        return image!
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
//        let views = newsCollectionView.visibleCells
//
//        for view in views {
//
//            let subviews = view.subviews
//
//            for subview in subviews {
//
//                subview.layer.opacity = 0.0
//            }
//        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
//        UIView.animate(withDuration: 0.4, animations: {
//
//            let views = self.newsCollectionView.visibleCells
//
//            for view in views {
//
//                let subviews = view.subviews
//
//                for subview in subviews {
//
//                    subview.layer.opacity = 1.0
//                }
//            }
//
//        }, completion: nil)
        
        indicator.currentPage = currentNewsIndex
        
        if scrollView == newsCollectionView {
            
            var currentCellOffset = newsCollectionView.contentOffset
            currentCellOffset.x += newsCollectionView.frame.width / 2
            
            if let indexPath = newsCollectionView.indexPathForItem(at: currentCellOffset) {
                
                newsCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
    }
    
    func addArticle(title: String, description: String, imgName: String) {
        
        articleImageNames.append(imgName)
        articleTitles.append(title)
        articleDescriptions.append(description)
        
        newsCollectionView.reloadData()
        newsCollectionView.reloadInputViews()
        
        let indexPath = IndexPath(row: articleTitles.count - 1, section: 0)
        
        print("Items: \(articleImageNames.count)")
        
        newsCollectionView.scrollToItem(at: indexPath, at: .right, animated: true)

    }
    
    func recordAndRecognizeSpeech() {
        
        let node = audioEngine.inputNode
        
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            buffer, _ in self.request.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            return print(error)
        }
        
        guard let myRecognizer = SFSpeechRecognizer() else {
            return
        }
        
        if !myRecognizer.isAvailable {
            return
        }
        
        recognitionTask = (speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            
            if let result = result {
                
                let bestString = result.bestTranscription.formattedString
                self.tempTxt = bestString
                
            } else if let error  = error {
                print(error)
            }
        }))!
        
    }
    
    func recordVideo() {
        
        // TODO
        
    }
    
    func saveVideo() {
        
        // TODO
        
    }
    
    func overlayVideo() {
        
        // TODO
        
    }
    
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }

    @IBAction func goLiveBtnPressed(_ sender: Any) {

        //Facebook Account Token
        let accessToken = FBSDKAccessToken.current()
        
        //Not loged in
        if accessToken == nil{
            let loginButton = FBSDKLoginButton()
            loginButton.delegate = self
            loginButton.loginBehavior = FBSDKLoginBehavior.native
            
            FBSDKLoginManager().logIn(withReadPermissions: ["email", "public_profile"], from: self) { (result, err) in
                if err != nil {
                    print("Login failed")
                }
                print("Login successful")
            }
        }
        else{
            //Starts Live
            if firstTap {
                
                startLive()
//                FBLiveAPI.shared.startLive() { result in
//                    guard let streamUrlString = (result as? NSDictionary)?.value(forKey: "stream_url") as? String else {
//                        return
//                    }
//                    let streamUrl = URL(string: streamUrlString)
//
//                    guard let lastPathComponent = streamUrl?.lastPathComponent,
//                        let query = streamUrl?.query else {
//                            return
//                    }
//
//                    self.session.startRtmpSession(
//                        withURL: "rtmp://rtmp-api.facebook.com:80/rtmp/",
//                        andStreamKey: "\(lastPathComponent)?\(query)"
//                    )
//
//                    self.livePrivacyControl.isUserInteractionEnabled = false
//                }
//                recorder.record()
//                recorder.scImageView?.ciImage = currentlySelectedImg.image?.ciImage
                
                recordAndRecognizeSpeech()
                isRecording = true
                
                UIView.animate(withDuration: 0.4, animations: {
                    
                    self.goLiveBack.updateConstraintsIfNeeded()
                    self.goLiveLbl.text = "Stop Recording"
                    
                }, completion: nil)
                
            } else {
                
                //recorder.pause()
                
                if audioEngine.isRunning {
                    
                    recordedText = "\(tempTxt)"
                    self.detectedTxt.text = self.recordedText
                    
                    audioEngine.stop()
                    
                    isRecording = false
                    
                    //                print("Search query before: \(self.searchQuery)")
                    googleNLPRequest(self.detectedTxt.text!)
                    let delayTime = DispatchTime.now() + 3
                    DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
                        self.newsRequest(queryString: self.searchQuery)
                        print("Search query after delay: \(self.searchQuery)")
                    })
                    //                print("Search query after: \(self.searchQuery)")
                    newsRequest(queryString: self.searchQuery)
                    
                    UIView.animate(withDuration: 0.4, animations: {
                        
                        self.goLiveBack.updateConstraintsIfNeeded()
                        self.goLiveLbl.text = "Go Live"
                        
                    }, completion: nil)
                    
                    //playView.addSubview(currentlySelectedImg)
                    //player.play()
                    
                    stopLive()
                    
                    
                    // Save to camera roll
                    //                session.mergeSegments(usingPreset: AVAssetExportPresetHighestQuality) { (url, error) in
                    //                    if (error == nil) {
                    //                        url?.saveToCameraRollWithCompletion({ (path, error) in
                    //                            debugPrint(path, error)
                    //                        })
                    //                    } else {
                    //                        debugPrint(error as Any)
                    //                    }
                    //                }
                    
                    
                } else {
                    
//                    recorder.record()
//                    recorder.scImageView?.ciImage = currentlySelectedImg.image?.ciImage
//
                    startLive()
                    isRecording = true
                    
                    do {
                        try audioEngine.start()
                    } catch {
                        return print(error)
                    }
                    
                    UIView.animate(withDuration: 0.4, animations: {
                        
                        self.goLiveBack.updateConstraintsIfNeeded()
                        self.goLiveLbl.text = "Stop Recording"
                        
                    }, completion: nil)
                }
                
            }
            
            firstTap = false
        }
    }
    
    let googleAPIKey = "AIzaSyDRpmhV-a_RTAEqFXBrasTc-rOe_EIY4ik"
    
    func googleNLPRequest(_ text: String) -> Void {
        //        var searchQuery = ""
        
        let parameters: [String:Any] = //["content": , "type": "PLAIN_TEXT"]
            [
                "document": [
                    "type": "PLAIN_TEXT",
                    "content": text],
                "encodingType": "UTF8"
        ]
        guard let url = URL(string: "https://language.googleapis.com/v1/documents:analyzeEntities?key=\(googleAPIKey)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else { return }
        request.httpBody = httpBody
        
        let session = URLSession.shared
        //        var temp = self.searchQuery
        session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                print(response)
            }
            if let data = data {
                do {
                    let json = JSON(data) //try JSONSerialization.jsonObject(with: data, options: [])
                    let entityNames =  json["entities"].arrayValue.map({$0["name"].stringValue})
                    //                    let entityTypes =  json["entities"].arrayValue.map({$0["type"].stringValue})
                    print(entityNames)
                    //                    print(entityTypes)
                    for entity in entityNames {
                        //                        if self.searchTypes.contains(entity) {
                        //                            if !self.searchQuery.isEmpty {
                        //                                self.searchQuery.append(" AND ")
                        //                            }
                        //                            self.searchQuery.append(entityNames[eCount])
                        //                        }
                        if !self.searchQuery.isEmpty {
                            self.searchQuery.append(" AND ")
                        }
                        self.searchQuery.append(entity)
                        //                        if eCount > 5 {
                        //
                        //                        }
                        //                        eCount += 1
                    }
                    //                    self.searchQuery = String(self.searchQuery.characters.map {
                    //                        $0 == " " ? "%20" : $0
                    //                    })
                    self.searchQuery = self.searchQuery.replacingOccurrences(of: " ", with: "%20")
                    
                    
                    
                    //                    print(newsURL)
                    print(self.searchQuery)
                    //                    return(searchQuery)
                    //                    temp = .searchQuery
                }
                //                } catch {
                //                    print(error)
                //                }
            }
            }.resume()
        //        print("Final Return: \(searchQuery)")
        //        print("Final Return2: \(temp)")
        //        return searchQuery
    }
    
    let newsAPIKey = "115ae73a193e41749bb267ba7cdbc1a7"
    
    func newsRequest(queryString: String) -> Void {
        
        //        print("news request search query: ")
        //        print(self.searchQuery)
        
        //        let encodeString = queryString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        //        print("Encoded String: \(encodeString!)")
        //        let sources = "abc-news,cnn,fox-news,the-guardian-uk,nbc-news,the-new-york-times,usa-today,the-wall-street-journal,the-washington-post,buzzfeed,google-news"
        
        guard let newsURL = URL(string: "https://newsapi.org/v2/everything?apiKey=\(newsAPIKey)&q=\(queryString)&language=en&sortBy=relevance") else {return}
        
        let session = URLSession.shared
        session.dataTask(with: newsURL) { (data, response, error) in
            if let response = response {
                print(response)
            }
            if let data = data {
                //do {
                    let json = JSON(data)//try JSONSerialization.jsonObject(with: data, options: [])
                    //                    print(json)
                    self.articleTitles = json["articles"].arrayValue.map({$0["title"].stringValue})
                    self.articleDescriptions = json["articles"].arrayValue.map({$0["description"].stringValue})
                    self.articleImageNames =  json["articles"].arrayValue.map({$0["urlToImage"].stringValue})
                    
                    if let articleTitle = self.articleTitles.first, let articleDscpt = self.articleDescriptions.first, let articleImg = self.articleImageNames.first{
                        self.addArticle(title: articleTitle, description: articleDscpt, imgName: articleImg)
                        
                        self.indicator.numberOfPages = self.articleTitles.count
                        
                        UIView.animate(withDuration: 0.5, animations: {
                            self.indicator.isHidden = false
                            self.indicator.alpha = 0.6
                        })
                    }
                    
                    print("titles", self.articleTitles)
                    print("dscpts", self.articleDescriptions)
                    print("images", self.articleImageNames)
                    //                    for article in articles {
                    //                        self.articleTitles.append(articl)
                    //                    }
                //}
                //                } catch {
                //                    print(error)
                //                }
            }
            }.resume()
        
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
        if error == nil {
            
            profileImgVIew.image = UIImage(named: "face")
            personName.text = "Robert Hernandez"
            
        }
        
        return
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
        return
    }
    
}

extension ViewController: SCRecorderDelegate {
    
    func recorder(_ recorder: SCRecorder, didAppendVideoSampleBufferIn session: SCRecordSession) {

    }
}

