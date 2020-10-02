# Regenerate crypto certificates using updated crypto-config
../bin/cryptogen extend --config=./crypto-config.yaml
sudo ../bin/configtxgen -profile OneOrgOrdererGenesis -outputBlock ./config/genesis.block

# Start the peer container
docker-compose -f docker-compose.yml up -d peer0.org1.example.com peer1.org1.example.com cli

# Fetch genesis block of the channel for peer1
docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp peer1.org1.example.com peer channel fetch oldest allarewelcome.block -c allarewelcome --orderer orderer.example.com:7050

# Join peer1 to the current channel
docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp peer1.org1.example.com peer channel join -b allarewelcome.block 

# Check if peer0 is joined to allarewelcome
docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp peer0.org1.example.com peer channel list

# Check if peer1 is joined to allarewelcome
docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp peer1.org1.example.com peer channel list

