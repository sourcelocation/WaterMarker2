//
//  ViewController.swift
//  WaterMarker
//
//  Created by Матвей Анисович on 3/23/21.
//

import Cocoa

class ViewController: NSViewController {

    var selectedImageURLs:[URL] = []
    var watermarkURL:URL?
    
    var previewImageIndex = 0
    var selectedScaling: Double = 0.6
    var selectedAlpha: Double = 0.3
    
    var replaceFiles = false
    var watermarkImage: NSImage?
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var watermarkImageView: NSImageView!
    @IBOutlet weak var watermarkFilenameLabel: NSTextField!
    @IBOutlet weak var imageViewPreview: NSImageView!
    @IBAction func scalingSliderValueChanged(_ sender: NSSlider) {
        let chosenScaling = sender.doubleValue
        selectedScaling = chosenScaling
        self.updatePreview()
    }
    @IBAction func alphaSliderValueChanged(_ sender: NSSlider) {
        let chosenAlpha = sender.doubleValue
        selectedAlpha = chosenAlpha
        self.updatePreview()
    }
    @IBAction func selectWatermarkButtonClicked(_ sender: NSButton) {
        let panel: NSOpenPanel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.isFloatingPanel = false
        panel.allowedFileTypes = imageFormats
        panel.beginSheetModal(for: self.view.window!, completionHandler: { response in
            if response == NSApplication.ModalResponse.OK {
                let url = panel.url!
                self.watermarkURL = url
                self.watermarkFilenameLabel.stringValue = url.lastPathComponent
                self.watermarkImageView.image = url.image
                self.watermarkImage = url.image
                self.updatePreview()
            }
        })
    }
    @IBAction func exportButtonClicked(_ sender: NSButton) {
        let panel: NSOpenPanel = NSOpenPanel()
        panel.canCreateDirectories = true
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.isFloatingPanel = false
        panel.prompt = "Export"
        panel.beginSheetModal(for: self.view.window!, completionHandler: { response in
            if response == NSApplication.ModalResponse.OK {
                guard let selectedURL = panel.url else { return }
                // Export
                for i in 0..<self.selectedImageURLs.count {
                    let imagecg = self.renderImage(index: i, alpha: self.selectedAlpha, scaling: self.selectedScaling)
                    let imagens = imagecg?.nsImage
                    let imageURL = selectedURL.appendingPathComponent(self.selectedImageURLs[i].lastPathComponent)
                    imagens?.writePNG(toURL: imageURL)
                }
            }
        })
    }
    
    @IBAction func selectFileButtonClicked(_ sender: NSButton) {
        let panel: NSOpenPanel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.isFloatingPanel = false
        panel.allowedFileTypes = imageFormats
        panel.beginSheetModal(for: self.view.window!, completionHandler: { response in
            if response == NSApplication.ModalResponse.OK {
                let selectedULRsPreviousCount = self.selectedImageURLs.count
                self.selectedImageURLs += panel.urls
                
                self.tableView.insertRows(at: IndexSet(selectedULRsPreviousCount...self.selectedImageURLs.count - 1), withAnimation: .slideDown)
                self.updatePreview()
            }
        })
        
    }
    @IBAction func changeIndexButtonTapped(_ sender: NSButton) {
        if selectedImageURLs.count < 1 { return }
        previewImageIndex += sender.tag == 1 ? -1 : 1
        if previewImageIndex >= selectedImageURLs.count {
            previewImageIndex = 0
        } else if previewImageIndex < 0{
            previewImageIndex = selectedImageURLs.count
        }
        self.updatePreview()
    }
    @IBAction func resetImagesButtonClicked(_ sender: NSButton) {
        let count = selectedImageURLs.count
        selectedImageURLs.removeAll()
        previewImageIndex = 0
        self.imageViewPreview.image = nil
        self.tableView.removeRows(at: IndexSet(0..<count), withAnimation: .effectFade)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerForDraggedTypes([.png,.tiff,.URL])
    }
    func updatePreview() {
        let cgImage = self.renderImage(index: self.previewImageIndex, alpha: selectedAlpha, scaling: selectedScaling)
        imageViewPreview.image = cgImage?.nsImage
    }
    func renderImage(index:Int, alpha: Double, scaling: Double) -> CGImage? {
        if selectedImageURLs.count < 1 { return nil }
        guard let bgImage = selectedImageURLs[index].image?.cgImage else { return nil }
        guard let watermark = watermarkImage?.cgImage else { return nil }
        let overlayer = Overlayer()
        let output = overlayer.overlay(bgImage, with: watermark,scaling:scaling, alpha:alpha)
        
        return output!
    }
}

extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return selectedImageURLs.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let url = selectedImageURLs[row]
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ImageCell"), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = url.lastPathComponent
            cell.imageView?.image = url.image
            return cell
        }
        return nil
    }
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 50
    }
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        self.previewImageIndex = row
        self.updatePreview()
        return true
    }
    func tableView( _ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if dropOperation == .above {
            return .copy
        }
        return []
    }
    func tableView( _ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let items = info.draggingPasteboard.pasteboardItems else { return false }
        
        let urls = items.compactMap { $0.propertyList(forType: .fileURL) as? String }.compactMap { URL(string: $0) }
        print(urls)
        selectedImageURLs += urls
        tableView.reloadData()
        return true
    }
}

extension URL {
    var image: NSImage? {
        return NSImage(contentsOf: self)
    }
    var exists: Bool {
        return FileManager.default.fileExists(atPath: self.path)
    }
}
extension NSImage {
    var cgImage: CGImage {
        return self.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    }
    func writePNG(toURL url: URL) {
        var url = url
        let shouldAlwaysReplaceFiles = UserDefaults.standard.bool(forKey: "alwaysReplaceFiles")
        
        guard let data = tiffRepresentation, let rep = NSBitmapImageRep(data: data), let imgData = rep.representation(using: .png, properties: [.compressionFactor : NSNumber(floatLiteral: 1.0)]) else {
            return
        }
        if url.exists, !shouldAlwaysReplaceFiles {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "File \"\(url.lastPathComponent)\" already exists"
            alert.informativeText = "Would you like to replace the already existing file at \"\(url.path)\"?"
            alert.addButton(withTitle: "Keep both")
            alert.addButton(withTitle: "Skip")
            alert.addButton(withTitle: "Replace")
            alert.showsSuppressionButton = true
            alert.suppressionButton?.title = "Always replace all files"
            
            let response = alert.runModal()
            
            if let suppressionButton = alert.suppressionButton,
               suppressionButton.state == .on {
                UserDefaults.standard.set(true, forKey: "alwaysReplaceFiles")
            }
            
            if response == .alertSecondButtonReturn {
                return
            } else if response == .alertFirstButtonReturn {
                url = url.deletingLastPathComponent().appendingPathComponent(url.deletingPathExtension().lastPathComponent + " with watermark." + url.pathExtension)
            }
        }
        do {
            try imgData.write(to: url)
        } catch {
            print(error)
        }
    }
}

extension CGImage {
    var nsImage: NSImage {
        return NSImage(cgImage:self, size: CGSize(width:width,height:height))
    }
}

let imageFormats = ["png", "jpg","jpeg", "tiff", "heic"]
