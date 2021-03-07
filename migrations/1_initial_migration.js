const EtherRent = artifacts.require("EtherRent.sol");
const MultisigSender = artifacts.require("MultisigSender.sol")
module.exports = function (deployer) {
  deployer.deploy(EtherRent);
  deployer.deploy(MultisigSender);
};
