//
//  DSBlockchainIdentityTopupTransition.h
//  DashSync
//
//  Created by Sam Westrich on 7/30/18.
//

#import "BigIntTypes.h"
#import "DSTransition.h"

@class DSECDSAKey, DSChain;

@interface DSBlockchainIdentityTopupTransition : DSTransition

@property (nonatomic, assign) uint16_t blockchainIdentityTopupTransactionVersion;
@property (nonatomic, readonly) uint64_t topupAmount;

- (instancetype)initWithInputHashes:(NSArray *)hashes inputIndexes:(NSArray *)indexes inputScripts:(NSArray *)scripts inputSequences:(NSArray *)inputSequences outputAddresses:(NSArray *)addresses outputAmounts:(NSArray *)amounts blockchainIdentityTopupTransactionVersion:(uint16_t)version registrationTransactionHash:(UInt256)registrationTransactionHash topupAmount:(uint64_t)topupAmount topupIndex:(uint16_t)topupIndex onChain:(DSChain *)chain;

- (instancetype)initWithBlockchainIdentityTopupTransactionVersion:(uint16_t)version registrationTransactionHash:(UInt256)registrationTransactionHash onChain:(DSChain *)chain;

@end
