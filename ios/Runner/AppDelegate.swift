import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AhniGradeOcr")!
    let channel = FlutterMethodChannel(name: "ahni/grade_ocr", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognize", let args = call.arguments as? [String: Any],
            let path = args["path"] as? String else { result(FlutterMethodNotImplemented); return }
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          guard let image = UIImage(contentsOfFile: path)?.cgImage else {
            throw NSError(domain: "GradeOCR", code: 1)
          }
          let request = VNRecognizeTextRequest()
          request.recognitionLevel = .accurate
          request.recognitionLanguages = ["ko-KR", "en-US"]
          try VNImageRequestHandler(cgImage: image).perform([request])
          let width = CGFloat(image.width), height = CGFloat(image.height)
          func row(_ text: String, _ rect: CGRect) -> [String: Any] {
            ["text": text, "left": rect.minX * width, "top": (1 - rect.maxY) * height,
             "right": rect.maxX * width, "bottom": (1 - rect.minY) * height]
          }
          var lines: [[String: Any]] = [], fragments: [[String: Any]] = []
          for observation in request.results ?? [] {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let text = candidate.string
            lines.append(row(text, observation.boundingBox))
            var found = false
            let regex = try NSRegularExpression(pattern: "\\S+")
            let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
            for match in regex.matches(in: text, range: fullRange) {
              guard let range = Range(match.range, in: text),
                    let box = try? candidate.boundingBox(for: range) else { continue }
              fragments.append(row(String(text[range]), box.boundingBox))
              found = true
            }
            if !found { fragments.append(row(text, observation.boundingBox)) }
          }
          let payload: [String: Any] = ["text": lines.compactMap { $0["text"] as? String }.joined(separator: "\n"), "lines": lines, "fragments": fragments]
          DispatchQueue.main.async { result(payload) }
        } catch {
          DispatchQueue.main.async { result(FlutterError(code: "ocr_failed", message: "OCR failed", details: nil)) }
        }
      }
    }
  }
}
