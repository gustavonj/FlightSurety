var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "message crunch uncover soda joke sea oxygen neither surround salute girl nation";

// ganache-cli --mnemonic "myth like bonus scare over problem client lizard pioneer submit female collect" -a 40

module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:8545/", 0, 50);
      },
      network_id: "*"// Match any network id
    }
  },
  compilers: {
    solc: {
      version: "^0.4.25"/*,
      optimizer: {
          enabled: true,
          runs: 1000
      },*/
  }
  }
};