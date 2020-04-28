import UIKit
import MapKit
import CoreData
import CoreLocation

class RouteDetailTableVC: UITableViewController {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var route = Route()

    @IBOutlet weak var routeOrigin: UILabel!
    @IBOutlet weak var routeDestination: UILabel!
    @IBOutlet weak var routeCompleteness: UILabel!
    @IBOutlet weak var routeProgress: UIProgressView!
    @IBOutlet weak var routeDistance: UILabel!
    @IBOutlet weak var routeServerDistance: UILabel!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var viewButton: UIButton!
    @IBOutlet weak var viewImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewImage.image = UIImage(data: route.image!)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(self.confirmDelete))
        
        submitButton.addTarget(self, action: #selector(self.confirmRecording), for: .touchUpInside)
        
        configureTable()
    }
    
    @objc func confirmDelete(sender:UIBarButtonItem) {
        let alert = UIAlertController(title: "Warning", message: "Are you sure to delete this route?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .default))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            self.deleteThisRoute()
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func configureTable() {
        self.tabBarController?.tabBar.isHidden = true
                
        routeOrigin.text = route.origin!.name
        routeDestination.text = route.destination!.name
        routeCompleteness.text = String(format: "%.1f %%", route.completeness*100)
        routeProgress.progress = route.completeness
        routeDistance.text = String(format: "%.2f metres", route.localDistance)
        routeServerDistance.text = String(format: "%.2f metres", route.serverDistance)

    }
    
    func deleteThisRoute() {
        do {
            context.delete(route)
            try context.save()
            
            let fetchRouteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Route")
            let fetchRouteResult = try context.fetch(fetchRouteRequest)
            let routeCount = fetchRouteResult.count
        } catch let error {
            print("[RUNTIME_ERROR] \(error)")
        }
    }
    
    @objc func confirmRecording(sedner: UIButton) {
        
        var question:String
        
        if (route.records == nil || route.records!.count < 3) {
            question = "Are you at the origin or destination now?"
        }
        else {
            question = "Are you ready to record missing points?"
        }
        
        let alert = UIAlertController(title: "Reminder", message: question, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .default))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            self.readyToRecord()

        }))
        self.present(alert, animated: true, completion: nil)
    }
       
    func readyToRecord() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        
        let recordingVC = storyBoard.instantiateViewController(withIdentifier: "recording") as! RecordingViewController
        recordingVC.savedRoute = route
        self.present(recordingVC, animated:true, completion:nil)
    }

    @IBAction func showViewOptions(_ sender: UIButton) {
        let actionAlert = UIAlertController(title: "View Options", message: "Please Select an Option.", preferredStyle: .alert)
        actionAlert.addAction(UIAlertAction(title: "View on Map", style: .default, handler: { action in
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)

            let mapViewCL = storyBoard.instantiateViewController(withIdentifier: "mapViewCL") as! MapViewController
            mapViewCL.route = self.route
            
            self.present(mapViewCL, animated: true, completion: nil)
        }))
        actionAlert.addAction(UIAlertAction(title: "View with AR", style: .default, handler: { action in
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)

            let arViewCL = storyBoard.instantiateViewController(withIdentifier: "arViewCL") as! ARViewController
            arViewCL.route = self.route
            
            self.present(arViewCL, animated: true, completion: nil)
        }))
        actionAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        self.present(actionAlert, animated: true, completion: nil)
    }
}
