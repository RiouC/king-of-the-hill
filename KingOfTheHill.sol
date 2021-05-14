// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Pour remix il faut importer une url depuis un repository github
// Depuis un project Hardhat ou Truffle on utiliserait: import "@openzeppelin/ccontracts/utils/Address.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol";
import "./Ownable.sol";


/** 
 * @title King Of The Hill
 * @notice Implements basic king of the hill game
 * @dev receive function is not handled yet
 */
contract KingOfTheHill is Ownable {
    using Address for address payable;

    // Storage
    address private _potOwner;
    uint256 private _pot;
    uint256 private _blockNumber;
    uint256 private constant NB_BLOCK_PER_TURN = 10;
    
    // Events
    event Outbided(address indexed account, uint256 pot);
    event IsNewTurn(bool indexed isNewTurn);

    constructor(address owner_) payable Ownable(owner_) {
        require(msg.value > 0, "KingOfTheHill (constructor) : Need a seed");
        _potOwner = owner_;
        _pot = msg.value;
        _blockNumber = block.number;
    }

    // modifiers
    
    
    receive() external payable {
        revert("You cannot send ether directly to this smart-contract, use outbid instead");
    }

    fallback() external {}
    
    /**
     * @notice Allows a player to outbid and become the king of the hill
     * @dev outbid calls the private _newTurn function under the hood
     */
    function outbid() public payable {
        if (block.number - _blockNumber >= NB_BLOCK_PER_TURN) {
            _newTurn();
            emit IsNewTurn(true);
        } else {
            emit IsNewTurn(false);
        }
        require(msg.value >= 2 * _pot, "KingOfTheHill (outbid) : You have to send 2 times the pot value");
        require(msg.sender != _potOwner, "KingOfTheHill (outbid) : You cannot outbid on your own bid");
        uint256 diff = msg.value - 2 * _pot;
        _pot += 2 * _pot;
        _potOwner = msg.sender;
        _blockNumber = block.number;
        emit Outbided(_potOwner, _pot);
        payable(msg.sender).sendValue(diff);
    }
    
    /**
     * @notice This function is triggered when a new turn begin
     * @dev We need to reset to a neutral value (address 0) in case the winner of the previous turn and the first bidder of the current turn are the same person.
     */
    function _newTurn() private {
        uint256 potOwnerReward = (80 * _pot) / 100;
        uint256 ownerReward = (10 * _pot) / 100;
        _pot -= potOwnerReward;
        _pot -= ownerReward;
        payable(_potOwner).sendValue(potOwnerReward);
        payable(owner()).sendValue(ownerReward);
        _potOwner = address(0);
    } 
    
    // getters
    
    /**
     * @return The current pot owner
     */
    function potOwner() public view returns (address) {
        return _potOwner;
    }
    
    /**
     * @return The current amount in the pot
     */
    function pot() public view returns (uint256) {
        return _pot;
    }
    
    /**
     * @return The block number of the first block of the current turn
     */
    function blockNumber() public view returns (uint256) {
        return _blockNumber;
    }
    
    /**
     * @dev if you have deployed this contract at the same address on different chain.id, the returned value will be different.
     * @return The current block number
     */
    function currentBlock() public view returns (uint256) {
        return block.number;
    }
}
