../bin/configtxgen -profile OneOrgChannel -outputAnchorPeersUpdate ./config/changeanchorpeerorg1.tx -channelID allarewelcome -asOrg Org1MSP

docker container rm -f cli

docker-compose -f docker-compose.yml up -d cli

docker exec \
  -e CORE_PEER_ADDRESS=peer1.org1.example.com:7051 \
  -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
  cli \
  peer channel update -o orderer.example.com:7050 -c allarewelcome -f ./config/changeanchorpeerorg1.tx

  docker logs peer1.org1.example.com