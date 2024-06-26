set dotenv-load
set export

# @dev used to be able to do $L1 and differentiate parameters in the recipes
L1 := "L1"
L2 := "L2"
NETWORK_ID := env_var('CHAIN1_ID')

# @dev Be aware that NETWORK_ID will become an environment variable that thanks to set export.
# So the recipes require the NETWORK_ID in order to work properly.

# contract deployments
deploy_create2_deployer NETWORK_ID JSON_RPC_URL:
    forge script script/001_Deploy_Create2Deployer.s.sol:DeployCreate2DeployerScript --rpc-url $JSON_RPC_URL --chain-id $NETWORK_ID --sender $SENDER --broadcast --ffi -vvvv

deploy_mock_gateway NETWORK_ID JSON_RPC_URL:
    forge script script/002_Deploy_Axelar_Mocks.s.sol:DeployAxelarMockScript --rpc-url $JSON_RPC_URL --chain-id $NETWORK_ID --sender $SENDER --broadcast --ffi -vvvv

deploy_crosschain_setup NETWORK_ID JSON_RPC_URL:
    forge script script/003_Deploy_CrossChainSetup.s.sol:DeployCrossChainSetupScript --rpc-url $JSON_RPC_URL --chain-id $NETWORK_ID --sender $SENDER --broadcast --ffi -vvvv

deploy_registry LAYER NETWORK_ID JSON_RPC_URL: 
    forge script script/004_Deploy_Registry_${LAYER}.s.sol:DeployRegistry${LAYER}Script --rpc-url $JSON_RPC_URL --chain-id $NETWORK_ID --sender $SENDER --broadcast --ffi -vvvv

deploy_registry_l2 NETWORK_ID JSON_RPC_URL:
    forge script script/004_Deploy_Registry_L2.s.sol:DeployRegistryL2Script --rpc-url $CHAIN2_URL --chain-id $CHAIN2_ID --sender $SENDER --broadcast --ffi -vvvv

deploy_consensus NETWORK_ID JSON_RPC_URL:
    forge script script/005_Deploy_Consensus.s.sol:DeployConsensusScript --rpc-url $JSON_RPC_URL --chain-id $NETWORK_ID --sender $SENDER --broadcast --ffi -vvvv

deploy_message_relayer NETWORK_ID JSON_RPC_URL:
    forge script script/006_Deploy_MessageRelayer.s.sol:DeployMessageRelayerScript --rpc-url $JSON_RPC_URL --chain-id $NETWORK_ID --sender $SENDER --broadcast --ffi -vvvv

deploy_local_contracts:
    echo "Deploying contracts locally"
    just deploy_create2_deployer $CHAIN1_ID $CHAIN1_URL # L1
    just deploy_create2_deployer $CHAIN2_ID $CHAIN2_URL # L2
    just deploy_mock_gateway $CHAIN1_ID $CHAIN1_URL # L1
    just deploy_mock_gateway $CHAIN2_ID $CHAIN2_URL # L2
    just deploy_crosschain_setup $CHAIN1_ID $CHAIN1_URL # L1
    just deploy_crosschain_setup $CHAIN2_ID $CHAIN2_URL # L2
    just deploy_registry $L1 $CHAIN1_ID $CHAIN1_URL # L1
    just deploy_registry $L2 $CHAIN2_ID $CHAIN2_URL # L2
    just deploy_consensus $CHAIN2_ID $CHAIN2_URL # L2
    just deploy_message_relayer $CHAIN1_ID $CHAIN1_URL # L1

# orchestration and testing
test_unit:
    echo "Running unit tests"
    NETWORK_ID=3137 forge test --match-path "test/unit/**/*.sol"

test_coverage:
    NETWORK_ID=3137 forge coverage --report lcov 
    lcov --remove ./lcov.info --output-file ./lcov.info 'config' 'test' 'script' 'DeployerUtils.sol' 'DeploymentUtils.sol' 'AddressUtils.sol' 'StringUtils.sol'
    genhtml lcov.info -o coverage --branch-coverage --ignore-errors category

test_integration skip="false":
    echo "Running integration tests"
    {{ if skip == "skip-deploy" { "echo Skipping deployment" } else { "just deploy_local_contracts" } }}
    forge test --match-path "*/integration/*.t.sol" -vvv

test CONTRACT:
    NETWORK_ID=3137 forge test --mc {{CONTRACT}} -vvvv

test_only CONTRACT TEST:
    NETWORK_ID=3137 forge test --mc {{CONTRACT}} --mt {{TEST}} -vvv