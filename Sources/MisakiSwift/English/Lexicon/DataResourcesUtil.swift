// MODIFIED FROM UPSTREAM by Halfmarble LLC, 2026. Apache License 2.0 section
// 4(b): the bundled resource directory was renamed Resources/ -> MisakiData/,
// because iOS codesign rejects a resource bundle whose top-level folder is
// literally named "Resources" ("bundle format unrecognized").
import Foundation

final class DataResourcesUtil {
    private init() {}
    
    static func loadGold(british: Bool) -> [String: Any] {
        let filename = british ? "gb_gold" : "us_gold"
        
      guard let url = Bundle.module.url(forResource: filename, withExtension: "json", subdirectory: "MisakiData"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return [:]
        }
      
        return json
    }
    
    static func loadSilver(british: Bool) -> [String: Any] {
      let filename = british ? "gb_silver" : "us_silver"
      
      guard let url = Bundle.module.url(forResource: filename, withExtension: "json",  subdirectory: "MisakiData"),
            let data = try? Data(contentsOf: url),
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
          return [:]
      }
            
      return json
    }
}
