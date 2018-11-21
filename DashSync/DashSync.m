//
//  DSDashSync.m
//  dashsync
//
//  Created by Sam Westrich on 3/4/18.
//  Copyright © 2018 dashcore. All rights reserved.
//

#import "DashSync.h"
#import <sys/stat.h>
#import <mach-o/dyld.h>
#import "NSManagedObject+Sugar.h"
#import "DSMerkleBlockEntity+CoreDataClass.h"
#import "DSTransactionEntity+CoreDataClass.h"
#import "DSChainEntity+CoreDataClass.h"
#import "DSPeerEntity+CoreDataClass.h"

@interface DashSync ()

@end

@implementation DashSync

+ (instancetype)sharedSyncController
{
    static id singleton = nil;
    static dispatch_once_t onceToken = 0;
    
    dispatch_once(&onceToken, ^{
        singleton = [self new];
    });
    
    return singleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // use background fetch to stay synced with the blockchain
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
        
        if ([[DSOptionsManager sharedInstance] retrievePriceInfo]) {
            [[DSPriceManager sharedInstance] startExchangeRateFetching];
        }
        // start the event manager
        [[DSEventManager sharedEventManager] up];
        
        struct stat s;
        self.deviceIsJailbroken = (stat("/bin/sh", &s) == 0) ? YES : NO; // if we can see /bin/sh, the app isn't sandboxed
        
        // some anti-jailbreak detection tools re-sandbox apps, so do a secondary check for any MobileSubstrate dyld images
        for (uint32_t count = _dyld_image_count(), i = 0; i < count && !self.deviceIsJailbroken; i++) {
            if (strstr(_dyld_get_image_name(i), "MobileSubstrate")) self.deviceIsJailbroken = YES;
        }
        
#if TARGET_IPHONE_SIMULATOR
        self.deviceIsJailbroken = NO;
#endif
    }
    return self;
}

-(void)startSyncForChain:(DSChain*)chain
{
    [[[DSChainsManager sharedInstance] chainManagerForChain:chain].peerManager connect];
}

-(void)stopSyncAllChains {
    NSArray * chains = [[DSChainsManager sharedInstance] chains];
    for (DSChain * chain in chains) {
        [[[DSChainsManager sharedInstance] chainManagerForChain:chain].peerManager disconnect];
    }
}

-(void)stopSyncForChain:(DSChain*)chain
{
    [[[DSChainsManager sharedInstance] chainManagerForChain:chain].peerManager disconnect];
}

-(void)wipePeerDataForChain:(DSChain*)chain {
    [self stopSyncForChain:chain];
    [[[DSChainsManager sharedInstance] chainManagerForChain:chain].peerManager removeTrustedPeerHost];
    [[[DSChainsManager sharedInstance] chainManagerForChain:chain].peerManager clearPeers];
    DSChainEntity * chainEntity = chain.chainEntity;
    [DSPeerEntity deletePeersForChain:chainEntity];
    [DSPeerEntity saveContext];
}

-(void)wipeBlockchainDataForChain:(DSChain*)chain {
    [self stopSyncForChain:chain];
    DSChainEntity * chainEntity = chain.chainEntity;
    [DSMerkleBlockEntity deleteBlocksOnChain:chainEntity];
    [DSTransactionHashEntity deleteTransactionHashesOnChain:chainEntity];
    [chain wipeBlockchainInfo];
    [DSTransactionEntity saveContext];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:DSWalletBalanceDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:DSChainBlocksDidChangeNotification object:nil];
    });
}

