//
//  DHNTravelInfo.h
//  NSObject+DHNObjectMapping
//
//  Created by Andreas on 05.04.15.
//  Copyright (c) 2015 dreyhomenet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DHNTrainInfo.h"

@interface DHNTravelInfo : NSObject

@property (nonatomic, copy) NSDate *dateDeparture;
@property (nonatomic, copy) NSString *destination;
@property (nonatomic, copy) NSString *departingDestination;
@property (nonatomic, strong) DHNTrainInfo *trainInfo;
@property (nonatomic, copy) NSArray *travelers;

@end
