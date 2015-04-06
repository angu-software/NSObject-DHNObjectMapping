//
//  DHNTravelInfo.m
//  NSObject+DHNObjectMapping
//
//  Created by Andreas on 05.04.15.
//  Copyright (c) 2015 dreyhomenet. All rights reserved.
//

#import "DHNTravelInfo.h"
#import "DHNTrainInfo.h"
#import "NSObject+DHNObjectMapping.h"

@class MyClass;

@implementation DHNTravelInfo

- (void)dhn_updatePropertiesWithDictionary:(NSDictionary *)dictionary andConfiguration:(DHNObjectMappingConfiguration *)mappingConfiguration
{
    
    [mappingConfiguration setMappingFromDictionaryKeyPath:@"dateDeparture"
                                            toPropertyKey:@"dateDeparture"
                                                withBlock:^id(NSString *propertKey, NSString *dictionaryKeyPath, id dictionaryValue) {
                                              
                                                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                                    dateFormatter = [[NSDateFormatter alloc] init];
                                                    dateFormatter.dateFormat = @"dd.MM.yyyy hh:mm";
        NSDate *date = [dateFormatter dateFromString:dictionaryValue];
        return date;
        
    }];
    [mappingConfiguration setMappingFromDictionaryKeyPath:@"departingFrom" toPropertyKey:@"departingDestination"];
    [mappingConfiguration setMappingFromDictionaryKeyPath:@"train"
                                            toPropertyKey:@"trainInfo"
                                                withClass:[DHNTrainInfo class]];
    
    [super dhn_updatePropertiesWithDictionary:dictionary andConfiguration:mappingConfiguration];
}

@end
