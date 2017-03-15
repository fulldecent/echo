//
//  Audio.swift
//  Echo
//
//  Created by Full Decent on 1/18/17.
//  Copyright © 2017 William Entriken. All rights reserved.
//

import Foundation
import Alamofire

struct Audio {
    let id: Int
    
    private enum JSONName: String {
        case id = "fileID"
    }
    
    func fileURL() -> URL {
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        return documentURL.appendingPathComponent("\(id).caf")
    }
    
    func fileExistsOnDisk() -> Bool {
        return (try? fileURL().checkResourceIsReachable()) ?? false
    }

    func deleteFromDisk() {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: fileURL())
    }
    
    init?(json: [String : Any]) {
        guard let id = json[JSONName.id.rawValue] as? Int else {
            return nil
        }
        self.id = id
    }
    
    func toJSON() -> [String : Any] {
        var retval = [String : Any]()
        retval[JSONName.id.rawValue] = id
        return retval
    }
    
    func fetchFile(withProgress progressHandler: ((Progress) -> Void)?) {
        let url = NetworkManager.shared.baseURL.appendingPathComponent("audio/\(id).caf")!
        let headers = NetworkManager.shared.authenticationHeaders()
        print("Download STARTED for : \(self.fileURL())")
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (self.fileURL(), [.removePreviousFile, .createIntermediateDirectories])
        }
        Alamofire.download(url, headers: headers, to: destination)
            .downloadProgress { progress in
                print("Download Progress: \(progress.fractionCompleted)")
                progressHandler?(progress)
            }
            .responseData { response in
                print("Download Done for : \(self.fileURL())")
                if let data = response.result.value {
                    try? data.write(to: self.fileURL())
                    print("DID SAVE")
                } else {
                    print("FAILED TO SAVE")
                }
        }
    }
}
