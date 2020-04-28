import UIKit
import CoreData

class SearchViewController: UIViewController {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func saveToDatabase(_ sender: Any) {
        
        let newHotspot1 = Hotspot(context: context)
        newHotspot1.id = 1
        newHotspot1.name = "Kowloon Tong MTR Exit C1"
        newHotspot1.latitude = 22.337010
        newHotspot1.longitude = 114.175410
        
        let newHotspot2 = Hotspot(context: context)
        newHotspot2.id = 2
        newHotspot2.name = "CityU Main Entrance"
        newHotspot2.latitude = 22.336730
        newHotspot2.longitude = 114.174355
                
        
        // MARK: For every server route, set the route points be each other's origin and destination.
        newHotspot1.availableDests = [2]
        newHotspot1.distanceToDests = [0.0]

        do {
            try context.save()
        } catch let error {
            print("[RUNTIME_ERROR] \(error)")
        }
    }
    
    @IBAction func clearHotspots(_ sender: Any) {
        do {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Hotspot")
            
            var fetchResult = try context.fetch(fetchRequest)
            var count = fetchResult.count
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(deleteRequest)
            
            fetchResult = try context.fetch(fetchRequest)
            count = fetchResult.count
            
        } catch let error {
            print("[RUNTIME_ERROR] \(error)")
        }
    }
    
    @IBAction func clearDatabase(_ sender: Any) {
        do {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Route")
            
            var fetchResult = try context.fetch(fetchRequest)
            var count = fetchResult.count
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(deleteRequest)
            
            fetchResult = try context.fetch(fetchRequest)
            count = fetchResult.count
        } catch let error {
            print("[RUNTIME_ERROR] \(error)")
        }
    }
    
    @IBAction func clearRecords(_ sender: Any) {
        do {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "RouteRecord")
            
            var fetchResult = try context.fetch(fetchRequest)
            for result in fetchResult {
                let routeRecord = result as! RouteRecord
                routeRecord.route!.completeness = 0.0
                routeRecord.route!.missingAfter = nil
            }
            var count = fetchResult.count
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(deleteRequest)
            
            fetchResult = try context.fetch(fetchRequest)
            count = fetchResult.count
            
        } catch let error {
            print("[RUNTIME_ERROR] \(error)")
        }
    }
    
}
