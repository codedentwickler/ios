//
//  DownloadService.swift
//  AmahiAnywhere
//
//  Created by codedentwickler on 6/17/18.
//  Copyright © 2018 Amahi. All rights reserved.
//


import Foundation

// Downloads server file, and stores in local file.
// Allows cancel, pause, resume download.
class DownloadService : NSObject {
    
    static let shared = DownloadService()
    static let BackgroundIdentifier = "\(Bundle.main.bundleIdentifier!).background"

    var activeDownloads: [URL: Download] = [:]
    
    // Create downloadsSession here, to set self as delegate
    lazy var downloadsSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: DownloadService.BackgroundIdentifier)
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    // MARK: - Download methods called in Server FilesViewController delegate methods
    
    func startDownload(_ offlineFile: OfflineFile) {
        let url = offlineFile.remoteFileURL()

        debugPrint("Download Has Started for url \(url)")
        let download = Download(offlineFile: offlineFile)
        download.task = downloadsSession.downloadTask(with: url)
        download.task!.resume()
        download.isDownloading = true
        
        activeDownloads[url] = download
    }
    
    func pauseDownload(_ offlineFile: OfflineFile) {
        let url = offlineFile.remoteFileURL()

        guard let download = activeDownloads[url] else { return }
        
        if download.isDownloading {
            download.task?.cancel(byProducingResumeData: { data in
                download.resumeData = data
            })
            download.isDownloading = false
        }
    }
    
    func cancelDownload(_ offlineFile: OfflineFile) {
        let url = offlineFile.remoteFileURL()

        if let download = activeDownloads[url] {
            download.task?.cancel()
            activeDownloads[url] = nil
        }
    }
    
    func resumeDownload(_ offlineFile: OfflineFile) {
        let url = offlineFile.remoteFileURL()

        guard let download = activeDownloads[url] else { return }
        if let resumeData = download.resumeData {
            download.task = downloadsSession.downloadTask(withResumeData: resumeData)
        } else {
            download.task = downloadsSession.downloadTask(with: url)
        }
        download.task!.resume()
        download.isDownloading = true
    }
}
