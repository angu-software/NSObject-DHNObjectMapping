//
//  NSObject_DHNObjectMappingTests.m
//  NSObject+DHNObjectMappingTests
//
//  Created by Andreas on 22.03.15.
//  Copyright (c) 2015 dreyhomenet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "NSObject+DHNObjectMapping.h"
#import "DHNTravelInfo.h"
#import "DHNTrainInfo.h"

@interface NSObject_DHNObjectMappingTests : XCTestCase

@property (nonatomic, strong) NSDictionary *objectData;
@property (nonatomic ,strong) NSDateFormatter *dateFormatter;

@end

@implementation NSObject_DHNObjectMappingTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    NSString *dataPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"travelInfo" ofType:@"plist"];
    self.objectData = [NSDictionary dictionaryWithContentsOfFile:dataPath];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"dd.MM.yyyy hh:mm";
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testMapping {
    
    DHNTravelInfo *travelInfo = [DHNTravelInfo dhn_objectWithDictionary:self.objectData];
    XCTAssertTrue([travelInfo.destination isEqualToString:self.objectData[@"destination"]], @"Destination");
    XCTAssertTrue([[self.dateFormatter stringFromDate:travelInfo.dateDeparture] isEqualToString:self.objectData[@"dateDeparture"]], @"Date");
    XCTAssertTrue([travelInfo.departingDestination isEqualToString:self.objectData[@"departingFrom"]], @"Departing destination");
    XCTAssertTrue([travelInfo.travelers isEqualToArray:self.objectData[@"travelers"]], @"Travelers array");
    XCTAssertTrue([travelInfo.trainInfo.name isEqualToString:self.objectData[@"train"][@"name"]], @"Train info name");
    XCTAssertTrue([travelInfo.trainInfo.maxSpeed isEqualToNumber:self.objectData[@"train"][@"maxSpeed"]], @"Train info max speed");
    XCTAssertTrue([travelInfo.trainInfo.hasRestaurant isEqualToNumber:self.objectData[@"train"][@"hasRestaurant"]], @"Train info has restaurant");
    
}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
