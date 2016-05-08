//
//  MainScene.swift
//  VRMusicRoom
//
//  Created by Nathan Flurry on 5/5/16.
//  Copyright © 2016 Nathan Flurry. All rights reserved.
//

import SceneKit
import SpriteKit
import CoreMotion
import AVFoundation

class MainScene: VRScene {
    // Defines if the
    var triggering: Bool = false {
        willSet(value) {
            // Reset previous looked node if not triggering anymore
            if !value {
                previousLookedNode = nil
            }
        }
    }
    
    // Nodes that were looked at in the last frame
    var previousLookedNode: SCNNode? = nil
    
    // The focus
    var focusNode: SCNNode?
    var focusNodeParent: SCNNode?
    
    // The sounds for nodes (node name, sound name
    let nodeSounds: [String: String] = [
        // Drumset (from http://www.soundjig.com/pages/soundfx/drums.html )
        "bass-drum": "bass-drum",
        "crash": "crash",
        "ride": "ride",
        "hi-hat": "hi-hat-open",
        "cow-bells": "cow-bell",
        "drum-left": "snare-drum-closed",
        "drum-middle-left": "snare-drum-open",
        "drum-middle-right": "snare-drum-open",
        "drum-right": "snare-drum-open"
    ]
    var nodeSoundSources: [SCNNode: AVAudioPlayer] = [:]
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func vrSceneReady() {
        // Load the url and scene source for the scene
        do {
            if let url = NSBundle.mainBundle().URLForResource("art.scnassets/Main", withExtension: "scn"),
                sceneSource = SCNSceneSource(URL: url, options: nil) {
                do {
                    // Get the scene
                    let scene = try sceneSource.sceneWithOptions(nil)
                    
                    // Move all children to this node
                    for child in scene.rootNode.childNodes {
                        rootNode.addChildNode(child)
                    }
                } catch {
                    print("There was an error loading the scene.\n\(error)")
                    return
                }
            } else {
                print("Could not get url or scene source for main scene.")
                return
            }
        }
        
        // Add sounds to all of the nodes
        for (nodeName, soundName) in nodeSounds {
            // Get the node
            guard let node = rootNode.childNodeWithName(nodeName, recursively: true) else {
                print("No node with name \"\(nodeName)\" exists.")
                continue
            }
            
//            // Create the source and load it
//            guard let source = SCNAudioSource(fileNamed: soundName + "mp3") else { // TODO: Fix SCNAudioSource
//                print("No sound with name \"\(soundName)\" exists.")
//                continue
//            }
            
            // Add a player to the node
            do {
                if let soundURL = NSBundle.mainBundle().URLForResource(soundName, withExtension: "mp3") {
                    nodeSoundSources[node] = try AVAudioPlayer(contentsOfURL: soundURL)
                } else {
                    print("No audio player for sound \(soundName)")
                }
            } catch {
                print("shit it didn't work")
            }
        }
        
        // Create the focus node
        do {
            // Create the geometry
            let focusGeometry = SCNSphere(radius: 0.2)
            focusGeometry.firstMaterial?.emission.contents = UIColor.whiteColor() // Make it always white
            focusGeometry.firstMaterial?.readsFromDepthBuffer = false // Ignore other objects' positions
            
            // Create the node
            focusNode = SCNNode(geometry: focusGeometry)
            focusNode?.renderingOrder = 1 // Draw in front of everything else
            focusNode?.position.z = -20 // Move out in front of the camera
            focusNodeParent?.castsShadow = false
            
            // Create the parent
            focusNodeParent = SCNNode() // Create the focus node's parent which contains the position and rotation
            focusNodeParent?.addChildNode(focusNode!) // Can't child under camera becaue it doesn't appear for some reason
            rootNode.addChildNode(focusNodeParent!)
        }

        // Animate the ship rotating
        do {
            // Retrieve the ship node
            let ship = rootNode.childNodeWithName("ship", recursively: true)!
            
            // Animate the 3d object
            ship.runAction(SCNAction.repeatActionForever(SCNAction.rotateByX(0, y: 2, z: 0, duration: 1)))
        }
    }
    
    // Called every frame
    func updateFocusTransform() {
        focusNodeParent?.position = camera.position
        focusNodeParent?.rotation = camera.cameraParent.rotation
    }
    
    // Called every frame
    func executeHitTest() {
        // Check if triggering
        guard triggering else {
            return
        }
        
        // Get the results
        let results = rootNode.hitTestWithSegmentFromPoint( // TODO: Fix this
            camera.position,
            toPoint: focusNode!.convertPosition(SCNVector3(), toNode: rootNode),
            options: nil
        )
        
        // Check there's actually any nodes
        guard results.count > 0 else {
            previousLookedNode = nil
            return
        }
        
        // Get the first result
        let result = results[0]
        let node = result.node
        
        // Check if it's a new node that was looked at
        if node != previousLookedNode {
            if let audioSource = nodeSoundSources[node] {
                // Play the node's audio
//                rootNode.runAction(SCNAction.playAudioSource(audioSource, waitForCompletion: false))
                audioSource.currentTime = 0
                audioSource.play()
            }
            
            // Save to previous looked node
            previousLookedNode = node
        }
    }
}