-(void)wipeMasternodeDataForChain:(DSChain*)chain {
    [self stopSyncForChain:chain];
    NSManagedObjectContext * context = [NSManagedObject context];
    [context performBlockAndWait:^{
        [DSChainEntity setContext:context];
        [DSSimplifiedMasternodeEntryEntity setContext:context];
        DSChainEntity * chainEntity = chain.chainEntity;
        [DSSimplifiedMasternodeEntryEntity deleteAllOnChain:chainEntity];
        DSChainManager * chainManager = [[DSChainsManager sharedInstance] chainManagerForChain:chain];
        [chainManager.peerManager setCount:0 forSyncCountInfo:DSSyncCountInfo_List];
        [chainManager.masternodeManager wipeMasternodeInfo];
        [DSSimplifiedMasternodeEntryEntity saveContext];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%@_%@",chain.uniqueID,LAST_SYNCED_MASTERNODE_LIST]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:DSMasternodeListDidChangeNotification object:nil userInfo:@{DSChainPeerManagerNotificationChainKey:chain}];
            [[NSNotificationCenter defaultCenter] postNotificationName:DSMasternodeListCountUpdateNotification object:nil userInfo:@{DSChainPeerManagerNotificationChainKey:chain}];
        });
    }];
    
}

-(void)wipeSporkDataForChain:(DSChain*)chain {
    [self stopSyncForChain:chain];
    DSChainEntity * chainEntity = chain.chainEntity;
    [DSSporkEntity deleteSporksOnChain:chainEntity];
    DSChainManager * chainManager = [[DSChainsManager sharedInstance] chainManagerForChain:chain];
    [chainManager.sporkManager wipeSporkInfo];
    [DSSporkEntity saveContext];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:DSSporkListDidUpdateNotification object:nil userInfo:@{DSChainPeerManagerNotificationChainKey:chain}];
    });
}

-(void)wipeGovernanceDataForChain:(DSChain*)chain {
    [self stopSyncForChain:chain];
    DSChainEntity * chainEntity = chain.chainEntity;
    [DSGovernanceObjectHashEntity deleteHashesOnChain:chainEntity];
    [DSGovernanceVoteHashEntity deleteHashesOnChain:chainEntity];
    DSChainManager * chainManager = [[DSChainsManager sharedInstance] chainManagerForChain:chain];
    [chainManager.peerManager setCount:0 forSyncCountInfo:DSSyncCountInfo_GovernanceObject];
    [chainManager.peerManager setCount:0 forSyncCountInfo:DSSyncCountInfo_GovernanceObjectVote];
    [chainManager.governanceSyncManager wipeGovernanceInfo];
    [DSGovernanceObjectHashEntity saveContext];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%@_%@",chain.uniqueID,LAST_SYNCED_GOVERANCE_OBJECTS]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:DSGovernanceObjectListDidChangeNotification object:nil userInfo:@{DSChainPeerManagerNotificationChainKey:chain}];
        [[NSNotificationCenter defaultCenter] postNotificationName:DSGovernanceVotesDidChangeNotification object:nil userInfo:@{DSChainPeerManagerNotificationChainKey:chain}];
        [[NSNotificationCenter defaultCenter] postNotificationName:DSGovernanceObjectCountUpdateNotification object:nil userInfo:@{DSChainPeerManagerNotificationChainKey:chain}];
        [[NSNotificationCenter defaultCenter] postNotificationName:DSGovernanceVoteCountUpdateNotification object:nil userInfo:@{DSChainPeerManagerNotificationChainKey:chain}];
    });
}

-(void)wipeWalletDataForChain:(DSChain*)chain forceReauthentication:(BOOL)forceReauthentication {
    [self wipeBlockchainDataForChain:chain];
    if (!forceReauthentication && [[DSAuthenticationManager sharedInstance] didAuthenticate]) {
        [chain wipeWalletsAndDerivatives];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:DSChainStandaloneAddressesDidChangeNotification object:nil userInfo:@{DSChainPeerManagerNotificationChainKey:chain}];
            [[NSNotificationCenter defaultCenter] postNotificationName:DSChainWalletsDidChangeNotification object:nil userInfo:@{DSChainPeerManagerNotificationChainKey:chain}];
            [[NSNotificationCenter defaultCenter] postNotificationName:DSChainStandaloneDerivationPathsDidChangeNotification object:nil userInfo:@{DSChainPeerManagerNotificationChainKey:chain}];
        });
    } else {
    [[DSAuthenticationManager sharedInstance] authenticateWithPrompt:@"Wipe wallets" andTouchId:NO alertIfLockout:NO completion:^(BOOL authenticatedOrSuccess, BOOL cancelled) {
        if (authenticatedOrSuccess) {
            [chain wipeWalletsAndDerivatives];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:DSChainStandaloneAddressesDidChangeNotification object:nil userInfo:@{DSChainPeerManagerNotificationChainKey:chain}];
                [[NSNotificationCenter defaultCenter] postNotificationName:DSChainWalletsDidChangeNotification object:nil userInfo:@{DSChainPeerManagerNotificationChainKey:chain}];
                [[NSNotificationCenter defaultCenter] postNotificationName:DSChainStandaloneDerivationPathsDidChangeNotification object:nil userInfo:@{DSChainPeerManagerNotificationChainKey:chain}];
            });
        }
    }];
    }

}

