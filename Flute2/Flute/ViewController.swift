//
//  ViewController.swift
//  Flute
//
//  Created by Denis Malykh on 15.06.17.
//  Copyright © 2017 Yandex. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var button: UIButton!
    
    var midiPlayer: AVMIDIPlayer?
    let sampler = FluteSampler()
    
    let soundFont = "<put soundfont file name here>"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {
            print("Error: could not set audio session")
        }
    }
    
    @IBAction func playFlute(_ sender: Any) {
        if midiPlayer == nil {
            button.setTitle("Stop this madness", for: .normal)
            doTheMusic()
        } else {
            button.setTitle("Play another one!", for: .normal)
            midiPlayer?.stop()
            midiPlayer = nil
        }
    }

    func doTheMusic() {
        let music = sampler.sample(1000)
        
        if let sequence = createMusicSequence(music),
            let data = dataFromMusicSequence(sequence) {
            
            let midiData = data.takeUnretainedValue() as Data
            midiPlayer = createMIDIPlayer(midiData: midiData)
            data.release()
            
            midiPlayer?.play(nil)
        }
    }
    
    func createMusicSequence(_ music: [(Int, Int, Int, Int)]) -> MusicSequence? {
        var musicSequence: MusicSequence?
        var status = NewMusicSequence(&musicSequence)
        guard status == OSStatus(noErr) else {
            print("Error: could not create MusicSequence \(status)")
            return nil
        }
        
        var track: MusicTrack?
        status = MusicSequenceNewTrack(musicSequence!, &track)
        guard status == OSStatus(noErr) else {
            print("Error: could not create MusicTrack \(status)")
            return nil
        }
        
        let channel = UInt8(0)
        
        //let instrument = UInt8(73)
        let instrument = UInt8(73)
        
        let tempo = Double(320.0) // 240, 480
        
//        var chanmess = MIDIChannelMessage(status: 0xB0 | channel, data1: 0, data2: 0, reserved: 0)
//        status = MusicTrackNewMIDIChannelEvent(track!, 0, &chanmess)
//        if status != noErr {
//            print("creating bank select msb event \(status)")
//        }
//        
//        chanmess = MIDIChannelMessage(status: 0xB0 | channel, data1: 32, data2: 0, reserved: 0)
//        status = MusicTrackNewMIDIChannelEvent(track!, 0, &chanmess)
//        if status != noErr {
//            print("creating bank select lsb event \(status)")
//        }
        
        var chanmess = MIDIChannelMessage(status: 0xC0 | channel, data1: instrument, data2: 0, reserved: 0)
        status = MusicTrackNewMIDIChannelEvent(track!, 0, &chanmess)
        if status != noErr {
            print("creating program change event \(status)")
        }
        
        var totalTicks = 0
        for (note, offset, duration, velocity) in music {
            var message = MIDINoteMessage(channel: UInt8(channel), note: UInt8(note),
                                          velocity: UInt8(velocity), releaseVelocity: 0,
                                          duration: Float(duration) / Float(tempo))
            
            totalTicks += offset
            let beat = MusicTimeStamp(totalTicks) / tempo
            
            status = MusicTrackNewMIDINoteEvent(track!, beat, &message)
            if status != OSStatus(noErr) {
                print("Error: could not create MIDINoteEvent \(status)")
            }
            
            totalTicks += duration
        }
        
        //CAShow(UnsafeMutablePointer<MusicSequence>(musicSequence!))
        return musicSequence!
    }
    
    func dataFromMusicSequence(_ sequence: MusicSequence) -> Unmanaged<CFData>? {
        var data: Unmanaged<CFData>?
        let status = MusicSequenceFileCreateData(sequence, .midiType, .eraseFile, 480, &data)
        guard status == OSStatus(noErr) else {
            print("Error: could not create data from MusicSequence \(status)")
            return nil
        }
        return data
    }
    
    func createMIDIPlayer(midiData: Data) -> AVMIDIPlayer? {
        guard let url = Bundle.main.url(forResource: soundFont, withExtension: "sf2") else {
            print("Error: could not load \(soundFont)")
            return nil
        }
        
        do {
            let midiPlayer = try AVMIDIPlayer(data: midiData, soundBankURL: url)            
            midiPlayer.prepareToPlay()
            return midiPlayer
        } catch {
            print("Error: could not create AVMIDIPlayer \(error)")
            return nil
        }
    }
}

