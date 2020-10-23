# Generate certificates
../bin/cryptogen extend --config=./crypto-config.yaml

ls crypto-config/peerOrganizations

# Put org definition in file
../bin/configtxgen -printOrg Org2MSP > ./config/org2_definition.json

# Find the correct CA _sk file for org1
caOrg1=$(ls crypto-config/peerOrganizations/org1.example.com/ca | grep _sk)
echo "CA Org1:" $caOrg1

# Find the correct CA _sk file for org2
caOrg2=$(ls crypto-config/peerOrganizations/org2.example.com/ca | grep _sk)
echo "CA Org2:" $caOrg2

# Bring the new CA containers up. --remove-orphans will remove the old CA container if it was still running
docker-compose -f docker-compose.yml up -d --remove-orphans

# Fetch latest configuration from the network
docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli \
  peer channel fetch config blockFetchedConfig.pb -o orderer.example.com:7050 -c allarewelcome

# Decode configuration
docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli bash -c \
  "configtxlator proto_decode --input blockFetchedConfig.pb --type common.Block | jq .data.data[0].payload.data.config > configBlock.json"

# Modify current configuration to include the new orgs
docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli bash -c \
  "jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups":{"Org2MSP":.[1]}}}}}' configBlock.json ./config/org2_definition.json > configChanges.json"

# Verify that configChanges.json exists
docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli \
  ls configChanges.json

# Encode original configuration file back to protobuf
docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli bash -c \
  "configtxlator proto_encode --input configBlock.json --type common.Config --output configBlock.pb"

# Encode config file with modifications back to protobuf
docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli bash -c \
  "configtxlator proto_encode --input configChanges.json --type common.Config --output configChanges.pb"

docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli bash -c \
  "configtxlator compute_update --channel_id allarewelcome --original configBlock.pb --updated configChanges.pb --output configProposal_Org2.pb"

docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli bash -c \
  "configtxlator proto_decode --input configProposal_Org2.pb --type common.ConfigUpdate | jq . > configProposal_Org2.json"

# Note: execute this command directly inside the container using: "docker exec -it cli bash" (you might have to set the correct environment variables)
# echo '{"payload":{"header":{"channel_header":{"channel_id":"allarewelcome","type":2}},"data":{"config_update":'$(cat configProposal_Org2.json)'}}}' | jq . > org2SubmitReady.json 

docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli bash -c \
  "configtxlator proto_encode --input org2SubmitReady.json --type common.Envelope --output org2SubmitReady.pb"

docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli bash -c \
  "peer channel signconfigtx -f org2SubmitReady.pb"

docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli bash -c \
  "peer channel update -f org2SubmitReady.pb -c allarewelcome -o orderer.example.com:7050"

# Start the org2 containers (2 peers, 2 couchDBs)
docker-compose -f docker-compose.yml up -d couchdbOrg2Peer0 peer0.org2.example.com couchdbOrg2Peer1 peer1.org2.example.com

docker exec \
  -e CORE_PEER_LOCALMSPID=Org2MSP \
  -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  cli \
  peer channel fetch 0 Org2AddedConfig.block -o orderer.example.com:7050 -c allarewelcome

docker exec \
  -e CORE_PEER_LOCALMSPID=Org2MSP \
  -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  cli \
  peer channel fetch 0 Org2AddedConfig.block -o orderer.example.com:7050 -c allarewelcome

# Join the peers of org 2 to the channel
docker exec \
  -e CORE_PEER_LOCALMSPID=Org2MSP \
  -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  cli \
  peer channel join -b Org2AddedConfig.block

docker exec \
  -e CORE_PEER_LOCALMSPID=Org2MSP \
  -e CORE_PEER_ADDRESS=peer1.org2.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  cli \
  peer channel join -b Org2AddedConfig.block

# Check if the peer is actually joined to the channel
docker exec \
  -e CORE_PEER_LOCALMSPID=Org2MSP \
  -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  cli \
  peer channel list

# Install version 1.0 on each peer
docker exec \
  -e CORE_PEER_LOCALMSPID=Org2MSP \
  -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  cli \
  peer chaincode install -n ccForAll -v 1.2 -p github.com/sacc

docker exec \
  -e CORE_PEER_LOCALMSPID=Org2MSP \
  -e CORE_PEER_ADDRESS=peer1.org2.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  cli \
  peer chaincode install -n ccForAll -v 1.2 -p github.com/sacc

docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli \
  peer chaincode install -n ccForAll -v 1.2 -p github.com/sacc

docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer1.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli \
  peer chaincode install -n ccForAll -v 1.2 -p github.com/sacc

# Check if the new version is installed
docker exec \
  -e CORE_PEER_LOCALMSPID=Org2MSP \
  -e CORE_PEER_ADDRESS=peer1.org2.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  cli \
  peer chaincode list --installed


# Note: this only worked for me when instantiating using Org1
docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli \
  peer chaincode upgrade -n ccForAll -v 1.2 -C allarewelcome -c '{"Args":["Mach","50"]}' --policy "AND('Org1.peer','Org2.peer', OR('Org1.member','Org2.peer'))"

# Verify whether the chaincode is instantiated on the channel using Org2!
docker exec \
  -e CORE_PEER_LOCALMSPID=Org2MSP \
  -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
  cli \
  peer chaincode list --instantiated -C allarewelcome

