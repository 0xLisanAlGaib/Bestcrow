-include .env

build:; forge build --root contracts

deploy:; forge script contracts/script/DeployBestcrow.s.sol:DeployBestcrow --rpc-url=${HOLESKY_RPC_URL} --private-key=${PRIVATE_KEY_ADMIN} --broadcast --root contracts

verify:; forge verify-contract \
    0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 \
    src/Bestcrow.sol:Bestcrow \
    --chain-id 17000 \
    --compiler-version 0.8.24 \
    --verifier-url https://api-holesky.etherscan.io/api \
    --etherscan-api-key ${ETHERSCAN_API_KEY} \
    --root contracts

escrow-view:; cast call --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "escrowDetails(uint256)(address,address,address,uint256,uint256,bool,bool,bool,bool)" 4

escrow-next-id:; cast call --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "nextEscrowId()(uint256)"

escrow-get-depositor:; cast call --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "getEscrowDepositor(uint256)(address)" 1


escrow-m-create:; cast send --json --value=1005000000000000 --private-key=${PRIVATE_KEY_1} --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "createEscrow(address,uint256,uint256,address,string,string)(uint256)" 0x0000000000000000000000000000000000000000 1000000000000000 $$(( $$(date +%s) + 86400 )) ${DEV_2} "Manual Escrow" "Created via manual command"

escrow-m-accept:; cast send --value=500000000000000 --private-key=${PRIVATE_KEY_2} --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "acceptEscrow(uint256)" 9

escrow-m-reject:; cast send --private-key=${PRIVATE_KEY_2} --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "rejectEscrow(uint256)" 9

escrow-m-request:; cast send --private-key=${PRIVATE_KEY_2} --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "requestRelease(uint256)" 9

escrow-m-approve:; cast send --private-key=${PRIVATE_KEY_1} --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "approveRelease(uint256)" 9

escrow-m-withdraw:; cast send --private-key=${PRIVATE_KEY_ADMIN} --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "withdrawFees(address)" 0x0000000000000000000000000000000000000000

escrow-m-refund:; cast send --private-key=${PRIVATE_KEY_1} --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "refundExpiredEscrow(uint256)" 2

 
escrow-create:; cast send --json --value=1005000000000000 --private-key=${PRIVATE_KEY_1} --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "createEscrow(address,uint256,uint256,address,string,string)(uint256)" 0x0000000000000000000000000000000000000000 1000000000000000 $$(( $$(date +%s) + 86400 )) ${DEV_2} "Test Escrow" "Test description to be used in tests" | jq -r '.logs[0].topics[1]' | cast --to-dec > .escrow-id

escrow-accept:; cast send --value=500000000000000 --private-key=${PRIVATE_KEY_2} --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "acceptEscrow(uint256)" $$(cat .escrow-id)

escrow-reject:; cast send --private-key=${PRIVATE_KEY_2} --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "rejectEscrow(uint256)" $$(cat .escrow-id)

escrow-request:; cast send --private-key=${PRIVATE_KEY_2} --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "requestRelease(uint256)" $$(cat .escrow-id)

escrow-approve:; cast send --private-key=${PRIVATE_KEY_1} --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "approveRelease(uint256)" $$(cat .escrow-id)

escrow-withdraw:; cast send --private-key=${PRIVATE_KEY_ADMIN} --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "withdrawFees(address)" 0x0000000000000000000000000000000000000000

escrow-e2e:; make escrow-create && sleep 5 && make escrow-accept && sleep 5 && make escrow-request && sleep 5 && make escrow-approve && sleep 5 && make escrow-withdraw

escrow-e2e-active:; make escrow-create && sleep 5 && make escrow-accept

escrow-e2e-request:; make escrow-create && sleep 5 && make escrow-accept && sleep 5 && make escrow-request


escrow-r-create:; cast send --json --value=1005000000000000 --private-key=${PRIVATE_KEY_1} --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "createEscrow(address,uint256,uint256,address,string,string)(uint256)" 0x0000000000000000000000000000000000000000 1000000000000000 $$(( $$(date +%s) + 60 )) ${DEV_2} "Refund Test" "Created for refund testing" | jq -r '.logs[0].topics[1]' | cast --to-dec > .escrow-id

escrow-r-refund:; cast send --private-key=${PRIVATE_KEY_1} --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "refundExpiredEscrow(uint256)" $$(cat .escrow-id)

escrow-r-e2e:; make escrow-r-create && sleep 70 && make escrow-r-refund


escrow-reject-create:; cast send --json --value=1005000000000000 --private-key=${PRIVATE_KEY_1} --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "createEscrow(address,uint256,uint256,address,string,string)(uint256)" 0x0000000000000000000000000000000000000000 1000000000000000 $$(( $$(date +%s) + 86400 )) ${DEV_2} "Reject Test" "Created for reject testing" | jq -r '.logs[0].topics[1]' | cast --to-dec > .escrow-id

escrow-reject-reject:; cast send --private-key=${PRIVATE_KEY_2} --rpc-url=${HOLESKY_RPC_URL} 0x7Ebd1370491e6F546841bD02ed0772a0c4DAC3B6 "rejectEscrow(uint256)" $$(cat .escrow-id)

escrow-reject-e2e:; make escrow-reject-create && sleep 10 && make escrow-reject-reject


escrow-ca:; make escrow-create && cat .escrow-id && sleep 5 && make escrow-accept