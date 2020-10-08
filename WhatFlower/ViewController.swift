//
//  ViewController.swift
//  WhatFlower
//
//  Created by 1101373 on 2020/10/07.
//
import Alamofire
import CoreML
import SDWebImage
import SwiftyJSON
import UIKit
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let imagePicker = UIImagePickerController()

    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var userPickedImageView: UIImageView!
    @IBOutlet var information: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        userPickedImageView.contentMode = .scaleAspectFill
        userPickedImageView.clipsToBounds = true
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert UIImage to CIImage")
            }
            
            userPickedImageView.image = userPickedImage

            detect(image: ciImage)
        }

        imagePicker.dismiss(animated: true, completion: nil)
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }

    func request(_ flowerName: String) {
        let wikipediaURl = "https://en.wikipedia.org/w/api.php"

        let parameters: [String: String] = [
            "format": "json",
            "action": "query",
            "prop": "extracts|pageimages",
            "exintro": "",
            "explaintext": "",
            "titles": flowerName,
            "indexpageids": "",
            "redirects": "1",
            "pithumbsize": "500",
        ]

        Alamofire.request(wikipediaURl,
                          parameters: parameters).responseJSON { response in
            if response.result.isSuccess {
                if let value = response.result.value {
                    let json = JSON(value)
                    let pageid = json["query"]["pageids"][0]
                    print(pageid)

                    let extract = json["query"]["pages"]["\(pageid)"]["extract"]
                    print(extract)

                    self.information.text = extract.stringValue

                    let flowerImageUrl = json["query"]["pages"]["\(pageid)"]["thumbnail"]["source"].stringValue
                    print(flowerImageUrl)
                    self.imageView.sd_setImage(with : URL(string : flowerImageUrl))
                }
            }
        }
    }

    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreModel failed.")
        }

        let request = VNCoreMLRequest(model: model) { request, _ in

            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image.")
            }

            if let firstResult = results.first {
                self.navigationItem.title = firstResult.identifier
                self.request(firstResult.identifier)
            }

//            print(results)
        }

        let handler = VNImageRequestHandler(ciImage: image)

        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
}
