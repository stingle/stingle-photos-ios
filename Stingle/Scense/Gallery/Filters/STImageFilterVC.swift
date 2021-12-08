//
//  STImageFilterVC.swift
//  Stingle
//
//  Created by Shahen Antonyan on 12/7/21.
//

import UIKit
import MetalPetal

enum STImageFilterType {
    case brightness
    case contrast

    var title: String {
        switch self {
        case .brightness:
            return "Brightness"
        case .contrast:
            return "Contrast"
        }
    }
}

class STImageFilter {
    let type: STImageFilterType
    let min: Float
    let max: Float
    var value: Float
    var filter: MTIUnaryFilter!

    init(type: STImageFilterType, min: Float, max: Float) {
        self.type = type
        self.min = min
        self.max = max
        self.value = (min + max) / 2
    }
}

class STImageFilterVC: UIViewController {

    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var imageView: STImageView!
    @IBOutlet weak var sliderValueLabel: UILabel!

    private var cgImage: CGImage?

    private var photoFile: STLibrary.File?

    private var selectedFilter: STImageFilter!

    private var filters = [
        STImageFilter(type: .brightness, min: 0.0, max: 1.0),
        STImageFilter(type: .contrast, min: 0.0, max: 1.0),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let photoFile = photoFile else {
            self.imageView.setImage(source: nil)
            return
        }
        let source = STImageView.Image(file: photoFile, isThumb: false)
        self.imageView.setImage(source, placeholder: nil) { result in
            self.cgImage = result?.cgImage
        } progress: { progress in

        } failure: { error in

        }
        let filter = self.filters.first!
        self.selectFilter(filter: filter)
    }

    @IBAction func sliderValueChanged(_ sender: Any) {
        self.selectedFilter.value = self.slider.value
        self.sliderValueLabel.text = "\(self.selectedFilter.value)"
        guard let cgImage = self.cgImage else {
            return
        }
        switch self.selectedFilter.type {
        case .brightness:
            let filter = MTIBrightnessFilter()
            filter.brightness = self.selectedFilter.value
            filter.inputImage = MTIImage(cgImage: cgImage)
            self.imageView.image = self.imageFromMTImage(image: filter.outputImage)
        case .contrast:
            let filter = MTIContrastFilter()
            filter.contrast = self.selectedFilter.value
            filter.inputImage = MTIImage(cgImage: cgImage)
            self.imageView.image = self.imageFromMTImage(image: filter.outputImage)
        }
    }

    // MARK: - Private methods

    private func selectFilter(filter: STImageFilter) {
        guard let index = self.filters.firstIndex(where: { $0.type == filter.type }) else {
            return
        }
        self.slider.minimumValue = filter.min
        self.slider.maximumValue = filter.max
        self.slider.value = filter.value
        self.pickerView.selectRow(index, inComponent: 0, animated: false)
        self.selectedFilter = filter
    }

    private func imageFromMTImage(image: MTIImage?) -> UIImage? {
        if let device = MTLCreateSystemDefaultDevice(), let outputImage = image {
            do {
                let context = try MTIContext(device: device)
                let filteredImage = try context.makeCGImage(from: outputImage)
                return UIImage(cgImage: filteredImage)
            } catch {
                print(error.localizedDescription)
                return nil
            }
        } else {
            return nil
        }
    }

}

extension STImageFilterVC: UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.filters.count
    }

}

extension STImageFilterVC: UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.filters[row].type.title
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectFilter(filter: self.filters[row])
    }

}

extension STImageFilterVC {

    static func create(photoFile: STLibrary.File?) -> STImageFilterVC {
        let storyboard = UIStoryboard(name: "Gallery", bundle: .main)
        let vc: Self = storyboard.instantiateViewController(identifier: "STImageFilterVC")
        vc.photoFile = photoFile
        return vc
    }

}
