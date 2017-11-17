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

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, SFSpeechRecognizerDelegate {

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
    
    var numArticles = 0
    var articleTitles = ["This is happening in some place, here is some sample text.",
                         "This is happening in some place, here is some sample text.",
                         "This is happening in some place, here is some sample text.",
                         "This is happening in some place, here is some sample text."]
    var articleDescriptions = ["This is the description of the news.",
                         "This is the description of the news.",
                         "This is the description of the news.",
                         "This is the description of the news."]
    var articleImageNames = ["img",
                               "img",
                               "img",
                               "img"]
    
    var selectedNewsIndex = 0
    var currentNewsIndex = 0
    var firstTap = true
    var isRecording = false
    var recordedText = ""
    var tempTxt = ""
    
    lazy var indicator: UIPageControl = {
        let pc = UIPageControl()
        pc.numberOfPages = numArticles
        
        pc.pageIndicatorTintColor = UIColor(red: 241/255, green: 241/255, blue: 241/255, alpha: 1)
        pc.currentPageIndicatorTintColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)
        
        return pc
    }()
    
    // Speech Recognition
    let audioEngine: AVAudioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask = SFSpeechRecognitionTask()
    
    // Camera
    let session = SCRecordSession()
    let recorder = SCRecorder()
    let player = SCPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        numArticles = articleTitles.count
        
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
        indicator.alpha = 0.6
        view.addSubview(indicator)
        
        if (!recorder.startRunning()) {
            debugPrint("Recorder error: ", recorder.error as Any)
        }
        
        recorder.session = session
        recorder.device = AVCaptureDevice.Position.front
        recorder.videoConfiguration.size = CGSize(width: view.frame.size.width, height: view.frame.size.height)
        recorder.delegate = self
        
        // DEMO ADDING A CELL
        let when = DispatchTime.now() + 5
        DispatchQueue.main.asyncAfter(deadline: when) {
            // Your code with delay
            
            self.addArticle()
            
        }

    }
    
    override func viewDidLayoutSubviews() {
        
        recorder.previewView = previewView
        
        player.setItemBy(session.assetRepresentingSegments())
        let playerLayer = AVPlayerLayer(player: player)
        let bounds = playView.bounds
        playerLayer.frame = bounds
        playView.layer.addSublayer(playerLayer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return numArticles
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
        
        // SAMPLE VALUES
        cell.title.text = articleTitles[indexPath.row]
        cell.descrip.text = articleDescriptions[indexPath.row]
        cell.image.image = UIImage(named: articleImageNames[indexPath.row])
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        selectedNewsIndex = indexPath.row
        
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        currentNewsIndex = indexPath.row
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        indicator.currentPage = currentNewsIndex
        
        if scrollView == newsCollectionView {
            
            var currentCellOffset = newsCollectionView.contentOffset
            currentCellOffset.x += newsCollectionView.frame.width / 2
            
            if let indexPath = newsCollectionView.indexPathForItem(at: currentCellOffset) {
                
                newsCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
    }
    
    func addArticle() {
        
        articleImageNames.append("img")
        articleTitles.append("New Title")
        articleDescriptions.append("New Description")
        
        let indexPath = IndexPath(row: articleImageNames.count, section: 0)
        
        newsCollectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.left, animated: true)

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

        if firstTap {
            
            recorder.record()

            recordAndRecognizeSpeech()
            isRecording = true
            
            UIView.animate(withDuration: 0.4, animations: {
                
                self.goLiveBack.updateConstraintsIfNeeded()
                self.goLiveLbl.text = "Stop Recording"
                
            }, completion: nil)
            
        } else {
            
            recorder.pause()
            
            if audioEngine.isRunning {
                
                recordedText = "\(tempTxt)"
                self.detectedTxt.text = self.recordedText
                
                audioEngine.stop()
                
                isRecording = false
                
                UIView.animate(withDuration: 0.4, animations: {
                    
                    self.goLiveBack.updateConstraintsIfNeeded()
                    self.goLiveLbl.text = "Go Live"
                    
                }, completion: nil)
                
                // Preview Video
                // player.play()
                
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
                
                recorder.record()
                
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

extension ViewController: SCRecorderDelegate {
    
    func recorder(_ recorder: SCRecorder, didAppendVideoSampleBufferIn session: SCRecordSession) {

    }
}

