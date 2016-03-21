//
//  KPLocalAssetsManager.m
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 12/01/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KPLocalAssetsManager.h"
#import "KPPlayerConfig.h"
#import "WidevineClassicCDM.h"
#import "NSMutableArray+QueryItems.h"
#import "KPLog.h"
#import "KPURLProtocol.h"
#import "KCacheManager.h"
#import "NSString+Utilities.h"


@interface KPLocalAssetsManager ()
+ (NSURLQueryItem *)queryItem:(NSString *)name
                             :(NSString *)value;
@end

typedef NS_ENUM(NSUInteger, kDRMScheme) {
    kDRMWidevineClassic, kDRMWidevineCENC
};

@interface KPPlayerConfig (Asset)
@property (nonatomic, copy, readonly) NSData *loadUIConf;
@property (nonatomic, copy, readonly) NSURL *resolvePlayerRootURL;
@end

@implementation KPPlayerConfig (Asset)

- (NSData *)loadUIConf {
    NSURL *serverURL = [NSURL URLWithString:self.server];
    serverURL = [serverURL URLByAppendingPathComponent:@"api_v3/index.php"];
    NSURLComponents *urlComps = [NSURLComponents componentsWithURL:serverURL resolvingAgainstBaseURL:NO];
    
    NSMutableArray *items = [NSMutableArray arrayWithArray:@[
                                                             [KPLocalAssetsManager queryItem:@"service" :@"uiconf"],
                                                             [KPLocalAssetsManager queryItem:@"action" :@"get"],
                                                             [KPLocalAssetsManager queryItem:@"format" :@"1"],
                                                             [KPLocalAssetsManager queryItem:@"p" :self.partnerId],
                                                             [KPLocalAssetsManager queryItem:@"id" :self.uiConfId],
                                                             ]];
    
    if (self.ks) {
        [items addObject:[KPLocalAssetsManager queryItem:@"ks" :self.ks]];
    }
    
    NSURL* apiCall = urlComps.URL;
    
    return [NSData dataWithContentsOfURL:apiCall];
}

- (NSURL *)resolvePlayerRootURL {
    // serverURL is something like "http://cdnapi.kaltura.com";
    // we need to get to "http://cdnapi.kaltura.com/html5/html5lib/v2.38.3".
    // This is done by loading UIConf data, and looking at "html5Url" property.
    
    NSData *jsonData = self.loadUIConf;
    NSError *jsonError = nil;
    NSDictionary *uiConf = [NSJSONSerialization JSONObjectWithData:jsonData
                                                           options:0
                                                             error:&jsonError];
    
    if (!uiConf) {
        KPLogError(@"Error parsing uiConf json: %@", jsonError);
        return nil;
    }
    NSString *serviceError = uiConf[@"message"];
    if (serviceError) {
        KPLogError(@"uiConf service reported error: %@", serviceError);
        return nil;
    }
    
    NSString *embedLoaderUrl = uiConf[@"html5Url"];
    
    // embedLoaderUrl is typically something like "/html5/html5lib/v2.38.3/mwEmbedLoader.php".
    
    if (!embedLoaderUrl) {
        KPLogError(@"No html5Url in uiConf");
        return nil;
    }
    NSURL *serverURL = [NSURL URLWithString:self.server];
    if ([embedLoaderUrl hasPrefix:@"/"]) {
        serverURL = [serverURL URLByAppendingPathComponent:embedLoaderUrl];
    } else {
        serverURL = [NSURL URLWithString:embedLoaderUrl];
    }
    
    return [serverURL URLByDeletingLastPathComponent];
}

@end

static NSInteger _threadCounter;

@implementation KPLocalAssetsManager

+ (void)setThreadCounter:(NSInteger)threadCounter {
    @synchronized(self) {
        _threadCounter = threadCounter;
    }
}

+ (NSInteger)threadCounter {
    @synchronized(self) {
        return _threadCounter;
    }
}

#define JSON_BYTE_LIMIT = 1024 * 1024;

#define CHECK_NOT_NULL(v)   if (!(v)) return NO
#define CHECK_NOT_EMPTY(v)  if ((v).length == 0) return NO

+ (BOOL)registerAsset:(KPPlayerConfig *)assetConfig
               flavor:(NSString *)flavorId
                 path:(NSString *)localPath
             callback:(kLocalAssetRegistrationBlock)completed {
    
    // NOTE: this method currently only supports (and assumes) Widevine Classic.
    
    // Preflight: check that all parameters are valid.
    CHECK_NOT_NULL(assetConfig);
    CHECK_NOT_EMPTY(assetConfig.server);
    CHECK_NOT_EMPTY(assetConfig.entryId);
    CHECK_NOT_NULL(assetConfig.partnerId);
    CHECK_NOT_EMPTY(assetConfig.uiConfId);
    CHECK_NOT_EMPTY(flavorId);
    CHECK_NOT_EMPTY(localPath);
    
    self.threadCounter = 1;
    [self storeLocalContentPage:assetConfig callback:completed];
    if (localPath.isWV) {
        self.threadCounter = 2;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self registerWidevineAsset:assetConfig
                              localPath:localPath
                               flavorId:flavorId
                               callback:completed];
        });
    }
    return YES;
}

