#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>

@interface Birthday : NSObject {
	NSString *name;
	NSUInteger year;
	NSUInteger month;
	NSUInteger day;
}

@property(copy) NSString *name;
@property NSUInteger year;
@property NSUInteger month;
@property NSUInteger day;


+ (Birthday*) birthdayWithYear: (NSUInteger) y
						 month: (NSUInteger) m
						   day: (NSUInteger) d
						  name: (NSString*) n;

+ (Birthday*) birthdayWithPerson: (ABPerson*) p;

+ (Birthday*) birthdayWithDate: (NSDate*) d
						  name: (NSString*) n;

- (id) initWithYear: (NSUInteger) y
			  month: (NSUInteger) m
				day: (NSUInteger) d
			   name: (NSString*) n;

- (NSComparisonResult) compare: (Birthday*) o;

- (NSString*) descriptionWithAgeIn: (NSUInteger) age_in_year;

- (void) output;

- (void) outputReverseVideo: (BOOL) reverse;

- (void) outputWithAgeIn: (NSUInteger) age_in_year;

- (void) outputWithAgeIn: (NSUInteger) age_in_year
			reverseVideo: (BOOL) reverseVideo;
@end
