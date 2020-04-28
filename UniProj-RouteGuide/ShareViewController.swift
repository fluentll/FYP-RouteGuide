import UIKit
import CoreData

class ShareViewController: UIViewController {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var routes = [Route]()

    @IBOutlet weak var scrollView: UIScrollView!
    
    let screenSize:CGRect = UIScreen.main.bounds
    let scrollViewTopInset:CGFloat = 20
    let scrollViewBottomInset:CGFloat = 25
    let buttonSpacing:Int = 30
    let buttonWidth:Int = 340
    let buttonHeight:Int = 210
    
    override func viewWillAppear(_ animated: Bool) {
        do {
            let fetchRecordRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "RouteRecord")
            let records = try context.fetch(fetchRecordRequest) as! [RouteRecord]
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Route")
            routes = try context.fetch(fetchRequest) as! [Route]
            
            if (scrollView.subviews.count > 0) {
                scrollView.subviews.forEach({ $0.removeFromSuperview() })
            }
            
            var count = 0
            for route in routes {
                let button = createRouteButton(route: route, index: count)
                scrollView.addSubview(button)
                count += 1
            }
            
            scrollView.contentSize = CGSize(width: screenSize.width, height: CGFloat(count*(buttonHeight+buttonSpacing)))
            
        }catch let error {
                print("[RUNTIME_ERROR] \(error)")
        }
        
        if ((self.tabBarController?.tabBar.isHidden)!) {
            self.tabBarController?.tabBar.isHidden = false
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.contentInset = UIEdgeInsets(top: scrollViewTopInset, left: 0, bottom: scrollViewBottomInset, right: 0)
    }
    
    func createRouteButton(route: Route, index: Int) -> UIButton {
        let button = UIButton()
        let xCoord = (Int(screenSize.width) - buttonWidth)/2
        let yCoord = Int(scrollViewTopInset) + index*buttonSpacing + index*buttonHeight
        
        button.frame = CGRect(x: xCoord, y: yCoord, width:buttonWidth, height: buttonHeight)
        
        button.setTitle(route.origin!.name! + "\n\n\n" + route.destination!.name!, for: .normal)
        button.setTitleColor(UIColor(red: 1, green: 1, blue: 1, alpha: 1) , for: .normal)
        
        button.titleLabel!.lineBreakMode = NSLineBreakMode.byWordWrapping
        button.titleLabel!.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.titleLabel!.layer.shadowOpacity = 0.9
        button.titleLabel!.textAlignment = .center
        button.titleLabel!.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.bold)
        
        button.setBackgroundImage(UIImage(data:route.image!,scale:1.0), for: .normal)

        button.layer.cornerRadius = 20
        button.clipsToBounds = true

        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.tag = index
        button.addTarget(self, action: #selector(self.readRouteDetail), for: .touchUpInside)
        return button
    }
    
    @objc func readRouteDetail(sender: UIButton) {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let routeDetailTableVC = storyBoard.instantiateViewController(withIdentifier: "routeDetailTable") as! RouteDetailTableVC
        routeDetailTableVC.route = routes[sender.tag] 
        self.navigationController?.pushViewController(routeDetailTableVC, animated: true)
    }
    
    @IBAction func addNewRoute(_ sender: Any) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        
        let newRouteNavVC = storyBoard.instantiateViewController(withIdentifier: "newRouteNav") as! UINavigationController
        newRouteNavVC.modalPresentationStyle = .fullScreen
        self.present(newRouteNavVC, animated:true, completion:nil)
    }
}
