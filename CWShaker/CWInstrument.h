//
//  CWInstrument.h
//  CWShaker
//
//  Created by C Williams on 02/11/2013.
//  Copyright (c) 2013 Charlie Williams. All rights reserved.
//

#define kInstrumentSelection 1071
#define kSystemDecay 4

struct InstrumentData;

@interface CWInstrument : NSObject

@property (nonatomic, readonly) NSUInteger index;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) struct InstrumentData *instPtr;

+ (CWInstrument *)instrumentWithName:(NSString *)name image:(UIImage *)image index:(NSUInteger)index;

@end
