import UIKit
import CoreData
import CoreLocation
import MapKit

class RecordingViewController: UIViewController, CLLocationManagerDelegate {
    
    var savedRoute = Route()
    var originalSavedRoute:Route?
    
    var editingRouteCLs = [CLLocation]()
    var recordedCLs = [CLLocation]()
    var recordedSavedIdxs = [Int]()
    var corrRecordedIdxs = [Int]()
    var editingMissingAfter = [Int]()
    
    var fullRouteNeeded = false
    var reverse:Bool?
    
    var lmAction = ""
    
    var prevCL:CLLocation?
    
    let numOfFullNeeded = 5
    let endPtDistFT = 10.0
    let simDistFT = 2.0
    let diffDistFT = 5.0
    let maxDiffDistFT = 10.0
    
    var testingCount = 0
    var testingPrev = CLLocation()
    
    private let locationManager = CLLocationManager()
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var recordingStatus: UILabel!
    @IBOutlet weak var instruction: UITextView!
    @IBOutlet weak var tryAgainButton: UIButton!
    @IBOutlet weak var stopRecordingButton: UIButton!
    @IBOutlet weak var viewForMap: UIView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
                        
        recordingStatus.text = "Setting Up"
        instruction.text = "Checking current location."
        tryAgainButton.isHidden = true
        stopRecordingButton.isHidden = true
        
        originalSavedRoute = nil
        editingRouteCLs = []
        recordedCLs = []
        recordedSavedIdxs = []
        corrRecordedIdxs = []
        editingMissingAfter = []
        reverse = nil
        prevCL = nil
        
        if (savedRoute.records == nil || savedRoute.records!.count < numOfFullNeeded) {
            fullRouteNeeded = true
        }
                
        var ptCL:CLLocation
        
        for index in 0..<savedRoute.ptsLat!.count {
            ptCL = CLLocation(latitude: savedRoute.ptsLat![index], longitude: savedRoute.ptsLong![index])
            editingRouteCLs.append(ptCL)
        }
                
