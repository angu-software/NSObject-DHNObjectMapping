//
//  NSObject+DHNObjectMapping.m
//
//
//  Created by Andreas on 22.03.15.
//
//  The MIT License (MIT) (https://www.tldrlegal.com/l/mit)
//  Copyright (c) 2015 Andreas Guenther.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.

#import "NSObject+DHNObjectMapping.h"

NSObject *const kDHNMappingByDefault = @"kDHNMappingByDefault";

@interface DHNObjectMappingConfiguration ()

@property (nonatomic, strong) NSMutableDictionary *valueMappings;
@property (nonatomic, strong) NSMutableDictionary *blockMappings;
@property (nonatomic, strong) NSMutableDictionary *classMappings;
@property (nonatomic, strong) NSMutableDictionary *keyPathMappings;

@end

@implementation DHNObjectMappingConfiguration

- (NSMutableDictionary *)valueMappings
{

    if (!_valueMappings) {
        _valueMappings = [NSMutableDictionary dictionary];
    }
    
    return _valueMappings;

}

- (NSMutableDictionary *)blockMappings
{

    if (!_blockMappings) {
        _blockMappings = [NSMutableDictionary dictionary];
    }

    return _blockMappings;
    
}

- (NSMutableDictionary *)classMappings
{

    if (!_classMappings) {
        _classMappings = [NSMutableDictionary dictionary];
    }
    
    return _classMappings;

}

- (NSMutableDictionary *)keyPathMappings
{

    if (!_keyPathMappings) {
        _keyPathMappings = [NSMutableDictionary dictionary];
    }
    
    return _keyPathMappings;

}

- (NSArray *)allKeyPaths
{

    return [[self.valueMappings allKeys] arrayByAddingObjectsFromArray:[self.keyPathMappings allKeys]];

}

- (void)setMappingFromDictionaryKeyPath:(NSString *)keyPath
                         toPropertyKey:(NSString *)propertyKey
{
    self.valueMappings[keyPath] = propertyKey;
}

- (void)setMappingFromDictionaryKeyPath:(NSString *)keyPath
                         toPropertyKey:(NSString *)propertyKey
                             withBlock:(DHNDictionaryKeyPathToPropertyMappingBlock)mappingBlock
{

    [self setMappingFromDictionaryKeyPath:keyPath toPropertyKey:propertyKey];
    
    self.blockMappings[keyPath] = mappingBlock;

    // removing the class mapping -> block mapping replaces the class mapping
    if ([[self.classMappings allKeys] containsObject:keyPath]) {
        [self.classMappings removeObjectForKey:keyPath];
    }
    
}

- (void)setMappingFromDictionaryKeyPath:(NSString *)keyPath
                         toPropertyKey:(NSString *)propertyKey
                             withClass:(Class)objectClass
{

    [self setMappingFromDictionaryKeyPath:keyPath toPropertyKey:propertyKey];
    
    self.classMappings[keyPath] = objectClass;

    // removing the block mapping -> class mapping replaces the block mapping
    if ([[self.blockMappings allKeys] containsObject:keyPath]) {
        [self.blockMappings removeObjectForKey:keyPath];
    }
    
}


- (void)setMappingForDictionaryKeyPath:(NSString *)keyPath
                            withBlock:(DHNMappingBlock)mappingBlock
{

    self.keyPathMappings[keyPath] = mappingBlock;

}

- (void)removeKeyPathMappings:(NSArray *)keyPaths
{
    
    [keyPaths enumerateObjectsUsingBlock:^(NSString *dictionaryKeyPath, NSUInteger idx, BOOL *stop) {
        
        [self.blockMappings removeObjectForKey:dictionaryKeyPath];
        [self.classMappings removeObjectForKey:dictionaryKeyPath];
        [self.valueMappings removeObjectForKey:dictionaryKeyPath];
        [self.keyPathMappings removeObjectForKey:dictionaryKeyPath];
        
    }];
    
}

