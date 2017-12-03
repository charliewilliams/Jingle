//
//  CWInstrument.m
//  CWShaker
//
//  Created by C Williams on 02/11/2013.
//  Copyright (c) 2013 Charlie Williams. All rights reserved.
//

#import "CWInstrument.h"
#import "iSTK.h"
#import "CWInstrumentFactory.h"

typedef enum ShakerTypes {
    
    Maraca_ = 0,
    Cabasa_ = 1,
    Sekere_ = 2,
    Guiro_ = 3,
    WaterDrops_ = 4,
    BambooChimes_ = 5,
    Tambourine_ = 6,
    SleighBells_ = 7,
    Sticks_ = 8,
    Crunch_ = 9,
    Wrench_ = 10,
    SandPaper_ = 11,
    CokeCan_ = 12,
    NextMug_ = 13,
    PennyVsMug_ = 14,
    NickelVsMug_ = 15,
    DimeVsMug_ = 16,
    QuarterVsMug_ = 17,
    FrancVsMug_ = 18,
    PesoVsMug_ = 19,
    BigRocks_ = 20,
    LittleRocks_ = 21,
    TunedBambooChimes_ = 22,
    EggShaker_ = 23
} ShakerTypes;

struct InstrumentData {
    NSUInteger baseNote;
    NSUInteger range;
    CGFloat amplitude;
    NSUInteger decay;
};

@interface CWInstrument ()

@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, readwrite) UIImage *image;
@property (nonatomic, assign) InstrumentData *instPtr;

@end

@implementation CWInstrument

- (void)dealloc {
    
    delete _instPtr;
}

+ (CWInstrument *)instrumentWithName:(NSString *)name image:(UIImage *)image index:(NSUInteger)index {
    
    CWInstrument *instrument = [[CWInstrument alloc] init];
    
    instrument.name = name;
    instrument.image = image;
    instrument.index = index;
    
    return instrument;
}

- (id)init {
    
    if (self = [super init]) {
        
        _instPtr = new InstrumentData();
    }
    return self;
}

- (void)setIndex:(NSUInteger)index {
    
    ShakerTypes stkIndex = [self stkIndexFromLayoutIndex:(Instrument)index];
    self.instPtr->baseNote = [self baseNoteForInstrumentIndex:stkIndex];
    self.instPtr->range = [self noteRangeForInstrumentIndex:stkIndex];
    self.instPtr->amplitude = 1;
    self.instPtr->decay = 127;
    
    _index = index;
}

- (ShakerTypes)stkIndexFromLayoutIndex:(Instrument)index {
    
// TODO do sample-based Snare
// TODO do gesture-based Guiro
    
    switch (index) {
            
        case JingleBells:
            return SleighBells_; // BUG
            
        case Shaker:
            return EggShaker_;
            
        case Snare:
            return (ShakerTypes)-1;
            
        case Tambourine:
            return Tambourine_;
            
        case Guiro:
            return Guiro_;
            
        case RainStick:
            return LittleRocks_; //?
            
        case Maracas:
            return Maraca_;
            
        case SpaceWater1:
            return TunedBambooChimes_;
            
        case SpaceWater2:
            return BambooChimes_;
    }
    return (ShakerTypes)-1;
}

static NSArray *allValidNotes = @[@54,  @55,  @59,  @62,  @66,  @70,
                                  @74,  @78,  @83,  @88,  @93,
                                  @98,  @104, @110, @117, @124,
                                  @131, @139, @147, @156, @165,
                                  @175, @185, @196, @196 // one extra to terminate
                                  ];

- (NSInteger)baseNoteForInstrumentIndex:(ShakerTypes)index {
    
    return [allValidNotes[index] integerValue];
}

- (NSUInteger)noteRangeForInstrumentIndex:(ShakerTypes)index {
    
    NSAssert([allValidNotes count] > index, @"index overrun: %d vs %lu", index, (unsigned long)[allValidNotes count]);
    
    return [allValidNotes[index+1] integerValue] - [allValidNotes[index] integerValue];
}

@end
