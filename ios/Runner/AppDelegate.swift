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
    let channel = FlutterMethodChannel(
      name: "ahni/grade_ocr", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognize", let args = call.arguments as? [String: Any],
        let path = args["path"] as? String
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          guard let image = UIImage(contentsOfFile: path)?.cgImage else {
            throw NSError(domain: "GradeOCR", code: 1)
          }
          var lines: [[String: Any]] = []
          var fragments: [[String: Any]] = []
          // The transcript has two tables. Recognize them separately so Vision
          // cannot merge a historical grade with the adjacent current course.
          let split = image.width / 2
          let defaultRegions = [
            CGRect(x: 0, y: 0, width: split, height: image.height),
            CGRect(x: split, y: 0, width: image.width - split, height: image.height),
          ]
          let suppliedRegions = (args["regions"] as? [[String: Double]])?.compactMap {
            item -> CGRect? in
            guard let left = item["left"], let top = item["top"], let right = item["right"],
              let bottom = item["bottom"],
              left.isFinite, top.isFinite, right.isFinite, bottom.isFinite, right > left,
              bottom > top
            else { return nil }
            let rect = CGRect(x: left, y: top, width: right - left, height: bottom - top)
              .intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return rect.isNull || rect.isEmpty ? nil : rect
          }
          let regions = suppliedRegions ?? defaultRegions
          let fieldsOnly = args["fieldsOnly"] as? Bool ?? false
          let regex = try NSRegularExpression(pattern: "\\S+")
          for region in regions {
            guard let cropped = image.cropping(to: region) else { continue }
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = fieldsOnly ? .fast : .accurate
            request.recognitionLanguages = fieldsOnly ? ["en-US"] : ["ko-KR", "en-US"]
            // Read credit/grade glyphs without natural-language correction.
            request.usesLanguageCorrection = !fieldsOnly

            try VNImageRequestHandler(cgImage: cropped).perform([request])
            func row(_ text: String, _ rect: CGRect) -> [String: Any] {
              [
                "text": text, "left": region.minX + rect.minX * region.width,
                "top": region.minY + (1 - rect.maxY) * region.height,
                "right": region.minX + rect.maxX * region.width,
                "bottom": region.minY + (1 - rect.minY) * region.height,
              ]
            }
            for observation in request.results ?? [] {
              let alternatives = observation.topCandidates(fieldsOnly ? 5 : 1)
              let fieldPattern = #"^(?:\d{1,2}\.\d\s*)?(?:[ABCD][+0]|P|NP|F)?$"#
              let fieldCandidate =
                fieldsOnly
                ? alternatives.first(where: {
                  !$0.string.trimmingCharacters(in: .whitespaces).isEmpty
                    && $0.string.range(of: fieldPattern, options: .regularExpression) != nil
                }) : nil
              guard let candidate = fieldCandidate ?? alternatives.first else { continue }
              let text = candidate.string
              lines.append(row(text, observation.boundingBox))
              var found = false
              let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
              for match in regex.matches(in: text, range: fullRange) {
                guard let range = Range(match.range, in: text),
                  let box = try? candidate.boundingBox(for: range)
                else { continue }
                fragments.append(row(String(text[range]), box.boundingBox))
                found = true
              }
              if !found { fragments.append(row(text, observation.boundingBox)) }
            }
          }
          let payload: [String: Any] = [
            "text": lines.compactMap { $0["text"] as? String }.joined(separator: "\n"),
            "lines": lines, "fragments": fragments,
          ]
          DispatchQueue.main.async { result(payload) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "ocr_failed", message: "OCR failed", details: nil))
          }
        }
      }
    }
  }
}