@end


@implementation NSObject (DHNObjectMapping)

+ (instancetype)dhn_objectWithDictionary:(NSDictionary *)dictionary;
{
    id object = [[[self class] alloc] init];
        
    [object dhn_updatePropertiesWithDictionary:dictionary andConfiguration:[[DHNObjectMappingConfiguration alloc] init]];
    
    return object;
}

+ (NSArray *)dhn_arrayOfObjectsWithArray:(NSArray *)dictionaryRepresentations
{

    if (!dictionaryRepresentations) {
        return nil;
    }
    
    NSMutableArray *objectArray = [NSMutableArray arrayWithCapacity:[dictionaryRepresentations count]];
    
    [dictionaryRepresentations enumerateObjectsUsingBlock:^(NSDictionary *dictionary, NSUInteger idx, BOOL *stop) {
       
        id object = [self dhn_objectWithDictionary:dictionary];
        if (object) {
            
            [objectArray addObject:object];
            
        }
        
    }];
    
    return [objectArray copy];

}

+ (instancetype)dhn_objectWithDictionary:(NSDictionary *)dictionary
                  inManagedObjectContext:(NSManagedObjectContext *)context
{

    id object = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([self class])
                                              inManagedObjectContext:context];
    
    if (object) {
        [object dhn_updatePropertiesWithDictionary:dictionary andConfiguration:[[DHNObjectMappingConfiguration alloc] init]];
    }
    
    return object;

}

- (void)dhn_updatePropertiesWithDictionary:(NSDictionary *)dictionary
                          andConfiguration:(DHNObjectMappingConfiguration *)mappingConfiguration
{

    // must ignore all key paths from the mapping configuration for the generic mapping
    // otherwise the mapped objects could contain broken data, although they are specified in the mapping configuration
    NSArray *keyPathsIgnoredByGenericMapping = mappingConfiguration.allKeyPaths;
    
    NSArray *mappedKeyPaths = [self dhn_keyPathMappingWithDictionary:dictionary andConfiguration:mappingConfiguration];
    
    // remove already mapped key paths from configuration in order to not process them again
    [mappingConfiguration removeKeyPathMappings:mappedKeyPaths];
    
    // mapp key paths directly to properties
    [self dhn_keyPathToPropertyMappingWithDictionary:dictionary andConfiguration:mappingConfiguration];
    
    // generic mapping (mapping key paths to properties of same name)
    [self dhn_genericKeyPathToPropertyMappingWithDictionary:dictionary ignoreKeyPaths:keyPathsIgnoredByGenericMapping];

}

- (BOOL)dhn_isValidValue:(id)value
{
    
    BOOL isValid = value != nil;

    isValid &= ![value isEqual:[NSNull null]];
    
    if ([value respondsToSelector:@selector(count)]) {
        
        isValid &= [value count] > 0;
        
    }
    
    if ([value respondsToSelector:@selector(length)]) {
        
        isValid &= [value length] > 0;
        
    }
    
    // check on invalid characters
    if([value isKindOfClass:[NSString class]])
    {
    
        NSString *trimmedString = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        isValid &= trimmedString.length > 0;
        
    }
    
    return isValid;

}

/*
 *  Iterates over all keys of the dictionary and try to set the value to a propperty with the same name.
 */
