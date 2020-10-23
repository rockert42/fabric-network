# Generate channel configuration transaction for OrgTwoChannel
../bin/configtxgen -profile OrgTwoChannel -outputCreateChannelTx ./config/OrgTwoChannel.tx -channelID orgtwochannel

# Generate channel configuration transaction for AllAreWelcomeTwo
../bin/configtxgen -profile AllAreWelcomeTwo -outputCreateChannelTx ./config/AllAreWelcomeTwo.tx -channelID allarewelcometwo

# Create channel allarewelcometwo using Org2
docker exec \
  -e CORE_PEER_LOCALMSPID=Org2MSP \
  -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  cli \
  peer channel create -o orderer.example.com:7050 -f ./config/AllAreWelcomeTwo.tx -c allarewelcometwo

# Create channel orgtwo channel using Org2
docker exec \
  -e CORE_PEER_LOCALMSPID=Org2MSP \
  -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  cli \
  peer channel create -o orderer.example.com:7050 -f ./config/OrgTwoChannel.tx -c orgtwochannel

# Join orgtwochannel with Org2
docker exec \
  -e CORE_PEER_LOCALMSPID=Org2MSP \
  -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  cli \
  peer channel join -o orderer.example.com:7050 -b ./orgtwochannel.block

# How the hell is it possible to join orgtwochannel with Org1?
docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli \
  peer channel join -o orderer.example.com:7050 -b ./orgtwochannel.block

docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli \
  peer channel list
