#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include "utils.h"

@interface WatchBundle : NSObject
- (BOOL)isApplicableToOSVersion:(id)version error:(id *)error;
@end

%group AppsSupport

%hook WatchBundle

- (BOOL)isApplicableToKnownWatchOSVersion {
    return [self isApplicableToOSVersion:@"11.9999" error:nil];
}

- (NSString *)currentOSVersionForValidationWithError:(id *)error {
    return @"11.9999";
}

%end

%end

static void InstallAppsSupportHooks(void) {
    Class watchBundleClass = objc_lookUpClass("MIEmbeddedWatchBundle");
    if (!watchBundleClass) {
        Log(@"MIEmbeddedWatchBundle class not found, skipping AppsSupport hooks");
        return;
    }

    %init(AppsSupport, WatchBundle=watchBundleClass);

    Log(@"Installed AppsSupport hooks");
}

%ctor {
    const char *progname = getprogname();
    if (!progname) {
        return;
    }
    if (is_equal(progname, "installd") ||
        is_equal(progname, "MobileInstallationHelperService") ||
        is_equal(progname, "com.apple.MobileInstallationHelperService")) {
        Log(@"Initializing AppsSupport...");
        InstallAppsSupportHooks();
    }
}
