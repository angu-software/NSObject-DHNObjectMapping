//
//  NSObject+DHNObjectMapping.h
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

@import CoreData;

extern NSObject *const kDHNMappingByDefault;

/**
 *  A mapping block for mapping a dictionary value to a property
 *
 *  @param propertKey    A property name of the class object
 *  @param dictionaryKeyPath  A dictionary key path
 *  @param dictionaryValue The value of the dictionaryKeyPath
 *
 *  @return Retuns the mapped value for the dictionaryKeyPath
 */
typedef id(^DHNDictionaryKeyPathToPropertyMappingBlock)(NSString *propertKey, NSString *dictionaryKeyPath, id dictionaryValue);

/**
 *  A Mapping block for mapping a dictionary value to a class object
 *
 *  @param dictionaryKeyPath A key path from the data dictionary
 *  @param dictionaryValue    The value of dictionaryKeyPath
 */
typedef void(^DHNMappingBlock)(NSString *dictionaryKeyPath, id dictionaryValue);

/**
 *  A configuration for DHNObjectMapping
 */
@interface DHNObjectMappingConfiguration : NSObject

/**
 *  Gets all specified key paths in the mapping configuration
 *
 *  @return An array containing all key paths in the mapping configuration
 */
- (NSArray *)allKeyPaths;

/**
 *  Sets the mapping for a dictionary key path to an object property
 *
 *  @param dictionaryKeyPath A source key path to map to the object
 *  @param propertyKey      A property key that gets mapped to the value of dictionaryKeyPath
 */
- (void)setMappingFromDictionaryKeyPath:(NSString *)dictionaryKeyPath
                         toPropertyKey:(NSString *)propertyKey;

/**
 *  Sets the mapping for a dictionary key path to an object property with a block that performs the mapping
 *
 *  @discussion If the block returndes nil the value of the property is set to the value of the property key directly. 
 *  If you need to avoid this behaviour return kDHNMappingByDefault in the block.
 *
 *  @param dictionaryKeyPath A key path to map
 *  @param propertyKey      A property key that is mappet to the dictionaryKeyPath
 *  @param mappingBlock     A DHNDictionaryKeyPathToPropertyMappingBlock that perfomes the mapping
 *
 */
- (void)setMappingFromDictionaryKeyPath:(NSString *)dictionaryKeyPath
                         toPropertyKey:(NSString *)propertyKey
                             withBlock:(DHNDictionaryKeyPathToPropertyMappingBlock)mappingBlock;

/**
 *  Sets the mapping for a dictionary key path to an object property.
 *
 *  @dicussion The mapping is performed by creating an instance of objectClass and performing the NSObject+DHNObjectMapping. The propertyKey will contain a maped instance of objectClass as value after the maping is performed.
 *
 *  @param dictionaryKeyPath A key path to map
 *  @param propertyKey      A property key that is mappet to the dictionaryKeyPath
 *  @param objectClass      A class that is used to map the dictionaryKeyPath to propertyKey.
 *
 */
- (void)setMappingFromDictionaryKeyPath:(NSString *)dictionaryKeyPath
                         toPropertyKey:(NSString *)propertyKey
                             withClass:(Class)objectClass;

/**
 *  Sets the mapping for a dictionary key path
 *
 *  @discussion The set mapping is not bound to a specific property. Do all the required mapping and assignments within the block.
 *
 *  @param dictionaryKeyPath A key path to map
 *  @param mappingBlock     A DHNMappingBlock that maps the attributes value
 */
- (void)setMappingForDictionaryKeyPath:(NSString *)dictionaryKeyPath
                            withBlock:(DHNMappingBlock)mappingBlock;

@end

/**
 *  This category enables mapping from a NSDictionary representation to a objective-c object representation.
 *
 */
@interface NSObject (DHNObjectMapping)

/**
 *  Creates a new object from a NSDictionary representation
 *
 *  @param dictionary  A NSDictionary representation
 *
 *  @return A object that properties are maped to the values of the dictionary
 */
+ (instancetype)dhn_objectWithDictionary:(NSDictionary *)dictionary;

/**
 *  Creates a new object from an array of  NSDictionary representations of the receiving object.
 *
 *  @param dictionaryRepresentations An array of  NSDictionary representations
 *
 *  @return Returns an array of objects that properties are maped to the values of the dictionary 
 *  representations contained in the dictionaryRepresentations.
 */
+ (NSArray *)dhn_arrayOfObjectsWithArray:(NSArray *)dictionaryRepresentations;

/**
 *  Creates a new object from a NSDictionary representation in a managed object context
 *
 *  @param dictionary A NSDictionary representation
 *  @param context    A NSManagedObjectContext
 *
 *  @return An object with the mapped values from dictionary , which is created using context
 */
+ (instancetype)dhn_objectWithDictionary:(NSDictionary *)dictionary
                  inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 *  Updates the properties of the object with a NSDictionary representation
 *
 *  @param dictionary           A NSDictionary representation
 *  @param mappingConfiguration A mapping configuration
 *
 *  @discussion This method maps the dictionary keys to the properties of the receiver object using a mapping configuration.
 *  By default the method tryes to map all keys to properties with the same name. To change this behaviour
 *  override this method, change the mappingConfiguration and call super with this altered configuration.
 *
 *  The method will first apply block mappings followed by class mappings and keypath mappings. Attributes with no
 *  explicid defined mappings are processed with the default behaviour.
 *
 */
- (void)dhn_updatePropertiesWithDictionary:(NSDictionary *)dictionary
                          andConfiguration:(DHNObjectMappingConfiguration *)mappingConfiguration;

/**
 *  Tests if a value is valid
 *
 *  @param value A value
 *
 *  @return YES if valid NO if not.
 */
- (BOOL)dhn_isValidValue:(id)value;

@end