+ (NSString *)prepareLicenseURLForAsset:(KPPlayerConfig *)assetConfig
                               flavorId:(NSString *)flavorId
                              drmScheme:(kDRMScheme)drmScheme
                                  error:(NSError **)error {
    
    // load license data
    NSURL *getLicenseDataURL = [self prepareGetLicenseDataURLForAsset:assetConfig
                                                             flavorId:flavorId
                                                            drmScheme:drmScheme];
    NSData *licenseData = [NSData dataWithContentsOfURL:getLicenseDataURL];
    NSError *jsonError = nil;
    NSDictionary *licenseDataDict = [NSJSONSerialization JSONObjectWithData:licenseData
                                                                    options:0
                                                                      error:&jsonError];
    
    if (!licenseDataDict) {
        KPLogError(@"Error parsing licenseData json: %@", jsonError);
        return nil;
    }
    
    // parse license data
    NSDictionary *licenseDataError = licenseDataDict[@"error"];
    if (licenseDataError) {
        NSString *message = [licenseDataError isKindOfClass:[NSDictionary class]] ? licenseDataError[@"message"] : @"<none>";
        if (error) {
            *error = [NSError errorWithDomain:@"KPLocalAssetsManager"
                                         code:'lder'
                                     userInfo:@{NSLocalizedDescriptionKey: @"License data error",
                                                @"EntryId": assetConfig.entryId ? assetConfig.entryId : @"<none>",
                                                @"ServiceError": message ? message : @"<none>"}];
        }
        return nil;
    }
    
    NSString* licenseUri = licenseDataDict[@"licenseUri"];
    
    return licenseUri;
}

+ (NSURL *)prepareGetLicenseDataURLForAsset:(KPPlayerConfig *)assetConfig
                                   flavorId:(NSString *)flavorId
                                  drmScheme:(kDRMScheme)drmScheme {
    
    NSURL *serverURL = [NSURL URLWithString:assetConfig.server];
    
    // URL may either point to the root of the server or to mwEmbedFrame.php. Resolve this.
    if ([serverURL.path hasSuffix:@"/mwEmbedFrame.php"]) {
        serverURL = [serverURL URLByDeletingLastPathComponent];
    } else {
        serverURL = assetConfig.resolvePlayerRootURL;
    }
    
    
    // Now serviceURL is something like "http://cdnapi.kaltura.com/html5/html5lib/v2.38.3".
    NSString* drmName = nil; 
    
    switch (drmScheme) {
        case kDRMWidevineCENC:
            drmName = @"wvcenc";
            break;
        case kDRMWidevineClassic:
            drmName = @"wvclassic";
            break;
    }
    
    // Build service URL
    NSURL* serviceURL = [serverURL URLByAppendingPathComponent:@"services.php"];
    NSURLComponents* url = [NSURLComponents componentsWithURL:serviceURL resolvingAgainstBaseURL:NO];
    
    NSMutableArray<NSURLQueryItem*>* queryItems = assetConfig.queryItems;
    [queryItems addQueryParam:@"service" value:@"getLicenseData"];
    [queryItems addQueryParam:@"drm" value:drmName];
    [queryItems addQueryParam:@"flavor_id" value:flavorId];

    url.queryItems = queryItems;
    
    serviceURL = [url URL];
    
    return serviceURL;

}

+ (void)registerWidevineAsset:(KPPlayerConfig *)assetConfig
                    localPath:(NSString *)localPath
                     flavorId:(NSString *)flavorId
                     callback:(kLocalAssetRegistrationBlock)callback {
    
    NSError *error = nil;
    NSString *licenseUri = [self prepareLicenseURLForAsset:assetConfig
                                                  flavorId:flavorId
                                                 drmScheme:kDRMWidevineClassic
                                                     error:&error];
    if (!licenseUri) {
        KPLogError(@"Error getting license data: %@", error);
        callback(error);
        return;
    }
    
    [WidevineClassicCDM setEventBlock:^(KCDMEventType event, NSDictionary *data) {
        
        switch (event) {
            case KCDMEvent_LicenseAcquired:
                self.threadCounter--;
                if (!self.threadCounter) {
                    callback(nil);
                }
                break;
                
            default:
                break;
        }
        KPLogDebug(@"Got asset event: event=%d, data=%@", event, data);
    } forAsset:localPath];
    [WidevineClassicCDM registerLocalAsset:localPath withLicenseUri:licenseUri];
    
}

+ (void)storeLocalContentPage:(KPPlayerConfig *)assetConfig
                     callback:(kLocalAssetRegistrationBlock)callback {
    [NSURLProtocol registerClass:[KPURLProtocol class]];
    CacheManager.baseURL = assetConfig.server;
    CacheManager.cacheSize = assetConfig.cacheSize;
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:assetConfig.videoURL]
                                       queue:[NSOperationQueue new]
                           completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
                               if (connectionError) {
                                   callback(connectionError);
                               } else if (data) {
                                   self.threadCounter--;
                                   if (!self.threadCounter) {
                                       callback(nil);
                                   }
                               }
                               [NSURLProtocol unregisterClass:[KPURLProtocol class]];
                           }];
}

+ (void)addQueryParameters:(NSDictionary *)queryParams
           toURLComponents:(NSURLComponents *)components {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:queryParams.count];
    [queryParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [array addObject:[NSURLQueryItem queryItemWithName:key value:obj]];
    }];
    components.queryItems = array;
}

+ (NSURLQueryItem *)queryItem:(NSString *)name
                             :(NSString *)value {
    return [NSURLQueryItem queryItemWithName:name value:value];
}

@end
