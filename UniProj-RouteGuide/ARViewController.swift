import UIKit
import ARKit
import SceneKit
import CoreLocation

class ARViewController: UIViewController, ARSCNViewDelegate, CLLocationManagerDelegate {
    
    var route = Route()
    let locationManager = CLLocationManager()
    var pivot = 0
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var addressText: UITextView!
    @IBOutlet weak var arText: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.distanceFilter = 3
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        
        sceneView.session.run(configuration)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationManager.startUpdatingLocation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
        locationManager.stopUpdatingLocation()
    }
    
    func buildRouteScene(cloestIdx: Int, devLatDeg: Float, devLongDeg: Float) -> SCNScene {
        let scene = SCNScene()
        var startIdx = cloestIdx
        
        if (startIdx != 0) {
            startIdx -= 1
        }
        
        var startPt = transformPtToAR(lat: Float(route.ptsLat![startIdx]), long: Float(route.ptsLong![startIdx]), currentLat: devLatDeg, currentLong: devLongDeg)
        var endPt = transformPtToAR(lat: Float(route.ptsLat![startIdx+1]), long: Float(route.ptsLong![startIdx+1]), currentLat: devLatDeg, currentLong: devLongDeg)
        let newText = String(format: "(%.3f, %.3f), (%.3f, %.3f)", startPt.x, startPt.z, endPt.x, endPt.z)
        arText.text = newText
        
        for i in 0..<route.ptsLat!.count-1 {
            let numOfNode = 5
            
            let incrementX = (endPt.x - startPt.x)/Float(numOfNode - 1)
            let incrementZ  = (endPt.z - startPt.z)/Float(numOfNode - 1)
            for j in 0..<numOfNode {
                let node = SCNNode(geometry: SCNBox(width: 0.3, height: 0.3, length: 0.3, chamferRadius: 0.0))
                let posX = startPt.x + Float(j)*incrementX
                let posZ = startPt.z + Float(j)*incrementZ
                node.position = SCNVector3(x: posX, y: -1.5, z: posZ)
                scene.rootNode.addChildNode(node)
            }
            
            startPt = endPt
            endPt = transformPtToAR(lat: Float(route.ptsLat![startIdx+i+1]), long: Float(route.ptsLong![startIdx+i+1]), currentLat: devLatDeg, currentLong: devLongDeg)
        }
        
        return scene
    }
    
    
    func transformPtToAR(lat: Float, long: Float, currentLat: Float, currentLong: Float) -> (x: Float, z:Float) {
        let objLocation = latLongToMerc(latDeg: lat, longDeg: long)
        let devLocation = latLongToMerc(latDeg: currentLat, longDeg: currentLong)
        let objFinalLocaZ = objLocation.y - devLocation.y;
        let objFinalLocaX = objLocation.x - devLocation.x;
        
        return (x:objFinalLocaX, z:-objFinalLocaZ);
    }
    
    func  latLongToMerc(latDeg: Float, longDeg: Float) -> (x: Float, y: Float){
        let latRad = (latDeg / 180.0 * Float.pi)
        let longRad = (longDeg / 180.0 * Float.pi)
        
        let sm_a:Float = 6378137.0
        let xmeters  = sm_a * longRad
        let ymeters = sm_a * log((sin(latRad) + 1) / cos(latRad))
        return (x:xmeters, y:ymeters)
    }
    
    func getClosestIdx(current: CLLocation, startIdx: Int) -> Int {
        var distance = 999999999.0
        var newDist:Double
        var ptCL:CLLocation
        var index = -1
        
        for i in startIdx..<route.ptsLat!.count-1 { //route.ptsLat!
            ptCL = CLLocation(latitude: route.ptsLat![i], longitude: route.ptsLong![i])
            newDist = current.distance(from: ptCL)
            if ( newDist < distance) {
                distance = newDist
                index = i
            }
            else { break }
        }
        return index
    }
    
    // MARK: - ARSCNViewDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    

    @IBAction func selfDismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
            let firstP = placemarks!.first!
            var currentLocaInfo:String = firstP.name == nil ? "" : (firstP.name! + "\n")
            currentLocaInfo = firstP.thoroughfare == nil ? currentLocaInfo : (currentLocaInfo + firstP.thoroughfare! + ", ")
            currentLocaInfo = firstP.locality == nil ? currentLocaInfo : (currentLocaInfo + firstP.locality! + ", ")
            currentLocaInfo = firstP.administrativeArea == nil ? currentLocaInfo : (currentLocaInfo + firstP.administrativeArea! + ", ")
            currentLocaInfo = firstP.country == nil ? currentLocaInfo : (currentLocaInfo + "\n" + firstP.country!)
            
            if (currentLocaInfo == "") {currentLocaInfo = "Not available."}
            self.addressText.text = currentLocaInfo
        })
        
        let scene = buildRouteScene(cloestIdx: 0, devLatDeg: Float(location.coordinate.latitude), devLongDeg: Float(location.coordinate.longitude))
        sceneView.scene = scene
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[RUNETIME_ERROR] CLLocationManager: \(error)")
    }
}
