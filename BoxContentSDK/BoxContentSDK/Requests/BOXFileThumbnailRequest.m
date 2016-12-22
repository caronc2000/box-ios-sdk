//
//  BOXFileThumbnailRequest.m
//  BoxContentSDK
//

#import "BOXRequest_Private.h"
#import "BOXFileThumbnailRequest.h"

#import "BOXAPIDataOperation.h"

@interface BOXFileThumbnailRequest ()

@property (nonatomic, readonly, strong) NSString *destinationPath;

@end

@implementation BOXFileThumbnailRequest

- (instancetype)initWithFileID:(NSString *)fileID
{
    if (self = [super init]) {
        _fileID = fileID;
        NSString *uniqueName = [NSString stringWithFormat:@"%@_%@", fileID, [[NSProcessInfo processInfo] globallyUniqueString]];
        _destinationPath = [NSTemporaryDirectory() stringByAppendingPathComponent:uniqueName];
    }
    return self;
}

- (instancetype)initWithFileID:(NSString *)fileID size:(BOXThumbnailSize)size
{
    if (self = [self initWithFileID:fileID]) {
        _maxWidth = [NSNumber numberWithInteger:size];
        _maxHeight = [NSNumber numberWithInteger:size];
    }
    return self;
}

- (BOXAPIOperation *)createOperation
{
    NSURL *URL = [self URLWithResource:BOXAPIResourceFiles
                                    ID:self.fileID
                           subresource:BOXAPISubresourceThumnailPNG
                                 subID:nil];
    
    NSMutableDictionary *queryParameters = [NSMutableDictionary dictionary];

    if (self.minWidth) {
        queryParameters[BOXAPIParameterKeyMinWidth] = [NSString stringWithFormat:@"%lld", [self.minWidth longLongValue]];
    }

    if (self.minHeight) {
        queryParameters[BOXAPIParameterKeyMinHeight] = [NSString stringWithFormat:@"%lld", [self.minHeight longLongValue]];
    }

    if (self.maxWidth) {
        queryParameters[BOXAPIParameterKeyMaxWidth] = [NSString stringWithFormat:@"%lld", [self.maxWidth longLongValue]];
    }

    if (self.maxHeight) {
        queryParameters[BOXAPIParameterKeyMaxHeight] = [NSString stringWithFormat:@"%lld", [self.maxHeight longLongValue]];
    }

    BOXAPIDataOperation *dataOperation = [self dataOperationWithURL:URL
                                                         HTTPMethod:BOXAPIHTTPMethodGET
                                              queryStringParameters:queryParameters
                                                     bodyDictionary:nil
                                                       successBlock:nil
                                                       failureBlock:nil];
    dataOperation.modelID = self.fileID;
    dataOperation.destinationPath = self.destinationPath;
    dataOperation.isSmallDownloadOperation = YES;
    
    [self addSharedLinkHeaderToRequest:dataOperation.APIRequest];

    return dataOperation;
}

- (void)performRequestWithProgress:(BOXProgressBlock)progressBlock completion:(BOXImageBlock)completionBlock
{
    if (completionBlock) {
        BOOL isMainThread = [NSThread isMainThread];
        BOXAPIDataOperation *dataOperation = (BOXAPIDataOperation *)self.operation;

        if (progressBlock) {
            dataOperation.progressBlock = ^(long long expectedTotalBytes, unsigned long long bytesReceived) {
                [BOXDispatchHelper callCompletionBlock:^{
                    progressBlock(bytesReceived, expectedTotalBytes);
                } onMainThread:isMainThread];
            };
        }

        NSString *destinationPath = self.destinationPath;
        dataOperation.successBlock = ^(NSString *modelID, long long expectedTotalBytes) {
            NSData *data = [NSData dataWithContentsOfFile:destinationPath];
            UIImage *image = [UIImage imageWithData:data scale:[[UIScreen mainScreen] scale]];
            [BOXDispatchHelper callCompletionBlock:^{
                completionBlock(image, nil);
            } onMainThread:isMainThread];
        };
        dataOperation.failureBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            [BOXDispatchHelper callCompletionBlock:^{
                completionBlock(nil, error);
            } onMainThread:isMainThread];
        };
        [self performRequest];
    }
}

#pragma mark - Superclass overidden methods

- (NSString *)itemIDForSharedLink
{
    return self.fileID;
}

- (BOXAPIItemType *)itemTypeForSharedLink
{
    return BOXAPIItemTypeFile;
}

@end
