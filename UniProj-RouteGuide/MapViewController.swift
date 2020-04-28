import UIKit
import MapKit

class MapViewController:UIViewController {
    
    var route = Route()
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {

        var annotation:MKPointAnnotation
        var annotations = [MKPointAnnotation]()

        for i in 0..<self.route.ptsLat!.count {
            let coord = CLLocationCoordinate2D(latitude: self.route.ptsLat![i], longitude: self.route.ptsLong![i])
            annotation = MKPointAnnotation(__coordinate: coord)
            annotations.append(annotation)
        }


        mapView.addAnnotations(annotations)
        mapView.showAnnotations(annotations, animated: false)
    }
    
    
    @IBAction func selfDismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
