//
//  DSBlockchainIdentityEntity+CoreDataProperties.h
//  DashSync
//
//  Created by Sam Westrich on 12/31/19.
//
//

#import "DSBlockchainIdentityEntity+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface DSBlockchainIdentityEntity (CoreDataProperties)

+ (NSFetchRequest<DSBlockchainIdentityEntity *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSData *uniqueID;
@property (nonatomic, assign) uint16_t type;
@property (nonatomic, assign) uint16_t registrationStatus;
@property (nonatomic, assign) uint64_t creditBalance;
@property (nullable, nonatomic, retain) NSSet<DSCreditFundingTransactionEntity *> *topUpFundingTransactions;
@property (nullable, nonatomic, retain) DSCreditFundingTransactionEntity *registrationFundingTransaction;
@property (nullable, nonatomic, retain) NSSet<DSBlockchainIdentityKeyPathEntity *> *keyPaths;
@property (nullable, nonatomic, retain) DSContactEntity *ownContact;
@property (nullable, nonatomic, retain) NSSet<DSTransitionEntity *> *transitions;
@property (nullable, nonatomic, retain) NSSet<DSBlockchainIdentityUsernameEntity *> *usernames;
@property (nullable, nonatomic, retain) DSChainEntity *chain;

@end

@interface DSBlockchainIdentityEntity (CoreDataGeneratedAccessors)

- (void)addTopUpFundingTransactionsObject:(DSCreditFundingTransactionEntity *)value;
- (void)removeTopUpFundingTransactionsObject:(DSCreditFundingTransactionEntity *)value;
- (void)addTopUpFundingTransactions:(NSSet<DSCreditFundingTransactionEntity *> *)values;
- (void)removeTopUpFundingTransactions:(NSSet<DSCreditFundingTransactionEntity *> *)values;

- (void)addKeyPathsObject:(DSBlockchainIdentityKeyPathEntity *)value;
- (void)removeKeyPathsObject:(DSBlockchainIdentityKeyPathEntity *)value;
- (void)addKeyPaths:(NSSet<DSBlockchainIdentityKeyPathEntity *> *)values;
- (void)removeKeyPaths:(NSSet<DSBlockchainIdentityKeyPathEntity *> *)values;

- (void)addUsernamesObject:(DSBlockchainIdentityUsernameEntity *)value;
- (void)removeUsernamesObject:(DSBlockchainIdentityUsernameEntity *)value;
- (void)addUsernames:(NSSet<DSBlockchainIdentityUsernameEntity *> *)values;
- (void)removeUsernames:(NSSet<DSBlockchainIdentityUsernameEntity *> *)values;

- (void)addTransitionsObject:(DSTransitionEntity *)value;
- (void)removeTransitionsObject:(DSTransitionEntity *)value;
- (void)addTransitions:(NSSet<DSTransitionEntity *> *)values;
- (void)removeTransitions:(NSSet<DSTransitionEntity *> *)values;

@end

NS_ASSUME_NONNULL_END
