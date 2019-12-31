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

@property (nullable, nonatomic, retain) NSData *uniqueId;
@property (nullable, nonatomic, retain) NSSet<DSCreditFundingTransactionEntity *> *creditFundingTransactions;
@property (nullable, nonatomic, retain) NSSet<DSBlockchainIdentityKeyPathEntity *> *keyPaths;
@property (nullable, nonatomic, retain) DSContactEntity *ownContact;
@property (nullable, nonatomic, retain) NSSet<DSTransitionEntity *> *transitions;
@property (nullable, nonatomic, retain) DSChainEntity *chain;

@end

@interface DSBlockchainIdentityEntity (CoreDataGeneratedAccessors)

- (void)addCreditFundingTransactionsObject:(DSCreditFundingTransactionEntity *)value;
- (void)removeCreditFundingTransactionsObject:(DSCreditFundingTransactionEntity *)value;
- (void)addCreditFundingTransactions:(NSSet<DSCreditFundingTransactionEntity *> *)values;
- (void)removeCreditFundingTransactions:(NSSet<DSCreditFundingTransactionEntity *> *)values;

- (void)addKeyPathsObject:(DSBlockchainIdentityKeyPathEntity *)value;
- (void)removeKeyPathsObject:(DSBlockchainIdentityKeyPathEntity *)value;
- (void)addKeyPaths:(NSSet<DSBlockchainIdentityKeyPathEntity *> *)values;
- (void)removeKeyPaths:(NSSet<DSBlockchainIdentityKeyPathEntity *> *)values;

- (void)addTransitionsObject:(DSTransitionEntity *)value;
- (void)removeTransitionsObject:(DSTransitionEntity *)value;
- (void)addTransitions:(NSSet<DSTransitionEntity *> *)values;
- (void)removeTransitions:(NSSet<DSTransitionEntity *> *)values;

@end

NS_ASSUME_NONNULL_END
