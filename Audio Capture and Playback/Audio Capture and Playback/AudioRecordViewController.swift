//
//  AudioRecordViewController.swift
//  Audio Capture and Playback
//
//  Created by Megan Wilson on 10/29/19.
//  Copyright © 2019 Megan Wilson. All rights reserved.
//

import UIKit
import AVKit

class AudioRecordViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {

    @IBOutlet weak var RecordButton: UIBarButtonItem!
    @IBOutlet weak var PlayButton: UIBarButtonItem!
    @IBOutlet weak var status: UILabel!
    
    var audioSes: AVAudioSession?
    var audioRecord: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var fileManager: FileManager?
    var documentDirectoryURL: URL?
    var audioFileName = "audio.caf"
    var audioFileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        RecordButton.isEnabled = false
        PlayButton.isEnabled = false
             
        initializeAudioFileStorage()
        initializeAudioSes()
            
            audioSes?.requestRecordPermission() {
                [unowned self] allowed in
                if allowed {
                    self.initializeAudioRecorder()
                    guard let _ = self.audioSes, let _ = self.audioRecord else {
                        self.presentAlert(message: "Unable to initialize audio.")
                        return
                    }
                    
                    self.RecordButton.isEnabled = true
                } else {
                    self.presentAlert(message: "Access to recording was denied.")
                }
            }

    }
    
    
    func initializeAudioFileStorage() {
           let fileManager = FileManager.default
           let documentDirectoryPaths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
           documentDirectoryURL = documentDirectoryPaths[0]
           audioFileURL = documentDirectoryURL?.appendingPathComponent(audioFileName)
       }
       
    func initializeAudioSes() {
           audioSes = AVAudioSession.sharedInstance()
           
           do {
               try audioSes?.setCategory(.playAndRecord, mode: .default, options: [])
           } catch {
               presentAlert(message: "audioSession error: \(error.localizedDescription)")
           }
       }
       
    func initializeAudioRecorder() {
           let recordingSettings =
               [AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue,
                AVEncoderBitRateKey: 16,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100.0] as [String : Any]
           
           guard let audioFileURL = audioFileURL else {
               presentAlert(message: "No audio file URL is available.")
               return
           }
           
           do {
               try audioRecord = AVAudioRecorder(url: audioFileURL, settings: recordingSettings)
               audioRecord?.delegate = self
           } catch {
               presentAlert(message: "Error initializing the audio recorder: \(error.localizedDescription)")
           }
       }
    
    @IBAction func recordHit(_ sender: Any) {
        if (audioRecord?.isRecording == false) {
                   PlayButton.isEnabled = false
                   RecordButton.image = UIImage(named: "stop")
                   audioRecord?.record()
               } else {
                   PlayButton.isEnabled = true
                   RecordButton.image = UIImage(named: "record")
                   audioRecord?.stop()
               }
    }
    
    @IBAction func playHit(_ sender: Any) {
        guard let audioFileURL = audioFileURL else {
                   presentAlert(message: "Audio file is not available to play.")
                   return
               }
               guard let audioRecorder = audioRecord, audioRecorder.isRecording == false else {
                   presentAlert(message: "Unable to play audio during recording.")
                   return
               }
               if let audioPlayer = audioPlayer {
                   if (audioPlayer.isPlaying) {
                       audioPlayer.stop()
                       PlayButton.image = UIImage(named: "play")
                       RecordButton.isEnabled = true
                       return
                   }
               }
               do {
                   audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
                   audioPlayer?.delegate = self
                   audioPlayer?.prepareToPlay()
                   audioPlayer?.play()
                   RecordButton.isEnabled = false
                   PlayButton.image = UIImage(named: "stop")
               }
               catch {
                   presentAlert(message: "Unable to create audio player.")
                   return
               }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
          RecordButton.isEnabled = true
          PlayButton.image = UIImage(named: "play")
      }
      
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
          guard let error = error  else {
              return
          }
          presentAlert(message: "Audio play decoding error: \(error.localizedDescription)")
      }
      
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
          guard let error = error  else {
              return
          }
          presentAlert(message: "Audio record encoding error: \(error.localizedDescription)")
      }
    
    func presentAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
    
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
}
