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

- (NSArray *)allAttributes
{

    return [[self.valueMappings allKeys] arrayByAddingObjectsFromArray:[self.keyPathMappings allKeys]];

}

- (void)setMappingFromDictionaryKeyPath:(NSString *)attributeKeyPath
                         toPropertyKey:(NSString *)propertyKey
{
    self.valueMappings[attributeKeyPath] = propertyKey;
}

- (void)setMappingFromDictionaryKeyPath:(NSString *)attributeKeyPath
                         toPropertyKey:(NSString *)propertyKey
                             withBlock:(DHNDictionaryKeyPathToPropertyMappingBlock)mappingBlock
{

    [self setMappingFromDictionaryKeyPath:attributeKeyPath toPropertyKey:propertyKey];
    
    self.blockMappings[attributeKeyPath] = mappingBlock;

    // removing the class mapping -> block mapping replaces the class mapping
    if ([[self.classMappings allKeys] containsObject:attributeKeyPath]) {
        [self.classMappings removeObjectForKey:attributeKeyPath];
    }
    
}

- (void)setMappingFromDictionaryKeyPath:(NSString *)attributeKeyPath
                         toPropertyKey:(NSString *)propertyKey
                             withClass:(Class)objectClass
{

    [self setMappingFromDictionaryKeyPath:attributeKeyPath toPropertyKey:propertyKey];
    
    self.classMappings[attributeKeyPath] = objectClass;

    // removing the block mapping -> class mapping replaces the block mapping
    if ([[self.blockMappings allKeys] containsObject:attributeKeyPath]) {
        [self.blockMappings removeObjectForKey:attributeKeyPath];
    }
    
}


- (void)setMappingForDictionaryKeyPath:(NSString *)attributeKeyPath
                            withBlock:(DHNMappingBlock)mappingBlock
{

    self.keyPathMappings[attributeKeyPath] = mappingBlock;

}

- (void)removeKeyPathMappings:(NSArray *)attributeKeypaths
{
    
    [attributeKeypaths enumerateObjectsUsingBlock:^(NSString *dictionaryKeyPath, NSUInteger idx, BOOL *stop) {
        
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

    // must ignore all attributes from the mapping configuration for the generic mapping
    // otherwise the mapped objects could contain broken data, although they are specified in the mapping configuration
    NSArray *attributesIgnoredByGenericMapping = mappingConfiguration.allAttributes;
    
    NSArray *mappedAttributes = [self dhn_attributeMappingWithdictionary:dictionary andConfiguration:mappingConfiguration];
    
    // remove already mapped attributes from configuration in order to not process them again
    [mappingConfiguration removeKeyPathMappings:mappedAttributes];
    
    // mapp attributes directly to properties
    [self dhn_attributesToPropertyMappingWithdictionary:dictionary andConfiguration:mappingConfiguration];
    
    // generic mapping (mapping attributes to properties of same name)
    [self dhn_genericAttributesToPropertyMappingWithdictionary:dictionary ignoreAttributes:attributesIgnoredByGenericMapping];

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
- (NSArray *)dhn_genericAttributesToPropertyMappingWithdictionary:(NSDictionary *)dictionary
                                                 ignoreAttributes:(NSArray *)ignoredAttributes
{
    NSMutableArray *mappedAttributes = [NSMutableArray array];
    
    // prepare ignored attributes. trim sub keypaths from the ignored attribute
    __block NSMutableArray *skippingAttributes = [NSMutableArray array];
    [ignoredAttributes enumerateObjectsUsingBlock:^(NSString *dictionaryKeyPath, NSUInteger idx, BOOL *stop) {
       
        [skippingAttributes addObject:[[dictionaryKeyPath componentsSeparatedByString:@"."] firstObject]];
        
    }];
    
    [[dictionary allKeys] enumerateObjectsUsingBlock:^(NSString *attributeName, NSUInteger idx, BOOL *stop) {
        
        if (![skippingAttributes containsObject:attributeName]) {
            
            if ([self respondsToSelector:NSSelectorFromString(attributeName)]) {
                
                id dictionaryData = dictionary[attributeName];
                
                if ([self dhn_isValidValue:dictionaryData]) {
                    [self setValue:dictionaryData forKey:attributeName];
                    [mappedAttributes addObject:attributeName];
                }
                
            };
        }
        
    }];
    
    return [mappedAttributes copy];

}

- (NSArray *)dhn_attributesToPropertyMappingWithdictionary:(NSDictionary *)dictionary
                                          andConfiguration:(DHNObjectMappingConfiguration *)mappingConfiguration
{
    
    __block NSMutableArray *mappedAttributes = [NSMutableArray array];
    
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
                [mappedAttributes addObject:dictionaryKeyPath];
            }
        }
    }];
    
    return [mappedAttributes copy];
    
}

- (NSArray *)dhn_attributeMappingWithdictionary:(NSDictionary *)dictionary
                               andConfiguration:(DHNObjectMappingConfiguration *)mappingConfiguration
{
    
    __block NSMutableArray *mappedAttributes = [NSMutableArray array];
    // general attribute mapping
    [mappingConfiguration.keyPathMappings enumerateKeysAndObjectsUsingBlock:^(NSString *dictionaryKeyPath, DHNMappingBlock mappingBlock, BOOL *stop) {
        
        id dictionaryData = [dictionary valueForKeyPath:dictionaryKeyPath];
        
        if ([self dhn_isValidValue:dictionaryData]) {
            
            mappingBlock(dictionaryKeyPath, dictionaryData);
            
            [mappedAttributes addObject:dictionaryKeyPath];
        }
        
    }];
    
    return [mappedAttributes copy];
    
}

@end
