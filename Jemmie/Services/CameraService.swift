import AVFoundation
import UIKit
import Combine

final class CameraService: NSObject, ObservableObject {
    @Published var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var completionQueue: [(Data?) -> Void] = []
    
    // MARK: - Public API
    
    func startSession() {
        if captureSession?.isRunning == true { return }
        
        let session = AVCaptureSession()
        session.sessionPreset = .medium
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("[Camera] Failed to access back camera")
            return
        }
        
        guard session.canAddInput(input) else { return }
        session.addInput(input)
        
        let output = AVCapturePhotoOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        photoOutput = output
        
        DispatchQueue.main.async {
            self.captureSession = session
        }
            
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    func stopSession() {
        captureSession?.stopRunning()
        DispatchQueue.main.async {
            self.captureSession = nil
        }
        photoOutput = nil
    }

    /// Capture a single JPEG frame from the current session.
    func captureFrame(completion: @escaping (Data?) -> Void) {
        guard let output = photoOutput else {
            completion(nil)
            return
        }
        
        completionQueue.append(completion)
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard !completionQueue.isEmpty else { return }
        let completion = completionQueue.removeFirst()
        
        if let error = error {
            print("[Camera] Capture error: \(error.localizedDescription)")
            completion(nil)
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData),
              let jpegData = image.jpegData(compressionQuality: 0.5) else {
            print("[Camera] Failed to process photo")
            completion(nil)
            return
        }

        print("[Camera] Captured frame: \(jpegData.count) bytes")
        completion(jpegData)
    }
}