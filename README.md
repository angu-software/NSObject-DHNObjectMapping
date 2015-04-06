# NSObject+DHNObjectMapping

A category to map the values of a NSDictionary representation of an object to the objets properties.

## How it works

### Default behaviour

NSObject+DHNObjectMapping maps the keys of the dictionary representation to the properties of the data object by using [Key-Value Coding](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/KeyValueCoding/Articles/KeyValueCoding.html) by default. If your data object has a property named equally to a key in the dictionary representation its value gets maped to the property on the data object.

```
NSDictionary representation -> Class object
{"name":"This is some name"} -> object.name
```

Undefined keys are ignored by default.

You can implenent other behavour by overriding the ```dhn_updatePropertiesWithDictionary:andConfiguration:``` in your data. See [Override the default mapping behaviour](#overrrideMapping) for more infomtaion.

Therefore you just need to handle special mapping for your objects.

## How to use

Since NSObject+DHNObjectMapping is working with NSDictionarys we need to convert your object data into a NSDictionary representation. There are many ways to achieve this. This depends on the data format youre using. With JSON or Plist-files cocoa provides serializers that does the job for you. If youre using your own special data format you need to convert these data first into an NSDictionary representation.

### Mapping data

To map the data to your cocoa object you just need to call ```dhn_objectWithDictionary:``` with the NSDictionary representation of that object. If you got an array of dictionary representations of the calss to mapp simpry call ```dhn_arrayOfObjectsWithArray:```. It also works with Core Data objects, just call ```dhn_objectWithDictionary:inManagedObjectContext:``` and provicde your the NSManagedObjectContext.

### [Override the default mapping behaviour](id:overrrideMapping)

To override the stadard mapping behaviour you can override ```dhn_updatePropertiesWithDictionary:andConfiguration:``` in your data class. This method will provide a ```DHNObjectMappingConfiguration``` you can adjust to your needs. If you done with specifiing your mapping just call ```[super dhn_updatePropertiesWithDictionary:andConfiguration:]```

The ```DHNObjectMappingConfiguration``` class provides methods to alter the default mapping by setting an new dictionary-key property mapping, setting classes to map embedded dictionay representations or block mappings for special handling.

```
#import "NSObject+DHNObjectMapping.h"
...
- (void)dhn_updatePropertiesWithDictionary:(NSDictionary *)dictionary andConfiguration:(DHNObjectMappingConfiguration *)mappingConfiguration
{
    [mappingConfiguration setMappingFromDictionaryKeyPath:@"someKey" toPropertyKey:@"mappToMe"];
    [mappingConfiguration setMappingFromDictionaryKeyPath:@"someOtherKey"
                                            toPropertyKey:@"someOtherProperty"
                                                withBlock:^id(NSString *propertKey, 
                                                              NSString *dictionaryKey, 
                                                                    id dictionaryData) {
                                                    
                                                    id someValueObject = nil;
                                                    
                                                    // ... Do your mapping and return
                                                    // the value the property should have
                                                    // return kDHNMappingByDefault to use the default behaviour
                                      
                                                    return someValueObject;
                                                    
    }];
    [mappingConfiguration setMappingFromDictionaryKeyPath:@"anotherKey"
                                            toPropertyKey:@"aPropertyOfClassMyClass"
                                                withClass:[MyClass class]];
    
    [mappingConfiguration setMappingForDictionaryKeyPath:@"whatAKey" 
                                              withBlock:^(NSString *dictionaryKeyPath, 
                                                                id dictionaryData) {
       
        // ... do your mapping and assign your values to all properties you like
        // ... this block is not bound to any property of self.
        
    }];

    [super dhn_updatePropertiesWithDictionary:dictionary andConfiguration:mappingConfiguration];
}
```

## Limitations

### Scalar values
Due to the usage of Key-Value coding its not possible to map scalar value properties (e.g. Properties of type BOOL, NSInteger, float, ect.) directly.
