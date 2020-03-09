//
//  Created by Andrew Podkovyrin
//  Copyright © 2019 Dash Core Group. All rights reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://opensource.org/licenses/MIT
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "DSDashPlatform.h"
#import "DPContract.h"
#import "DSChain.h"
#import "DSDAPINetworkService.h"

@interface DSDashPlatform ()

@property (strong, nonatomic) DSChain *chain;
@property (strong, nonatomic, null_resettable) NSMutableDictionary *knownContracts;
@property (strong, nonatomic) DPContract *dashPayContract;
@property (strong, nonatomic) DPContract *dpnsContract;

@end

@implementation DSDashPlatform

- (instancetype)initWithChain:(DSChain *)chain {

    self = [super init];
    if (self) {
        _chain = chain; //must come first
    }
    return self;
}

static NSMutableDictionary *_platformChainDictionary = nil;
static dispatch_once_t platformChainToken = 0;

+ (instancetype)sharedInstanceForChain:(DSChain *)chain {

    NSParameterAssert(chain);

    dispatch_once(&platformChainToken, ^{
        _platformChainDictionary = [NSMutableDictionary dictionary];
    });
    DSDashPlatform *platformForChain = nil;
    @synchronized(self) {
        if (![_platformChainDictionary objectForKey:chain.uniqueID]) {
            platformForChain = [[DSDashPlatform alloc] initWithChain:chain];
            [_platformChainDictionary setObject:platformForChain forKey:chain.uniqueID];
        }
        else {
            platformForChain = [_platformChainDictionary objectForKey:chain.uniqueID];
        }
    }
    return platformForChain;
}

- (DPDocumentFactory *)documentFactoryForBlockchainIdentity:(DSBlockchainIdentity *)blockchainIdentity forContract:(DPContract *)contract {
    DPDocumentFactory *documentFactory = [[DPDocumentFactory alloc] initWithBlockchainIdentity:blockchainIdentity contract:contract onChain:self.chain];
    return documentFactory;
}

+ (NSString *)nameForContractWithIdentifier:(NSString *)identifier {
    if ([identifier isEqualToString:DASHPAY_CONTRACT]) {
        return @"DashPay";
    }
    else if ([identifier isEqualToString:DPNS_CONTRACT]) {
        return @"DPNS";
    }
    return @"Unnamed Contract";
}

- (NSMutableDictionary *)knownContracts {
    if (!_knownContracts) {
        _knownContracts = [NSMutableDictionary dictionaryWithObjects:@[ [self dashPayContract], [self dpnsContract] ] forKeys:@[ DASHPAY_CONTRACT, DPNS_CONTRACT ]];
    }
    return _knownContracts;
}

- (DPContract *)dashPayContract {
    if (!_dashPayContract) {
        _dashPayContract = [DPContract localDashpayContractForChain:self.chain];
    }
    return _dashPayContract;
}

- (DPContract *)dpnsContract {
    if (!_dpnsContract) {
        _dpnsContract = [DPContract localDPNSContractForChain:self.chain];
    }
    return _dpnsContract;
}

@end
