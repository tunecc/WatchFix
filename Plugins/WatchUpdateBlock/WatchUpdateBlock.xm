#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <dispatch/dispatch.h>
#include "utils.h"

static const void *kWFWUBSUBManagerDelegateAssociationKey = &kWFWUBSUBManagerDelegateAssociationKey;

typedef void (^WFWUBBooleanResultCallback)(BOOL value);
typedef void (^WFWUBSingleResultCallback)(id result, NSError *error);
typedef void (^WFWUBScanResultsCallback)(id update, id scanResults);

static BOOL WFWUBShouldInstallForCurrentProcess(void) {
    const char *progname = getprogname();
    if (is_equal(progname, "Bridge") ||
        is_equal(progname, "SharingViewService") ||
        is_equal(progname, "softwareupdateservicesd")) {
        return YES;
    }

    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier] ?: @"";
    return [bundleIdentifier isEqualToString:@"com.apple.Bridge"] ||
        [bundleIdentifier isEqualToString:@"com.apple.SharingViewService"];
}

static id WFWUBCurrentSUBManagerDelegate(id manager) {
    if (manager && [manager respondsToSelector:@selector(delegate)]) {
        id delegate = ((id (*)(id, SEL))objc_msgSend)(manager, @selector(delegate));
        if (delegate) {
            return delegate;
        }
    }

    return manager ? objc_getAssociatedObject(manager, kWFWUBSUBManagerDelegateAssociationKey) : nil;
}

static id WFWUBNoUpdateScanResultsObject(id value) {
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *sanitized = [(NSDictionary *)value mutableCopy];
        sanitized[@"hasUpdate"] = @NO;
        [sanitized removeObjectForKey:@"update"];
        [sanitized removeObjectForKey:@"descriptor"];
        [sanitized removeObjectForKey:@"download"];
        return [sanitized copy];
    }

    if ([value isKindOfClass:[NSArray class]]) {
        return @[];
    }

    return @{ @"hasUpdate": @NO };
}

static void WFWUBDeliverSUBManagerNoUpdate(id manager) {
    id delegate = WFWUBCurrentSUBManagerDelegate(manager);
    SEL callbackSEL = @selector(manager:scanRequestDidLocateUpdate:error:);
    if (!delegate || ![delegate respondsToSelector:callbackSEL]) {
        return;
    }

    void (^deliver)(void) = ^{
        if (![delegate respondsToSelector:callbackSEL]) {
            return;
        }

        ((void (*)(id, SEL, id, id, id))objc_msgSend)(delegate, callbackSEL, manager, nil, nil);
    };

    if ([NSThread isMainThread]) {
        deliver();
    } else {
        dispatch_sync(dispatch_get_main_queue(), deliver);
    }
}

%group WatchUpdateBlockBridgeHooks

%hook SUBManager

- (instancetype)initWithDelegate:(id)delegate {
    id manager = %orig(delegate);
    if (manager && delegate) {
        objc_setAssociatedObject(manager,
                                 kWFWUBSUBManagerDelegateAssociationKey,
                                 delegate,
                                 OBJC_ASSOCIATION_ASSIGN);
    }

    return manager;
}

- (void)scanForUpdates {
    Log(@"Suppressing SUBManager watchOS update scan result");
    WFWUBDeliverSUBManagerNoUpdate(self);
}

%end

%end

%group WatchUpdateBlockServicesHooks

%hook WFWUBSUManagerClientClass

- (void)isScanning:(id)completion {
    WFWUBBooleanResultCallback callback = completion;
    if (callback) {
        callback(NO);
        return;
    }

    %orig(completion);
}

- (void)scanForUpdates:(id)options withResult:(id)completion {
    WFWUBSingleResultCallback callback = completion;
    if (callback) {
        callback(nil, nil);
        return;
    }

    %orig(options, completion);
}

- (void)scanForUpdates:(id)options withScanResults:(id)completion {
    WFWUBScanResultsCallback callback = completion;
    if (callback) {
        callback(nil, WFWUBNoUpdateScanResultsObject(nil));
        return;
    }

    %orig(options, completion);
}

- (void)scanRequestDidStartForOptions:(id)options {
}

- (void)scanRequestDidFinishForOptions:(id)options results:(id)results error:(NSError *)error {
    %orig(options, WFWUBNoUpdateScanResultsObject(results), nil);
}

- (void)scanDidCompleteForOptions:(id)options results:(id)results error:(NSError *)error {
    %orig(options, WFWUBNoUpdateScanResultsObject(results), nil);
}

- (void)scanRequestDidFinishForOptions:(id)options update:(id)update error:(NSError *)error {
    %orig(options, nil, nil);
}

- (void)scanDidCompleteWithNewUpdateAvailable:(id)update error:(NSError *)error {
    %orig(nil, nil);
}

%end

%end

static void InstallWatchUpdateBlockHooks(void) {
    Class subManagerClass = objc_lookUpClass("SUBManager");
    if (subManagerClass) {
        %init(WatchUpdateBlockBridgeHooks);
        Log(@"Installed WatchUpdateBlock SUBManager hooks");
    } else {
        Log(@"SUBManager class not found, skipping WatchUpdateBlock SUBManager hooks");
    }

    dlopen("/System/Library/PrivateFrameworks/SoftwareUpdateServices.framework/SoftwareUpdateServices", RTLD_NOW);

    Class suManagerClientClass = objc_lookUpClass("SUManagerClient");
    if (!suManagerClientClass) {
        Log(@"SUManagerClient class not found, skipping WatchUpdateBlock SoftwareUpdateServices hooks");
        return;
    }

    %init(WatchUpdateBlockServicesHooks, WFWUBSUManagerClientClass=suManagerClientClass);
    Log(@"Installed WatchUpdateBlock SoftwareUpdateServices hooks");
}

%ctor {
    if (!WFWUBShouldInstallForCurrentProcess()) {
        return;
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Log(@"Initializing WatchUpdateBlock...");
        InstallWatchUpdateBlockHooks();
    });
}
