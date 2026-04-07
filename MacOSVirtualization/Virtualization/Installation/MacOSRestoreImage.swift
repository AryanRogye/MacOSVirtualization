//
//  MacOSRestoreImage.swift
//  MacOSVirtualization
//
//  Created by Aryan Rogye on 4/7/26.
//

import Virtualization

enum MacOSRestoreImageError: Error {
    case localURLInvalid
    case failedToMoveDownloadedRestoreImage(String)
}

class MacOSRestoreImage: NSObject {
    
    private var downloadObserver: NSKeyValueObservation?
    /// Caller must set this
    public var onDownloadProgress: (Double?) -> Void = { p in }
    
    /**
     * Function Downloads the latest supported MacOSImage
     * completionHandler: either contains the error that the user has
     * this lets us pass the error back
     */
    public func download(
        completionHandler: @escaping (Result<Void, Error>
    ) -> Void) {
        VZMacOSRestoreImage.fetchLatestSupported { [self](result: Result<VZMacOSRestoreImage, Error>) in
            switch result {
            case let .failure(error):
                completionHandler(.failure(error))
                
            case let .success(restoreImage):
                downloadRestoreImage(restoreImage: restoreImage, completionHandler: completionHandler)
            }
        }
    }
    
    /**
     * Starts a download task and calls our completion handler on exit
     */
    private func downloadRestoreImage(
        restoreImage: VZMacOSRestoreImage,
        completionHandler: @escaping (Result<Void, Error>
    ) -> Void) {
        /// we set downloadTask to a download task that can be called/observed
        let downloadTask = URLSession.shared.downloadTask(with: restoreImage.url) { localURL, response, error in
            /// if there is a error just let whoever called this handle it
            if let error = error {
                completionHandler(.failure(error))
                return
            }
            
            /// make sure that the localURL is valid, this is better than apples example where they
            /// straight up unwrapped it with !
            guard let localURL else {
                completionHandler(.failure(MacOSRestoreImageError.localURLInvalid))
                return
            }
            
            /// Move the Downloaded URL to the new URL
            /// This renames the localURL to what its set as
            do {
                try FileManager.default.moveItem(
                    at: localURL,
                    to: Constants.restoreImageURL
                )
                completionHandler(.success(()))
            } catch {
                completionHandler(.failure(
                    MacOSRestoreImageError.failedToMoveDownloadedRestoreImage(error.localizedDescription)))
                return
            }
        }
        
        /// start observing it
        downloadObserver = downloadTask.progress.observe(\.fractionCompleted,
                                                          options: [.initial, .new]
        ) { [weak self] (progress, change) in
            guard let self else { return }
            /// Whoever is calling this should set this
            onDownloadProgress((change.newValue ?? 0) * 100)
        }
        downloadTask.resume()
    }
}
