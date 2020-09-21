# Regenerate crypto certificates using updated crypto-config
../bin/cryptogen extend --config=./crypto-config.yaml
sudo ../bin/configtxgen -profile OneOrgOrdererGenesis -outputBlock ./config/genesis.block
../bin/configtxgen -inspectBlock ./config/genesis.block

# Start the peer container
docker-compose -f docker-compose.yml up -d peer0.org1.example.com peer1.org1.example.com cli

# The following command is not in the training, but might be required if the next step fails
# docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel create -o orderer.example.com:7050 -c allarewelcome -f /etc/hyperledger/configtx/allarewelcome.tx

# Fetch genesis block of the channel for peer1
docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp peer1.org1.example.com peer channel fetch oldest allarewelcome.block -c allarewelcome --orderer orderer.example.com:7050

# Join peer1 to the current channel
docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp peer1.org1.example.com peer channel join -b allarewelcome.block 

# Check if peer1 is joined to the channel
docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp peer1.org1.example.com peer channel list

# Check if peer0 is joined to allarewelcome. If not execute the 2 commented commands
docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp peer0.org1.example.com peer channel list
# docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel create -o orderer.example.com:7050 -c allarewelcome -f /etc/hyperledger/configtx/allarewelcome.tx
# docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp peer0.org1.example.com peer channel join -b allarewelcome.block 