        if (savedRoute.missingAfter != nil) {
            for index in savedRoute.missingAfter! {
                editingMissingAfter.append(index)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.locationManager.distanceFilter = simDistFT
        findKnownCL()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.allowsBackgroundLocationUpdates = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        testingCount = 0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: func for Recording Process
    
    func findKnownCL() {
        lmAction = "finding"
        locationManager.startUpdatingLocation()
    }
       
    func confirmCL() {
        locationManager.stopUpdatingLocation()
        lmAction = "confirming"
        instruction.text = "Stay at current location for a while."
        locationManager.requestLocation()
    }
    
    func failedConfirmCL() {
        loadingIndicator.stopAnimating()
        instruction.text = "Fail to get your location in recorded route."
        tryAgainButton.isHidden = false
    }
    
    func startRecording() {
        locationManager.distanceFilter = diffDistFT
        lmAction = "recording"
        
        recordingStatus.text = "Recording Now"
        if (fullRouteNeeded) {
            instruction.text = reverse! ? "Please walk towards " + savedRoute.origin!.name! + "." : "Please walk towards " + savedRoute.destination!.name! + "."
        }
        else {
            instruction.text = "Please start walking."
        }
        stopRecordingButton.isHidden = false
        
        locationManager.startUpdatingLocation()
    }
    
    func finishRecording() {
        locationManager.stopUpdatingLocation()
        
        recordingStatus.text = "Processing Record"
        instruction.text = ""
        
        originalSavedRoute = savedRoute
        
        if (reverse!) {
            recordedCLs = recordedCLs.reversed()
            recordedSavedIdxs = recordedSavedIdxs.reversed()
            corrRecordedIdxs = corrRecordedIdxs.reversed()
        }
        
        // Step 1: Improve existing parts
        if (savedRoute.completeness != 0.0) {
            improveExisting()
        }
        
        // Step 2: Improve missing parts
        if (savedRoute.missingAfter != nil && savedRoute.missingAfter!.count > 0) {
            improveMissing()
        }
        
        let alert = UIAlertController(title: "Finished", message: "Would you like to review the th improved route on Map?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: { action in
            self.saveRecord()
        }))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            
            self.stopRecordingButton.isHidden = true
            self.recordingStatus.text = "Generating route on map"
            
            let screenRect = UIScreen.main.bounds
            let screenWidth = screenRect.size.width
            let screenHeight = screenRect.size.height
            
            let mapView = MKMapView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
            
            var annotation:MKPointAnnotation
            var annotations = [MKPointAnnotation]()
                        
            let ptCLsSource = self.savedRoute.records != nil && self.savedRoute.records!.count > 0 ? self.editingRouteCLs : self.recordedCLs
            
            for ptCL in ptCLsSource {
                annotation = MKPointAnnotation(__coordinate: ptCL.coordinate)
                annotations.append(annotation)
            }
            
            mapView.addAnnotations(annotations)
            mapView.showAnnotations(annotations, animated: false)
            
            self.loadingIndicator.stopAnimating()
            self.recordingStatus.isHidden = true
            
            self.viewForMap.addSubview(mapView)
            self.viewForMap.isHidden = false
            self.saveButton.isHidden = false
            self.deleteButton.isHidden = false
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveRecord() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let newRecord = RouteRecord(context: context)
        var latArr = [Double]()
        var longArr = [Double]()
        
        for ptCL in recordedCLs {
            latArr.append(ptCL.coordinate.latitude)
            longArr.append(ptCL.coordinate.longitude)
        }
        
        newRecord.ptsLat = latArr
        newRecord.ptsLong = longArr
        newRecord.route = self.savedRoute 
        
        let firstRecord = savedRoute.records!.count == 1 ? true : false
        var targetCLs:[CLLocation]
        
        if (firstRecord) {
            targetCLs = recordedCLs
        }
            
        else {
            latArr.removeAll()
            longArr.removeAll()
            for ptCL in editingRouteCLs {
                latArr.append(ptCL.coordinate.latitude)
                longArr.append(ptCL.coordinate.longitude)
            }
            
            targetCLs = editingRouteCLs
        }
        
        let missings = getMissingParts(ptCLs: targetCLs)
        
        let completeness = Float(targetCLs.count - 1 - missings.count) / Float(targetCLs.count - 1)
        
        savedRoute.ptsLat = latArr
        savedRoute.ptsLong = longArr
        savedRoute.missingAfter = missings
        savedRoute.completeness = completeness
        savedRoute.localDistance = getTotalDistance(startIdx: 0, endIdx: targetCLs.count-1, ptCLs: targetCLs)
        
        var newRoute = Route()
        
        do {
            try context.save()
            
            let fetchRouteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Route")
            fetchRouteRequest.predicate = NSPredicate(format: "id == %d", savedRoute.id)
            let fetchRouteResult = try context.fetch(fetchRouteRequest)
            newRoute = fetchRouteResult[0] as! Route
            
            let records = (fetchRouteResult[0] as! Route).records
        } catch let error {
            print("[RUNTIME_ERROR] \(error)")
        }
        
        let presenter = presentingViewController!.children[1].children[1] as! RouteDetailTableVC
        presenter.route = newRoute
        
        self.dismiss(animated: true, completion: presenter.configureTable)
    }
    
    // MARK: Common Helper Func
    
    func insertPtsAfter(ptCLs: [CLLocation], insertAt: Int, idxMissingIdx: Int) {
        
        for (index, ptCL) in ptCLs.enumerated() {
            editingRouteCLs.insert(ptCL, at: insertAt+index)
        }
    }
    
    func getTotalDistance(startIdx: Int, endIdx: Int, ptCLs: [CLLocation]) -> Double {
        var totalDist = 0.0
        
        for i in startIdx..<endIdx {
            let distance =  ptCLs[i+1].distance(from : ptCLs[i])
            totalDist += distance
        }
        
        return totalDist
    }
    
    func getMissingParts(ptCLs: [CLLocation]) -> [Int] {
        var missings = [Int]()
        
        for i in 0..<ptCLs.count-1 {
            let distance = ptCLs[i].distance(from: ptCLs[i+1])
            if (distance > maxDiffDistFT) {
                missings.append(i)
            }
        }
        
        return missings
    }
    
