const { ethers, upgrades } = require("hardhat");

// TO DO: Place the address of your proxy here!
const proxyAddress = "0x2a927dd249df72A8c73E74EEE40C45e697551251";

async function main() {

    const Bingo = await ethers.getContractFactory("Bingo");
    const upgraded = await upgrades.upgradeProxy(proxyAddress, Bingo);

    console.log(await upgraded.getAddress());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });