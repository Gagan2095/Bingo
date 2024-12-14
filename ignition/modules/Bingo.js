const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const TokenModule = buildModule("Bingo", (m) => {
    const token = m.contract("Bingo");

    return { token };
});

module.exports = TokenModule;