    func getClosestCLToCL(ptCL: CLLocation, routeCLs: [CLLocation]) -> Int {
        var distance:Double
        var shortestDistance:Double = savedRoute.localDistance
        var cloestPtIdx = 0
        
        for (index, routeCL) in routeCLs.enumerated() {
            distance = routeCL.distance(from: ptCL)
            if (distance < shortestDistance) {
                shortestDistance = distance
                cloestPtIdx = index
            }
        }
        
        return cloestPtIdx
    }
    
    func getClosestCLDist(ptCL: CLLocation) -> (dist: Double, idx: Int) {
        var distance:Double = ptCL.distance(from: editingRouteCLs[0])
        var newDistance:Double
        var targetCLIdx = 0
        
        if (fullRouteNeeded) {
            newDistance = ptCL.distance(from: editingRouteCLs[editingRouteCLs.count-1])
            if (newDistance < distance) {
                distance = newDistance
                targetCLIdx = 1
            }
        }
            
        else {
            for i in 0..<editingRouteCLs.count-1 {
                newDistance = ptCL.distance(from: editingRouteCLs[i])
                if ( newDistance < distance) {
                    distance = newDistance
                }
                else { break }
            }
        }
        
        return (dist:distance, idx:targetCLIdx)
    }
    
    func collectSavedCLNearby(location: CLLocation, idxOfLocation: Int) {
        let recordedSavedCLIdx = recordedSavedIdxs.last!
        let maxIdx = editingRouteCLs.count - 1
        
        var count = reverse! ? recordedSavedCLIdx : editingRouteCLs.count - recordedSavedCLIdx - 1
        let increment = reverse! ? -1 : 1
        var index = recordedSavedCLIdx + increment
        
        while (count > 0 && index < maxIdx) {
            let ptCL = editingRouteCLs[index]
            
            let distance = location.distance(from: ptCL)
            
            if (distance < simDistFT) {
                recordedSavedIdxs.append(index) //original: recordedSavedIdxs[recordedSavedIdxs.count-1] = index
                corrRecordedIdxs.append(idxOfLocation)
                return
            }
            index = index + increment
            count-=1
        }
    }
    
    // MARK: func for Existing
    
    func improveExisting() {
        for i in 0..<recordedSavedIdxs.count-1 {
            let savedRangeStart = recordedSavedIdxs[i]
            let savedRangeEnd = recordedSavedIdxs[i+1]
            let recordedRangeStart = corrRecordedIdxs[i]
            let recordedRangeEnd = corrRecordedIdxs[i+1] // e.g. (i = 1, j = 0) 8
            
            let totalSavedDist = getTotalDistance(startIdx: savedRangeStart, endIdx: savedRangeEnd, ptCLs: editingRouteCLs)
            let totalReDist = getTotalDistance(startIdx: recordedRangeStart, endIdx: recordedRangeEnd, ptCLs: recordedCLs)
            
            if (totalSavedDist < totalReDist) {
                continue
            }
            
            var totalSavedDistWithSaved = totalSavedDist
            var totalReDistWithSaved = totalReDist
            
            if ( savedRangeStart != 0 ) {
                totalSavedDistWithSaved += editingRouteCLs[savedRangeStart-1].distance(from : editingRouteCLs[savedRangeStart])
                totalReDistWithSaved += editingRouteCLs[savedRangeStart-1].distance(from : recordedCLs[recordedRangeStart])
            }
            
            if ( savedRangeEnd != editingRouteCLs.count-1 ) {
                totalSavedDistWithSaved += editingRouteCLs[savedRangeEnd+1].distance(from : editingRouteCLs[savedRangeEnd])
                totalReDistWithSaved += editingRouteCLs[savedRangeEnd+1].distance(from : recordedCLs[recordedRangeEnd])
            }
            
            if (totalReDistWithSaved < totalSavedDistWithSaved) {
                let oldLength = editingRouteCLs.count
                let recordedSlicedArr = Array(recordedCLs[recordedRangeStart...recordedRangeEnd])

                editingRouteCLs.replaceSubrange(savedRangeStart...savedRangeEnd, with: recordedSlicedArr)
                
                let newLength = editingRouteCLs.count
                
                for (i, idx) in recordedSavedIdxs.enumerated() {
                    if (idx > savedRangeStart) {
                        recordedSavedIdxs[i] += ( newLength - oldLength)
                    }
                }
                
                for (i, idx) in editingMissingAfter.enumerated() {
                    if (idx > savedRangeStart) {
                        editingMissingAfter[i] += ( newLength - oldLength)
                    }
                }
            }
        }
    }
    
