//
//  CWInstrumentFactory.h
//  CWShaker
//
//  Created by C Williams on 02/11/2013.
//  Copyright (c) 2013 Charlie Williams. All rights reserved.
//

@class CWInstrument;

typedef enum InstrumentIndex {
    JingleBells,
    Maracas,
    Tambourine,
    Shaker,
    SpaceWater1,
    SpaceWater2,
    Guiro,
    Snare,
    RainStick
} InstrumentIndex;

@interface CWInstrumentFactory : NSObject

+ (NSUInteger)numberOfInstruments;
+ (NSUInteger)lastInstrumentIndex;
+ (CWInstrument *)instrumentAtIndex:(NSInteger)index;

@end
