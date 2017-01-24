//
//  ExceptionCatcher.h
//  EP Calipers
//
//  Created by David Mann on 1/24/17.
//  Copyright © 2017 EP Studios. All rights reserved.
//

// see http://stackoverflow.com/questions/34956002/how-to-properly-handle-nsfilehandle-exceptions-in-swift-2-0/35003095#35003095

#ifndef ExceptionCatcher_h
#define ExceptionCatcher_h

#import <Foundation/Foundation.h>

NS_INLINE NSException * _Nullable tryBlock(void(^_Nonnull tryBlock)(void)) {
    @try {
        tryBlock();
    }
    @catch (NSException *exception) {
        return exception;
    }
    return nil;
}
#endif /* ExceptionCatcher_h */
