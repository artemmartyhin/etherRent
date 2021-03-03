const Web3 = require('web3');
const web3 = new Web3(Web3.givenProvider || 'ws://localhost:8545');
const { expect } = require('chai');
const timeMachine = require('ganache-time-traveler');
const truffleAssert = require('truffle-assertions');

const EtherRent = artifacts.require('EtherRent.sol');

describe('Testset for EtherRent', ()=>{
    let deployer;
    let user1, user2;
    let token;
    let snapshotId;

    before(async()=>{
        [
            deployer,
            user1, user2
        ] = await web3.eth.getAccounts();
        console.log(user1, user2);
        token = await EtherRent.new({from: deployer});
    });
    describe('Token info', ()=>{
        beforeEach(async()=>{
            const snapshot =await timeMachine.takeSnapshot();
            snapshotId=snapshot['result'];
        })
        afterEach(async() => await timeMachine.revertToSnapshot(snapshotId));

        it('Correct name',async()=>{
            expect(await token.name()).to.equal('RentToken');
        });
        it('Correct symbol', async()=>{
            expect(await token.symbol()).to.equal('RTT');
        });
    });
    describe('Start working with contract', ()=>{
        beforeEach(async()=>{
            const snapshot =await timeMachine.takeSnapshot();
            snapshotId=snapshot['result'];
        })
        afterEach(async() => await timeMachine.revertToSnapshot(snapshotId));

        it('Users must have 0 tokens in supply',async()=>{
            expect((await token.balanceOf(user1)).toNumber()).to.equal(0);
            expect((await token.balanceOf(user2)).toNumber()).to.equal(0);
        });
        it('Must recieve ether', async()=>{
            token.BuyTokens({value: web3.utils.toWei('2', 'ether')});
            let actualBalance = web3.eth.getBalance(token.address);
            let expectedBalance = web3.utils.toWei('2', 'ether');
            await assert.deepEqual(actualBalance, expectedBalance, "Balance incorrect!");
        });
    })
});


