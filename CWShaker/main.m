//
//  main.m
//  CWShaker
//
//  Created by C Williams on 02/11/2013.
//  Copyright (c) 2013 Charlie Williams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import "CWAppDelegate.h"

int main(int argc, char * argv[]) {
    
    @autoreleasepool {
        
#ifndef __i386__
//        if (system(NULL)) {
//            exit(0);
//        };
        
//        uint32_t a = _dyld_image_count();
//        
//        for (uint32_t i = 0; i < a; i++) {
//            const char *b = _dyld_get_image_name(0);
//            if ([[NSString stringWithUTF8String:b] rangeOfString:@"Substrate"].location != NSNotFound) {
//                exit(0);
//            }
//        }
#endif
        
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([CWAppDelegate class]));
    }
}
