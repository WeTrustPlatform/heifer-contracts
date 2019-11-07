pragma solidity ^0.5.2;

import "./ERC20TokenInterface.sol";


contract Heifer {
  ERC20TokenInterface public tokenContract;  // public - allow easy verification of token contract.
  address[] public committees;
  mapping(address => User) public members;

  struct User {
    uint256 credit;  // amount of funds user has contributed - winnings (not including discounts) so far
    bool isCommittee; // true if user is a committee member
    bool isAlive; // needed to check if a member is indeed a member
  }

  /////////
  // EVENTS
  /////////
  event Contribution(address indexed user, uint256 amount);

  ////////////
  // MODIFIERS
  ////////////
  modifier onlyFromMember {
    require(members[msg.sender].isAlive, "Member only");
    _;
  }

  constructor( ERC20TokenInterface erc20tokenContract,  // pass 0 to use ETH
               address[] memory _committees,
               address[] memory _members) public {
    tokenContract = erc20tokenContract;
    for (uint8 i = 0; i < _committees.length; i++) {
      addCommitteeMember(_committees[i]);
    }
    for (uint8 i = 0; i < _members.length; i++) {
      addMember(_members[i]);
    }
  }

  ////////////
  // FUNCTIONS
  ////////////

  function contribute() external payable onlyFromMember {
    User storage member = members[msg.sender];
    uint256 value = validateAndReturnContribution();
    member.credit += value;
    emit Contribution(msg.sender, value);
  }

  function validateAndReturnContribution() internal returns (uint256) {  // dontMakePublic
    bool isEthRosca = (address(tokenContract) == address(0));
    require(isEthRosca || msg.value <= 0, "This token contract does not accept receiving ETH");  // token ROSCAs should not accept ETH

    uint256 value = (isEthRosca ? msg.value : tokenContract.allowance(msg.sender, address(this)));
    require(value != 0, "Should have a value");

    if (isEthRosca) {
      return value;
    }
    require(tokenContract.transferFrom(msg.sender, address(this), value), "Should be able to transfer from token contract");
    return value;
  }

  function addCommitteeMember(address user) internal {
    members[user] = User({credit: 0, isCommittee: true, isAlive: true});
  }

  // TODO: Can we add members on the fly (make it external)?
  function addMember(address user) internal {
    require(!members[user].isAlive, "User already existed");  // already registered
    members[user] = User({credit: 0, isCommittee: false, isAlive: true});
  }
}