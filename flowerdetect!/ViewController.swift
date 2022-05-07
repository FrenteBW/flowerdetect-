import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true //crop the image
        
    }
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
        //edited image = cropped image
            guard let convertedCIImage = CIImage(image: userPickedImage) else{ //CIImage로 변환
                
                fatalError("cannot convert to CIImage.")
                
            }
            
            detect(image: convertedCIImage)
        
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    //
    func detect(image: CIImage){
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else{ //학습된 모델 불러오기
            
            fatalError("Cannot import model")
            
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in //모델 request 불러오기
                    guard let result = request.results?.first as? VNClassificationObservation else {
                        fatalError("Could not complete classfication")
                    }
              
                    self.navigationItem.title = result.identifier.capitalized //Flower name 보여주기
                    self.requestInfo(flowerName: result.identifier)
                    
        }
        
        let handler = VNImageRequestHandler(ciImage: image) //모델 handler 불러오기
        
        do{
        try handler.perform([request])
        }
        
        catch{
            print(error)
        }
    }
    
    func requestInfo(flowerName: String){
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "redirects" : "1",
            "pithumbsize" : "500",
            "indexpageids" : ""
            
        ]
        
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON
        { (response) in
            if response.result.isSuccess{
                
                let flowerJSON : JSON = JSON(response.result.value!)
                
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue //설명부분 내용
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL)) //cocopod 이용,
                
                self.label.text = flowerDescription
                
            }
        }
    }
    
        @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}

//commit 확인