    // MARK: func for Missing
    
    func improveMissing() {
        let startSavedIdx = recordedSavedIdxs[0]
        let endSavedIdx = recordedSavedIdxs.last!
        var added:Int = 0
        
        for (index, missingPtIdx) in editingMissingAfter.enumerated() {
            if ( missingPtIdx >= startSavedIdx && missingPtIdx < endSavedIdx ) {
                let  closestStartMissing:Int = getClosestCLToCL(ptCL: editingRouteCLs[missingPtIdx], routeCLs:recordedCLs)
                let closestEndMissing:Int = getClosestCLToCL(ptCL: editingRouteCLs[missingPtIdx+1], routeCLs:recordedCLs)
                
                let closestNewStart:Int = getClosestCLToCL(ptCL: recordedCLs[closestStartMissing], routeCLs:editingRouteCLs)
                let closestNewEnd:Int = getClosestCLToCL(ptCL: recordedCLs[closestStartMissing+1], routeCLs:editingRouteCLs)
                let missingStartCL:CLLocation = editingRouteCLs[missingPtIdx]
                let missingEndCL:CLLocation = editingRouteCLs[missingPtIdx+1]
                
                if (closestStartMissing == closestEndMissing) {
                    let newCL:CLLocation = recordedCLs[closestStartMissing]
                    let distNewToStart = missingStartCL.distance(from: newCL)
                    let distNewToEnd = missingEndCL.distance(from: newCL)
                    
                    if (distNewToStart < maxDiffDistFT && distNewToEnd < maxDiffDistFT) {
                        let ptCLArr = [recordedCLs[closestStartMissing]]
                        insertPtsAfter(ptCLs: ptCLArr, insertAt: missingPtIdx+1, idxMissingIdx: index)
                        added += 0
                    }
                    continue
                }
                    
                else {
                    if ( closestNewStart == missingPtIdx ) {
                        
                        let newStartCL:CLLocation = recordedCLs[closestStartMissing]
                        let distStartToEnd = missingEndCL.distance(from: missingStartCL)
                        let distNewToEnd = missingEndCL.distance(from: newStartCL)
                        
                        if (distNewToEnd < maxDiffDistFT) {
                            let ptCLArr = [recordedCLs[closestStartMissing]]
                            insertPtsAfter(ptCLs: ptCLArr, insertAt: missingPtIdx+1, idxMissingIdx: index)
                            added+=1
                        }
                    }
                    
                    if ( closestNewEnd == missingPtIdx+1 ) { // both of them are closest to each other
                        let newEndCL:CLLocation = recordedCLs[closestEndMissing]
                        
                        let distEndToStart = missingStartCL.distance(from: missingEndCL)
                        let distNewToStart = missingStartCL.distance(from: newEndCL)
                        
                        if (distNewToStart < maxDiffDistFT) {
                            let ptCLArr = [recordedCLs[closestEndMissing]]
                            insertPtsAfter(ptCLs: ptCLArr, insertAt: missingPtIdx+added+1, idxMissingIdx: index)
                            added+=1
                        }
                    }
                    
                    let numOfPtsInbetween = (closestNewEnd - closestNewStart) - 1

                    if (numOfPtsInbetween > 0) {
                        let ptCLsArr = Array(recordedCLs[(closestNewStart+1)..<closestNewEnd])

                        insertPtsAfter(ptCLs: ptCLsArr, insertAt: missingPtIdx+added+1, idxMissingIdx: index)
                        added+=numOfPtsInbetween
                    }
                }
                
                if (added > 0) {
                    for i in (index+1)..<editingMissingAfter.count {
                        let old = editingMissingAfter[i]
                        editingMissingAfter[i] = old + added
                    }
                }
                
                added = 0
            }
        }
    }
    
    // MARK: IBAction func
    
    @IBAction func tryAgain(_ sender: Any) {
        tryAgainButton.isHidden = true
        loadingIndicator.startAnimating()
        findKnownCL()
    }
    
