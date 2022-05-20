pragma solidity ^0.4.24;
 
contract SafeMath { //calling the safemath interface to allow us to use mathematical functions in the smart contract
 
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
 
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
 
 
//Calling the ERC-20 interface and all of it's functions
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
 
 
//Function that receives approoval and executes in one call
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
 
//The actual TBOS token contract
 
contract TBOS is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;

    uint8 public decimals;
    uint public _totalSupply;
    uint public threshold = 40;

    address public charityWallet = 0x309B2378DfdF897697B21E7310D595590fc56C24;
    address public binanceWallet = 0x4b78D3561c45E5b3c7ac134f5e4B48200d3A2edF;
    address public developerWallet = 0xFE7c28fF04B9c0c5fe28BDfACd282976ea498cb3;

 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed; //mapping each wallet
 
    constructor() public {
        symbol = "TBOS";
        name = "Two Birds One Stone";
        decimals = 2;
        _totalSupply = 300000;
        balances[developerWallet] = _totalSupply; //assigns the entire available balance to the developer wallet
        emit Transfer(address(0), developerWallet, _totalSupply); 
    }
 
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)]; 
    } //checks the total supply of tokens
 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner]; 
    } //checks the balance of a specified wallet
 
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    } //this is responsible for the transfer of tokens from the total supply to users
 
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    } //checks if the total supply has the amount of tokens that need to be allocated to a user
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        uint tax = tokens / 100;
        tokens = tokens - tax;
        uint developerShare = tax / 2;
        uint charityShare = tax / 2;

        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        balances[to] = safeSub(balances[to], tax);
        balances[developerWallet] = safeAdd(balances[developerWallet], developerShare);
        balances[charityWallet] = safeAdd(balances[charityWallet], charityShare);

        emit Transfer(from, to, tokens);
        emit Transfer(to, developerWallet, developerShare);
        emit Transfer(to, charityWallet, charityShare);
        return true;
    } //this is responsible for transacting tokens between users as well as
    // automatically collecting the tax, it sends it to the relevant wallets
 
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    } //checks if a user has enough balance to perform a transaction
 
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    } //exectues transactions that are of buying and spending of tokens
 
    function thresholdTransfer(uint tokens) public returns (bool success){
        require(balanceOf(charityWallet) >= threshold);

        balances[charityWallet] = safeSub(balances[charityWallet], tokens);
        balances[binanceWallet] = safeAdd(balances[binanceWallet], tokens);

        emit Transfer(charityWallet, binanceWallet, tokens);
        return true;
    }//transfers tokens from the charity wallet to the binance wallet
    //when a certain number of tokens reach the threshold in the charity
    //wallet

    function () public payable {
        revert();
    } //prevents users from directly sending ETH to the contract, this minimises the gas price
}