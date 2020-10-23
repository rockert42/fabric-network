# This command is not in the training, but is required for me to make chaincode installation work
docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli \
  go get github.com/hyperledger/fabric-chaincode-go/shim

echo "Going to sleep for 5s before installing chaincode"
sleep 5s

# Install version 1.1 on peer 0
docker exec \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  cli \
  peer chaincode install -n ccForAll -v 1.1 -p github.com/sacc

# Upgrade chaincode to version 1.1 on channel allarewelcome
docker exec \
  -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
  cli \
  peer chaincode upgrade -n ccForAll -v 1.1 -C allarewelcome -c '{"Args":["Mach","50"]}' --policy "AND('Org1.peer','Org2.peer', OR('Org1.member','org2.peer'))"

# List instantiated chaincode on channel allarewelcome
docker exec \
  -e CORE_PEER_LOCALMSPID=Org1MSP \
  -e CORE_PEER_ADDRESS=peer1.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli \
  peer chaincode list --instantiated -C allarewelcome
