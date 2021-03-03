const EtherRent = artifacts.require("EtherRent.sol");

module.exports = function (deployer) {
  deployer.deploy(EtherRent);
};
