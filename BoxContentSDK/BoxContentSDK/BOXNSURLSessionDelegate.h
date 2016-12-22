//
//  BOXNSURLSessionDelegate.h
//  BoxContentSDK
//
//  Created by Thuy Nguyen on 12/15/16.
//  Copyright © 2016 Box. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BOXAPIOperation.h"

/**
 Class to handle delegate callbacks for NSURLSession
 */
@interface BOXNSURLSessionDelegate : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate, NSURLSessionStreamDelegate>

- (void)mapSessionTaskId:(NSUInteger)sessionTaskId withOperation:(BOXAPIOperation *)operation;

@end
