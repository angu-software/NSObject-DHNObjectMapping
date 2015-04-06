Pod::Spec.new do |s|
  s.name         = "DHNObjectMapping"
  s.version      = "1.0.0"
  s.summary      = "A category to map the values of a NSDictionary representation of an object to the object’s properties."
  s.description  = <<-DESC
                   NSObject+DHNObjectMapping maps the keys of the dictionary representation to the properties of the data 
                   object by using Key-Value Coding by default. If your data object has a property named equally to a key 
                   in the dictionary representation its value gets mapped to the property on the data object. You can change
                   this default behavior. But in general you only need to handle special mapping for your objects.
                   DESC

  s.homepage     = "https://github.com/dreyhomedev/NSObject-DHNObjectMapping"
  s.license      = "MIT"
  s.author       = "dreyhomedev" 
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/dreyhomedev/NSObject-DHNObjectMapping.git", :tag => s.version}
  s.source_files  = "NSObject+DHNObjectMapping/NSObject+DHNObjectMapping.h", "NSObject+DHNObjectMapping/NSObject+DHNObjectMapping.m"
end
