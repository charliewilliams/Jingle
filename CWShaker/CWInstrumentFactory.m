//
//  CWInstrumentInformationSource.m
//  CWShaker
//
//  Created by C Williams on 02/11/2013.
//  Copyright (c) 2013 Charlie Williams. All rights reserved.
//

#import "CWInstrumentFactory.h"
#import "CWInstrument.h"

#define kNumberOfInstruments 6

@implementation CWInstrumentFactory

+ (NSUInteger)numberOfInstruments {
    return kNumberOfInstruments;
}

+ (NSUInteger)lastInstrumentIndex {
    return kNumberOfInstruments-1;
}

+ (CWInstrument *)instrumentAtIndex:(NSInteger)index {
    
    NSAssert(index < [self numberOfInstruments], @"Index beyond number of instruments");
    
    switch (index) {
            
        case Shaker: {
            return [CWInstrument instrumentWithName:@"Egg Shaker" image:[self imageNamed:@"Egg_Shaker"] index:Shaker];
        }
            break;
            
        case JingleBells: {
            return [CWInstrument instrumentWithName:@"Sleigh Bells" image:[self imageNamed:@"Sleigh_Bells"] index:JingleBells];
        }
            break;
            
        case Snare: {
            return [CWInstrument instrumentWithName:@"Snare Drum" image:[self imageNamed:@"Snare_Drum"] index:Snare];
        }
            break;
            
        case Tambourine: {
            return [CWInstrument instrumentWithName:@"Tambourine" image:[self imageNamed:@"Tambourine"] index:Tambourine];
        }
            break;
            
        case RainStick: {
            return [CWInstrument instrumentWithName:@"Rain Stick" image:[self imageNamed:@"Rain_Stick"] index:RainStick];
        }
            break;
            
        case Maracas: {
            return [CWInstrument instrumentWithName:@"Maracas" image:[self imageNamed:@"Maracas"] index:Maracas];
        }
            break;
    
        case Guiro: {
            return [CWInstrument instrumentWithName:@"Guiro" image:[self imageNamed:@"Guiro"] index:Guiro];
        }
            break;
            
        case SpaceWater1: {
            return [CWInstrument instrumentWithName:@"Space Water" image:[self imageNamed:@"Space_Water"] index:SpaceWater1];
        }
            break;
            
        case SpaceWater2: {
            return [CWInstrument instrumentWithName:@"Space Icecubes" image:[self imageNamed:@"Space_Water2"] index:SpaceWater2];
        }
            break;
    }
    return nil;
}

+ (UIImage *)imageNamed:(NSString *)imageName {
    
#if TARGET_OS_TV
    NSString *path = [[NSBundle mainBundle] pathForResource:imageName ofType:@"png"];
    return [UIImage imageWithContentsOfFile:path];
#else
    return [UIImage imageNamed:imageName];
#endif
}

@end
