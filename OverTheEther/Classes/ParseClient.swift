//
//  ParseClient.swift
//  ThroughOuterSpace
//
//  Created by Johannes Schreiber on 29/01/16.
//  Copyright © 2016 Johannes Schreiber. All rights reserved.
//

import Foundation
import Parse
import CocoaLumberjack

class ParseClient: BaaSClient {
    
    required init() {
        Parse.setApplicationId("XetMqR3J7rUitAgiWz5ShIBssx7LOuNqVMSyxGC2",
            clientKey: "m1IDG1DACxQEt24jBFkN5xUskwZhFsDmvoAaUtol")
    }

    func downloadFile(withUUID uuid: String, progress: ProgressBlock?, completion: @escaping CompletionDownloadBlock) {
        let query = PFQuery(className: "Data")
        query.whereKey("uuid", equalTo: uuid)
        query.findObjectsInBackground {(objects, error) -> Void in
            guard error == nil
                else { DDLogError("Parse didnt find objects: \(String(describing: error))") ; return }

            guard let results = objects
                else { DDLogError("Objects array is nil") ; return }

            guard results.count == 1
                else { DDLogError("Parse found more than one or no object") ; return }

            let result = results.first!
            let receivedFileOptArr = result.object(forKey: "data")
            guard let receivedFileArr = receivedFileOptArr as? [PFFileObject]
                else { DDLogError("Received file array is not [PFFile] array") ; return }

            guard let receivedFile = receivedFileArr.first
                else { DDLogError("Received array has no first element") ; return }

            receivedFile.getDataInBackground({ (data, error) -> Void in
                guard error == nil else { DDLogError("Error while downloding file") ; return }
                guard let receivedData = data
                    else { DDLogError("Received data is nil") ; return }

                let err:NSError? = nil
                completion(err, receivedData as Data)

                // Remove the file from the server
                result.deleteInBackground(block: { (success, error) -> Void in
                    guard success
                        else { DDLogError("Couldn't delete file") ; return }
                    guard error == nil
                        else { DDLogError("Delete error: \(error!)") ; return }

                    DDLogInfo("Deleted received file from Parse")
                })

                }, progressBlock: { (percentComplete) -> Void in
                    if let p = progress {
                        p(Double(percentComplete) / 100.0)
                    }
            })
        }
    }

    func uploadFile(data: Data, progress: ProgressBlock?, completion: @escaping CompletionUploadBlock) {
        let dataOpt = PFFileObject(data: data as Data)
        guard let data = dataOpt else { DDLogError("Couldnt create PFFile") ; return }
        let uuid = NSUUID().uuidString
        let parseObject = PFObject(className: "Data")

        parseObject.add(uuid, forKey: "uuid")
        parseObject.add(data, forKey: "data")
        parseObject.saveInBackground { (success, error) -> Void in
            if let err = error {
                completion(err as NSError, uuid)
            } else if !success {
                completion(NSError(domain: "Upload", code: 0, userInfo: nil), uuid)
            } else {
                completion(nil, uuid)
            }
        }

    }
}
