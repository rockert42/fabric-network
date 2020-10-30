rm ./config/genesis.block

../bin/configtxgen -profile OneOrgOrdererGenesis -outputBlock ./config/genesis.block

docker-compose -f docker-compose.yml up -d zookeeper1.example.com zookeeper2.example.com zookeeper3.example.com kafkaA.example.com kafkaB.example.com
 
sleep 30

docker-compose -f docker-compose.yml up -d Org1ca.example.com Org2ca.example.com orderer.example.com peer0.org1.example.com peer1.org1.example.com peer0.org2.example.com peer1.org2.example.com cli