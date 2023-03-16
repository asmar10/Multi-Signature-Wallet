// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


error invalidRequiredMembers();
error ownerAddressCantBeZero();
error duplicateAddressesDetected();
error requiredNumberOfApprovalNotfulfilled();
error insufficientFunds();
error invalidAddress();
error transactionAlreadyExecuted();
error youHaveAlreadyApprovedThisTransaction();
error insufficientApprovals();

contract multisig {
    event _deposit(address indexed sender, uint indexed amount);
    event _submit(address indexed receiver, address indexed sender, uint indexed amount);
    event _approved(address indexed owner,  uint indexed txId);

    address[] public owners;
    uint count; 
    uint256 public requiredForApproval;
    mapping(address=> bool ) public exists;
    mapping(uint => bool) isTransactionLive;
    mapping(address=>mapping(uint=>bool)) hasOwnerApproved;
    mapping(uint => transaction) public transactionById;

    struct transaction {
        uint txId;
        address to;
        uint amount;
        address sender;
        uint currentApprovals;
        bool status;
    }
    
    modifier onlyOwner{
        require(exists[msg.sender]==true,"Youre not owner");
        _;
    }

    modifier checkIfTransactionisLive( uint txId){
        require(transactionById[txId].status==false,"transactionAlreadySent");
        _;
    }

    constructor (address[] memory _owners, uint256 _requiredForApproval){
        if(_requiredForApproval<1 || _requiredForApproval >_owners.length){
            revert invalidRequiredMembers();
        }
        for(uint8 i = 0; i<_owners.length; i++){
            if(address(_owners[i]) == address(0) ) {
                revert ownerAddressCantBeZero();
            }
            else if(exists[_owners[i]]==true){
                revert duplicateAddressesDetected();
            }
            owners.push(_owners[i]);
            exists[_owners[i]]=true;
        }
        requiredForApproval=_requiredForApproval;
    }

    function deposit() public payable {
        emit _deposit(msg.sender,msg.value);
    }

    function sendTransaction(uint txId) public onlyOwner {
        if(transactionById[txId].currentApprovals < requiredForApproval){
            revert insufficientApprovals();
        }
        transactionById[txId].status=true;
        payable(transactionById[txId].to).transfer(transactionById[txId].amount);

    }

    function submitTransaction(address _to, uint _amount) public onlyOwner{
        uint amount = _amount *1 ether;
        if(address(this).balance<amount){
            revert insufficientFunds();
        }
        if(_to == address(0)){
            revert invalidAddress();
        }
        count++;
        transaction memory a = transaction(
            count,
            _to,
            amount,
            msg.sender,
            0,
            false
        );
        // Transactions.push(a);
        transactionById[count]=a;
        
        emit _submit(_to, msg.sender, amount);
    }

    function approveTransaction(uint txId) public onlyOwner checkIfTransactionisLive(txId) {
        if(hasOwnerApproved[msg.sender][txId]==true){
            revert youHaveAlreadyApprovedThisTransaction();
        }
        hasOwnerApproved[msg.sender][txId]=true;
        transactionById[txId].currentApprovals++;

        emit _approved(msg.sender, txId);
    }

    function revokeApproval(uint txId) public onlyOwner checkIfTransactionisLive(txId){
     require(hasOwnerApproved[msg.sender][txId]==true,"You havent approved this transaction");
     hasOwnerApproved[msg.sender][txId]=false;
     transactionById[txId].currentApprovals--;

    }
    
    function getTotalTransactions() public view returns(uint  ){
        return count; 
    }

}