- (NSArray *)dhn_genericKeyPathToPropertyMappingWithDictionary:(NSDictionary *)dictionary
                                                 ignoreKeyPaths:(NSArray *)ignoredKeyPaths
{
    NSMutableArray *mappedKeyPaths = [NSMutableArray array];
    
    // prepare ignored kay paths. trim sub keypaths from the ignored key path
    __block NSMutableArray *skippingKeyPaths = [NSMutableArray array];
    [ignoredKeyPaths enumerateObjectsUsingBlock:^(NSString *dictionaryKeyPath, NSUInteger idx, BOOL *stop) {
       
        [skippingKeyPaths addObject:[[dictionaryKeyPath componentsSeparatedByString:@"."] firstObject]];
        
    }];
    
    [[dictionary allKeys] enumerateObjectsUsingBlock:^(NSString *keyPath, NSUInteger idx, BOOL *stop) {
        
        if (![skippingKeyPaths containsObject:keyPath]) {
            
            if ([self respondsToSelector:NSSelectorFromString(keyPath)]) {
                
                id dictionaryData = dictionary[keyPath];
                
                if ([self dhn_isValidValue:dictionaryData]) {
                    [self setValue:dictionaryData forKey:keyPath];
                    [mappedKeyPaths addObject:keyPath];
                }
                
            };
        }
        
    }];
    
    return [mappedKeyPaths copy];

}

- (NSArray *)dhn_keyPathToPropertyMappingWithDictionary:(NSDictionary *)dictionary
                                          andConfiguration:(DHNObjectMappingConfiguration *)mappingConfiguration
{
    
    __block NSMutableArray *mappedKeyPaths = [NSMutableArray array];
    
    [mappingConfiguration.valueMappings enumerateKeysAndObjectsUsingBlock:^(NSString *dictionaryKeyPath, NSString *propertyKeyPath, BOOL *stop) {
        
        id dictionaryData = [dictionary valueForKeyPath:dictionaryKeyPath];
        
        if ([self dhn_isValidValue:dictionaryData]) {
            
            id mappedObject = kDHNMappingByDefault;
            
            //block mapping
            if ([[mappingConfiguration.blockMappings allKeys] containsObject:dictionaryKeyPath]) {
                DHNDictionaryKeyPathToPropertyMappingBlock mappingBlock = mappingConfiguration.blockMappings[dictionaryKeyPath];
                if (mappingBlock != NULL) {
                    
                    mappedObject = mappingBlock(propertyKeyPath, dictionaryKeyPath, dictionaryData);
                }
            }
            
            //class mapping
            if ([[mappingConfiguration.classMappings allKeys] containsObject:dictionaryKeyPath]) {
                
                Class classObject = mappingConfiguration.classMappings[dictionaryKeyPath];
                
                if ([dictionaryData isKindOfClass:[NSDictionary class]]) {
                    mappedObject = [classObject dhn_objectWithDictionary:dictionaryData];
                    
                } else if ([dictionaryData isKindOfClass:[NSArray class]]) {
                    mappedObject = [classObject dhn_arrayOfObjectsWithArray:dictionaryData];
                }
                
            }
            
            //direct mapping
            if ([mappedObject isEqual:kDHNMappingByDefault]) {
                mappedObject = dictionaryData;
            } 
                
            if (mappedObject) {
                [self setValue:mappedObject forKeyPath:propertyKeyPath];
                [mappedKeyPaths addObject:dictionaryKeyPath];
            }
        }
    }];
    
    return [mappedKeyPaths copy];
    
}

- (NSArray *)dhn_keyPathMappingWithDictionary:(NSDictionary *)dictionary
                               andConfiguration:(DHNObjectMappingConfiguration *)mappingConfiguration
{
    
    __block NSMutableArray *mappedKeyPaths = [NSMutableArray array];
    // general key path mapping
    [mappingConfiguration.keyPathMappings enumerateKeysAndObjectsUsingBlock:^(NSString *dictionaryKeyPath, DHNMappingBlock mappingBlock, BOOL *stop) {
        
        id dictionaryData = [dictionary valueForKeyPath:dictionaryKeyPath];
        
        if ([self dhn_isValidValue:dictionaryData]) {
            
            mappingBlock(dictionaryKeyPath, dictionaryData);
            
            [mappedKeyPaths addObject:dictionaryKeyPath];
        }
        
    }];
    
    return [mappedKeyPaths copy];
    
}

@end
