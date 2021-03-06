//
//  Request.swift
//  SentrySwift
//
//  Created by Josh Holtz on 1/7/16.
//
//

import Foundation

extension SentryClient {
	
	public typealias EventFinishedSending = (success: Bool) -> ()
	
	/// Sends an event to the API
	/// - Parameter event: An event
	/// - Parameter finished: A closure with a success boolean
	func sendEvent(event: Event, finished: EventFinishedSending? = nil) {
		do {
			let data = try NSJSONSerialization.dataWithJSONObject(event.serialized, options: [])
			sendData(data, finished: finished)
		} catch _ {
			return
		}
	}
	
	/// Sends data to the API
	/// - Parameter data: The data
	/// - Parameter finished: A closure with a success boolean
	func sendData(data: NSData, finished: EventFinishedSending? = nil) {

		// Logging cause yeah
		if let body = NSString(data: data, encoding: NSUTF8StringEncoding) {
			SentryLog.Debug.log("body = \(body)")
		}
		
		// Creating request
		let request = NSMutableURLRequest(URL: dsn.serverURL)
		request.HTTPMethod = "POST"
		request.HTTPBody = data
		
		// Setting headers
		let sentryHeader = dsn.xSentryAuthHeader
		request.setValue(sentryHeader.value, forHTTPHeaderField: sentryHeader.key)
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		
		// Creating data task
		let config = NSURLSessionConfiguration.defaultSessionConfiguration()
		let session = NSURLSession(configuration: config)
		
		// Creates and starts network request
		let task : NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: {(data, response, error) in
			
			var success = false
			
			// Returns success if we have data and 200 response code
			if let data = data, response = response as? NSHTTPURLResponse {
				SentryLog.Debug.log("status = \(response.statusCode)")
				SentryLog.Debug.log("response = \(NSString(data: data, encoding: NSUTF8StringEncoding))")
				
				success = 200..<300 ~= response.statusCode
			}
			if let error = error {
				SentryLog.Error.log("error = \(error)")
			}
			
			finished?(success: success)
		});
		task.resume()
	}
}