-(uint64_t)dbSize {
    NSString * storeURL = [[NSManagedObject storeURL] path];
    NSError * attributesError = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:storeURL error:&attributesError];
    if (attributesError) {
        return 0;
    } else {
        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        long long fileSize = [fileSizeNumber longLongValue];
        return fileSize;
    }
}


- (void)performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    //todo this needs to be made per chain
    __block id protectedObserver = nil, syncFinishedObserver = nil, syncFailedObserver = nil;
    __block void (^completion)(UIBackgroundFetchResult) = completionHandler;
    void (^cleanup)(void) = ^() {
        completion = nil;
        if (protectedObserver) [[NSNotificationCenter defaultCenter] removeObserver:protectedObserver];
        if (syncFinishedObserver) [[NSNotificationCenter defaultCenter] removeObserver:syncFinishedObserver];
        if (syncFailedObserver) [[NSNotificationCenter defaultCenter] removeObserver:syncFailedObserver];
        protectedObserver = syncFinishedObserver = syncFailedObserver = nil;
    };
    
    if ([[DSChainsManager sharedInstance] mainnetManager].syncProgress >= 1.0) {
        NSLog(@"background fetch already synced");
        if (completion) completion(UIBackgroundFetchResultNoData);
        return;
    }
    
    // timeout after 25 seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 25*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (completion) {
            NSLog(@"background fetch timeout with progress: %f", [[DSChainsManager sharedInstance] mainnetManager].syncProgress);
            completion(([[DSChainsManager sharedInstance] mainnetManager].syncProgress > 0.1) ? UIBackgroundFetchResultNewData :
                       UIBackgroundFetchResultFailed);
            cleanup();
        }
        //TODO: disconnect
    });
    
    protectedObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationProtectedDataDidBecomeAvailable object:nil
                                                       queue:nil usingBlock:^(NSNotification *note) {
                                                           NSLog(@"background fetch protected data available");
                                                           [[[DSChainsManager sharedInstance] mainnetManager].peerManager connect];
                                                       }];
    
    syncFinishedObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:DSChainPeerManagerSyncFinishedNotification object:nil
                                                       queue:nil usingBlock:^(NSNotification *note) {
                                                           NSLog(@"background fetch sync finished");
                                                           if (completion) completion(UIBackgroundFetchResultNewData);
                                                           cleanup();
                                                       }];
    
    syncFailedObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:DSChainPeerManagerSyncFailedNotification object:nil
                                                       queue:nil usingBlock:^(NSNotification *note) {
                                                           NSLog(@"background fetch sync failed");
                                                           if (completion) completion(UIBackgroundFetchResultFailed);
                                                           cleanup();
                                                       }];
    
    NSLog(@"background fetch starting");
    [[[DSChainsManager sharedInstance] mainnetManager].peerManager connect];
    
    // sync events to the server
    [[DSEventManager sharedEventManager] sync];
    
    //    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"has_alerted_buy_dash"] == NO &&
    //        [WKWebView class] && [[BRAPIClient sharedClient] featureEnabled:BRFeatureFlagsBuyDash] &&
    //        [UIApplication sharedApplication].applicationIconBadgeNumber == 0) {
    //        [UIApplication sharedApplication].applicationIconBadgeNumber = 1;
    //    }
}

@end
