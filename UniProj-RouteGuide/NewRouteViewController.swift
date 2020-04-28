import UIKit
import CoreData

class NewRouteViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var hotspots = [Hotspot]()
    var origins = [Hotspot]()
    var destinations = [Hotspot]()
    var originNameList = [String]()
    var destinationNameList = [String]()
    var previousSelectedOrigin:Int?
    var selectedOrigin:Int?
    var selectedDestination:Int?
    
    @IBOutlet weak var originTextField: UITextField!
    @IBOutlet weak var destinationTextField: UITextField!
    
    let locationPickerView = UIPickerView()
    var currentTextField:UITextField?
    
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Hotspot")
    
    override func viewWillAppear(_ animated: Bool) {
        do {
            let fetchResult = try context.fetch(fetchRequest)
            
            hotspots = fetchResult as! [Hotspot]
            
            for hotspot in hotspots {
                
                if (hotspot.availableDests != nil) {
                    origins.append(hotspot)
                }
            }
            
            for origin in origins {
                originNameList.append(origin.name!)
            }
            
            print("[DEV_LOG] originNameList: \(originNameList)")
            
        }catch let error{
            print("[RUNTIME_ERROR] \(error)")
        }
        
        if (origins.count == 0) {
            originTextField.isEnabled = false
            originTextField.placeholder = "No origin available."
            destinationTextField.placeholder = "No destintaion available."
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        originTextField.delegate = self
        destinationTextField.delegate = self
        locationPickerView.delegate = self
        
        currentTextField = originTextField
        
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        let button = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.endEditing))
        toolBar.setItems([button], animated: true)
        toolBar.isUserInteractionEnabled = true
        originTextField.inputAccessoryView = toolBar
        destinationTextField.inputAccessoryView = toolBar
        originTextField.inputView = locationPickerView
        destinationTextField.inputView = locationPickerView
        // Do any additional setup after loading the view.
    }
    
    func getRouteImage(selectedOrigin: Int) -> UIImage {
        var targetImg = UIImage()
        switch selectedOrigin {
        case 0:
            targetImg = UIImage(named: "routeImg1.jpg")!
        case 1:
            targetImg = UIImage(named: "routeImg2.jpg")!
        case 2:
            targetImg = UIImage(named: "routeImg3.jpg")!
        default:
            print("[RUNTIME_ERROR] No sutiable image for route.")
        }
        return targetImg
    }
    
    @objc func endEditing(){
        currentTextField!.endEditing(true)
        
        if (currentTextField == originTextField) {
            if (selectedOrigin != previousSelectedOrigin){
                destinations.removeAll()
                destinationNameList.removeAll()
                for destIndex in origins[selectedOrigin!].availableDests! {
                    for hotspot in hotspots {
                        if (hotspot.id == destIndex) {
                            destinations.append(hotspot)
                            destinationNameList.append(hotspot.name!)
                        }
                        
                    }
                }
            }
            
            if (!destinationTextField.isEnabled) {
                destinationTextField.isEnabled = true
            }
            
            previousSelectedOrigin = selectedOrigin
        }
    }
    
    @IBAction func saveNewRoute(_ sender: Any) {
        
        if (selectedOrigin == nil) {
            let alert = UIAlertController(title: "Input Error", message: "No selected origin.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if (selectedDestination == nil) {
            let alert = UIAlertController(title: "Input Error", message: "No selected destination.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Route")
        
        do {
            let fetchResult = try context.fetch(fetchRequest)
            
            var ptsLat = [Double]()
            var ptsLong = [Double]()
            
            ptsLat.append(origins[selectedOrigin!].latitude)
            ptsLat.append(destinations[selectedDestination!].latitude)
            ptsLong.append(origins[selectedOrigin!].longitude)
            ptsLong.append(destinations[selectedDestination!].longitude)
            
            let newRoute = Route(context: context)
            
            newRoute.id = fetchResult.last == nil ? 0 : (fetchResult.last as! Route).id + 1
            newRoute.origin = origins[selectedOrigin!]
            newRoute.destination = destinations[selectedDestination!]
            newRoute.completeness = 0.0
            newRoute.localDistance = 0.0
            newRoute.serverDistance = origins[selectedOrigin!].distanceToDests![selectedDestination!]
            newRoute.ptsLat = ptsLat
            newRoute.ptsLong = ptsLong
            newRoute.image = getRouteImage(selectedOrigin: selectedOrigin!).jpegData(compressionQuality: 1.0)
            try context.save()
            
            print("[RUNTIME_LOG] New route saved: \(newRoute)")

            self.dismiss(animated: true)
        }catch let error{
            print("[RUNTIME_ERROR] \(error)")
        }
    }
    
    @IBAction func cancelAddRoute(_ sender: Any) {
        print("[RUNTIME_LOG] Button clicked: Cancel AddRoute")
        self.dismiss(animated: true)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
     
        if (currentTextField == originTextField){
            return originNameList.count
        }
            
        else if (currentTextField == destinationTextField) {
            return destinationNameList.count
        }
            
        else { return 0 }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {

        if (currentTextField == originTextField){
            return originNameList[row]
        }
            
        else if (currentTextField == destinationTextField) {
            return destinationNameList[row]
        }
            
        else { return "No hotspot available." }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if (currentTextField == originTextField){
            currentTextField!.text = originNameList[row]
            selectedOrigin = row
        }
            
        else if (currentTextField == destinationTextField) {
            currentTextField!.text = destinationNameList[row]
            selectedDestination = row
        }
            
        else { currentTextField!.text = "No hotspot available." }
        
    }
    
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        currentTextField = textField
        return true
    }
}
