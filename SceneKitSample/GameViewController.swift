//
//  GameViewController.swift
//  SceneKitSample
//
//  Created by 坪内 征悟 on 2017/06/25.
//  Copyright © 2017年 Masanori. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import MapKit
import CoreLocation

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene()
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 10, z: 15)
        cameraNode.rotation = SCNVector4(1, 0, 0, -0.2 * Float.pi)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // create a cube node
        let cubeGeometry = self.cubeGeometry()
        let cubeNode = SCNNode(geometry: cubeGeometry)
        cubeNode.position = SCNVector3(x: 0, y: Float(cubeGeometry.height / 2), z: 0)
        scene.rootNode.addChildNode(cubeNode)
        
        // animate the 3d object
        cubeNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
        
        // create a map image plane node
        setupLocation()
        createMapImagePlane()
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    // MARK: - Cube
    
    private func cubeGeometry() -> SCNBox {
        let cubeGeometry = SCNBox(width: 2.0, height: 2.0, length: 2.0, chamferRadius: 0.0)
        // create cube textures
        let frontMaterial = SCNMaterial()
        let font = UIFont.boldSystemFont(ofSize: 20)
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineBreakMode = .byClipping
        let shadow = NSShadow()
        shadow.shadowOffset = CGSize(width: 0.5, height: 0.5)
        shadow.shadowColor = UIColor.darkGray
        shadow.shadowBlurRadius = 0
        let attributes = [
            NSAttributedStringKey.font: font,
            NSAttributedStringKey.paragraphStyle: style,
            NSAttributedStringKey.shadow: shadow,
            NSAttributedStringKey.foregroundColor: UIColor.black,
            NSAttributedStringKey.backgroundColor: UIColor.white]
        let frontString = "前" as NSString
        let frontImage = frontString.image(with: attributes,
                                           at: CGRect(origin: CGPoint.zero, size: CGSize(width: 20, height: 24)))
        frontMaterial.diffuse.contents = frontImage
        
        let backMaterial = SCNMaterial()
        backMaterial.diffuse.contents = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        let leftMaterial = SCNMaterial()
        leftMaterial.diffuse.contents = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
        let rightMaterial = SCNMaterial()
        rightMaterial.diffuse.contents = #colorLiteral(red: 0.9994240403, green: 0.9855536819, blue: 0, alpha: 1)
        let topMaterial = SCNMaterial()
        topMaterial.diffuse.contents = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        let bottomMaterial = SCNMaterial()
        bottomMaterial.diffuse.contents = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
        
        cubeGeometry.materials = [frontMaterial, rightMaterial, backMaterial, leftMaterial, topMaterial, bottomMaterial]
        return cubeGeometry
    }
    
    // MARK: - Location
    
    private var locationManager: CLLocationManager?
    
    private func setupLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.startUpdatingLocation()
        }
    }
    
    // MARK: - Map
    
    private func createMapImagePlane() {
        let options = MKMapSnapshotOptions()
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let centerCoordinate: CLLocationCoordinate2D
        if let coordinate = locationManager?.location?.coordinate {
            centerCoordinate = coordinate
        } else {
            centerCoordinate = CLLocationCoordinate2DMake(35.702069, 139.775327) // 東京駅
        }
        options.region = MKCoordinateRegionMake(centerCoordinate, span)
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start(with: DispatchQueue.global(), completionHandler: { (snapshot, error) in
            DispatchQueue.main.async {
                guard let image = snapshot?.image, let scnView = self.view as? SCNView, let scene = scnView.scene else {
                    return
                }
                let mapGeometry = SCNPlane(width: image.size.width/20, height: image.size.height/20)
                let mapMaterial = SCNMaterial()
                mapMaterial.diffuse.contents = image
                mapGeometry.firstMaterial = mapMaterial
                let mapNode = SCNNode(geometry: mapGeometry)
                mapNode.position = SCNVector3(x: 0, y: 0, z: 0)
                mapNode.rotation = SCNVector4(1, 0, 0, -0.5 * Float.pi) // x軸で-90度回転(奥に倒す感じ)
                scene.rootNode.addChildNode(mapNode)
                
                // 地図の裏面をグレーにする
                let frontGeometry = SCNPlane(width: mapGeometry.width, height: mapGeometry.height)
                let frontMaterial = SCNMaterial()
                frontMaterial.cullMode = .front
                frontMaterial.diffuse.contents = #colorLiteral(red: 0.7233663201, green: 0.7233663201, blue: 0.7233663201, alpha: 1)
                frontGeometry.firstMaterial = frontMaterial
                let frontNode = SCNNode(geometry: frontGeometry)
                frontNode.position = mapNode.position
                frontNode.position.y -= 0.01 // 完全に重なるとブレるため、ちょっと下にずらす
                frontNode.rotation = mapNode.rotation
                scene.rootNode.addChildNode(frontNode)
            }
        })
    }
}

// MARK: - CLLocationManagerDelegate
extension GameViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways, .authorizedWhenInUse:
            break
        }
    }
}

// MARK: - NSString
extension NSString {
    func image(with attributes: [NSAttributedStringKey: Any]? = nil, at rect: CGRect) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        self.draw(in: rect, withAttributes: attributes)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
