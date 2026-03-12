import AVFoundation
import UIKit

final class CameraService: NSObject {
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var continuation: CheckedContinuation<Data?, Never>?

    // MARK: - Public API

    /// Capture a single JPEG frame from the back camera.
    func captureFrame(completion: @escaping (Data?) -> Void) {
        Task {
            let data = await captureFrameAsync()
            await MainActor.run { completion(data) }
        }
    }

    private func captureFrameAsync() async -> Data? {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            setupAndCapture()
        }
    }

    // MARK: - Private

    private func setupAndCapture() {
        let session = AVCaptureSession()
        session.sessionPreset = .medium
        captureSession = session

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("[Camera] Failed to access back camera")
            deliverResult(nil)
            return
        }

        guard session.canAddInput(input) else {
            deliverResult(nil)
            return
        }
        session.addInput(input)

        let output = AVCapturePhotoOutput()
        guard session.canAddOutput(output) else {
            deliverResult(nil)
            return
        }
        session.addOutput(output)
        photoOutput = output

        session.startRunning()

        // Small delay for camera sensor to warm up
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard let output = self.photoOutput else {
                self.deliverResult(nil)
                return
            }
            let settings = AVCapturePhotoSettings()
            output.capturePhoto(with: settings, delegate: self)
        }
    }

    private func teardown() {
        captureSession?.stopRunning()
        captureSession = nil
        photoOutput = nil
    }

    private func deliverResult(_ data: Data?) {
        teardown()
        continuation?.resume(returning: data)
        continuation = nil
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            print("[Camera] Capture error: \(error.localizedDescription)")
            deliverResult(nil)
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData),
              let jpegData = image.jpegData(compressionQuality: 0.5) else {
            print("[Camera] Failed to process photo")
            deliverResult(nil)
            return
        }

        print("[Camera] Captured frame: \(jpegData.count) bytes")
        deliverResult(jpegData)
    }
}