    @IBAction func stopRecording(_ sender: Any) {
        let actionAlert = UIAlertController(title: "Stop Recording", message: "Please Select an Option.", preferredStyle: .alert)
        actionAlert.addAction(UIAlertAction(title: "Finish and Save", style: .default, handler: { action in
            self.checkBeforeFinish()
        }))
        actionAlert.addAction(UIAlertAction(title: "Got Wrong Route", style: .default, handler: { action in
            let alert = UIAlertController(title: "Warning", message: "Are you sure to quit recording?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                self.locationManager.stopUpdatingLocation()
                self.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        }))
        actionAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        self.present(actionAlert, animated: true, completion: nil)
    }
    
    
    @IBAction func saveFromMap(_ sender: Any) {
        saveRecord()
    }
    
    @IBAction func deleteFromMap(_ sender: Any) {
        let alert = UIAlertController(title: "Warning", message: "Are you sure to remove the improvement?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .default))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            self.dismiss(animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func checkBeforeFinish() {
        if (fullRouteNeeded) {
            let endPointStr:String = (reverse! ? savedRoute.origin!.name : savedRoute.destination!.name)!
            let endPointCL:CLLocation = reverse! ? editingRouteCLs[0] : editingRouteCLs.last!
            let distance:Double = recordedCLs.last!.distance(from: endPointCL)
            let message = String(format: "You are %.2f metres away from %@.", distance, endPointStr)
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
            
        else if (recordedSavedIdxs.count >= 2) {
            let lastFoundSaveCL = editingRouteCLs[recordedSavedIdxs.last!]
            for (index, recordedCL) in recordedCLs.enumerated() {
                let distance = recordedCL.distance(from: lastFoundSaveCL)
                if (distance < simDistFT) {
                    recordedCLs = Array(recordedCLs[...index])
                    finishRecording()
                    return
                }
            }
        }
        
        let alert = UIAlertController(title: "Error", message: "The recorded route is too short.\nPlease keep oging.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: func for Delegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let distToO = location.distance(from: editingRouteCLs[0])
        let distToD = location.distance(from: editingRouteCLs[editingRouteCLs.count - 1])
        
        switch lmAction {
            
        case "finding":
            prevCL = location
            
            
            if (distToO < endPtDistFT) {
                recordedCLs.append(editingRouteCLs[0])
                recordedSavedIdxs.append(0)
                corrRecordedIdxs.append(0)
                reverse = false
                startRecording()
                return
            }
            
            if (distToD < endPtDistFT) {
                recordedCLs.append(editingRouteCLs[editingRouteCLs.count - 1])
                recordedSavedIdxs.append(editingRouteCLs.count - 1)
                corrRecordedIdxs.append(recordedCLs.count - 1)
                reverse = true
                startRecording()
                return
            }
            
            let distNIdx = getClosestCLDist(ptCL: location)
            var name = ""
            if ( fullRouteNeeded ) {
                name = distNIdx.idx == 0 ? savedRoute.origin!.name! : savedRoute.destination!.name!
            }
            instruction.text = fullRouteNeeded ? String(format: "You are %.2f metres away from %@.", distNIdx.dist, name) : String(format: "You are %.2f metres away from the closest recorded point.", distNIdx.dist)
            
        case "recording":
            collectSavedCLNearby(location: location, idxOfLocation: recordedCLs.count) // no -1 to count bc it has not been appended to recordedCLs
            
            if (reverse! && distToO < endPtDistFT) {
                recordedCLs.append(editingRouteCLs[0])
                recordedSavedIdxs.append(0)
                corrRecordedIdxs.append(0)
                finishRecording()
                return
            }
            
            if (!reverse! && distToD < endPtDistFT) {
                recordedCLs.append(editingRouteCLs[editingRouteCLs.count - 1])
                recordedSavedIdxs.append(editingRouteCLs.count - 1)
                corrRecordedIdxs.append(recordedCLs.count - 1)
                finishRecording()
                return
            }
            
            let distance = location.distance(from: prevCL!)
            if (distance > diffDistFT) {
                print(String(format: "[DEV_LOG] Recognize a valid point to recordedCLs with dist:  %.3f", distance))
                recordedCLs.append(location)
            }
            prevCL = location
            
        default:
            print("[RUNTIME_ERROR] No appropriate action for loacation manager")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[RUNETIME_ERROR] CLLocationManager: \(error)")
    }
}
