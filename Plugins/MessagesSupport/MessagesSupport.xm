#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include "utils.h"

%group MessagesSupport

%hook ApplicationManager

- (NSDictionary *)_supplementalSystemAppBundleIDMappingForWatchOSSixAndLater {
    NSDictionary *result = %orig;
    NSMutableDictionary *mapping = [result mutableCopy] ?: [NSMutableDictionary dictionary];
    NSString *messagesBundleID = @"com.apple.MobileSMS";
    mapping[messagesBundleID] = messagesBundleID;
    Log(@"Added Messages supplemental bundle mapping");
    return mapping;
}

%end

%end

static void InstallMessagesSupportHooks(void) {
    Class managerClass = objc_lookUpClass("ACXAvailableApplicationManager");
    if (!managerClass) {
        Log(@"ACXAvailableApplicationManager class not found, skipping MessagesSupport hooks");
        return;
    }

    %init(MessagesSupport, ApplicationManager=managerClass);
    Log(@"Installed MessagesSupport hooks");
}

%ctor {
    const char *progname = getprogname();
    if (!progname) {
        return;
    }

    if (is_equal(progname, "appconduitd")) {
        Log(@"Initializing MessagesSupport...");
        InstallMessagesSupportHooks();
    }
}
