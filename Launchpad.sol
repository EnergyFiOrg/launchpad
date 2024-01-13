// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


///@author Okoli Evans
///@title  A contract that holds Initial Coin Offerings (ICO), and can handle multiple
///@title  ICOs at once
///@dev  The contract admin oversees registration and creation of vetted projects for ICO,
///@dev  and also monitors the process, and disburses funds at the end of the ICO.
///@notice  An ID is assigned to every ICO created to for efficient tracking of variables changes and
///@notice  updates.


contract Launchpad {

    struct IFODetail {
        uint32 totalBuyers;
        address admin;
        address token;
        uint32 id;
        uint256 publicshareBalance;
        uint256 MaxCap;
        uint256 minimumSubscription;
        uint256 maximumSubscription;
        uint256 tokenTotalSupply;
        uint256 publicShare;
        uint256 exchangeRate;
        uint256 totalAmountRaised;
        uint256 totalAmountDistributed;
        string tokenName;
        string tokenSymbol;
        bool hasStarted;
        bool maxCapReached;
    }

    mapping(uint32 => IFODetail ) IFODetails_ID;
    mapping(address => mapping(uint32 => uint256)) Amount_per_subscriber;

    address public Controller;
    uint256 public GlobaltotalAmountRaised;
    uint256 public GlobaltotalAmountDistributed;

    /////////  ERRORS  ///////////

    error notController();
    error IFO_Not_Started();
    error IFO_Already_Started();
    error Amount_less_Than_Minimum_Subscription();
    error Amount_greater_Than_Maximum_Subscription();
    error IFO_Not_Ended();
    error IFO_Not_In_Session();
    error IFO_still_in_progress();
    error Value_cannot_be_empty();
    error IFO_Details_Not_Found();
    error MaxCapReached();
    error Insufficient_Funds();
    error Invalid_Address();
    error ID_Taken_Choose_Another_ID();

    ////////  EVENTS  /////////
    event ICO_Created(uint32 _id, address _token);
    event ICO_Started(uint32 _id);
    event BuyPresale(uint32 _id, address _buyer, uint256 _amount);
    event BuyPresale2(uint32 _id, address _buyer, uint256 _amount);
    event ICO_Ended(uint32 _id);
    event Claim_Token(uint32 _id, address _claimer, uint256 _amount);

    constructor() {
        Controller = msg.sender;
    }


   ////////////////////////////////////////////////////////////////
   ///                                                         ////
   ///                     CORE FUNCTIONS                      ////
   ///                                                         ////
   //////////////////////////////////////////////////////////////// 


    function createICO(
        uint32 _id,
        address _admin,
        address _token,
        uint256 _maxCap,
        uint256 _minimumSubscription,
        uint256 _maximumSubscription,
        uint256 _tokenTotalSupply,
        uint256 _publicShare,
        uint256 _exchangeRate,
        string memory _tokenName,
        string memory _tokenSymbol
        ) external  {
        IFODetail storage ifoDetail = IFODetails_ID[_id];
        if(msg.sender != Controller) revert notController();
        if (ifoDetail.hasStarted == true) revert IFO_Already_Started();
        if(_id <= 0) revert Value_cannot_be_empty();
         if(ifoDetail.id == _id) revert ID_Taken_Choose_Another_ID();
        if(_maxCap <= 0) revert Value_cannot_be_empty();
        if(_token == address(0))revert Value_cannot_be_empty();
        if(_minimumSubscription <= 0) revert Value_cannot_be_empty();
        if(_maximumSubscription <= 0) revert Value_cannot_be_empty();
        if(_tokenTotalSupply <= 0) revert Value_cannot_be_empty();
        if(_publicShare <= 0) revert Value_cannot_be_empty();
        if(_exchangeRate <= 0) revert Value_cannot_be_empty();
        if(_admin == address(0)) revert Value_cannot_be_empty();

        bool success = IERC20(_token).transferFrom(_admin, address(this), _tokenTotalSupply);
        require(success, "Transfer FAIL");
       
        ifoDetail.totalBuyers = 0;
        ifoDetail.id = _id;
        ifoDetail.admin = _admin;
        ifoDetail.token = _token;
        ifoDetail.MaxCap = _maxCap;
        ifoDetail.minimumSubscription = _minimumSubscription;
        ifoDetail.maximumSubscription = _maximumSubscription;
        ifoDetail.tokenTotalSupply = _tokenTotalSupply;
        ifoDetail.publicShare = _publicShare;
        ifoDetail.exchangeRate = _exchangeRate;
        ifoDetail.tokenName = _tokenName;
        ifoDetail.tokenSymbol = _tokenSymbol;

        emit ICO_Created(_id, _token);

    }

    function startICO(uint32 _id) external {
        IFODetail storage ifoDetail = IFODetails_ID[_id];
        require(msg.sender == Controller, "only owner can start ICO");
        if (ifoDetail.hasStarted == true) revert IFO_Already_Started();
        if (ifoDetail.id == 0) revert IFO_Details_Not_Found();
        ifoDetail.hasStarted = true;
      
        emit ICO_Started(_id);
    }


    function buyPresale(uint32 _id) external payable {
        uint _amount = msg.value;

        IFODetail storage ifoDetail = IFODetails_ID[_id];
        require(_amount > 0, "Amount must be greater than zero");
        if(ifoDetail.hasStarted == false) revert IFO_Not_In_Session();
        if(_amount < ifoDetail.minimumSubscription ) revert Amount_less_Than_Minimum_Subscription();
        if(ifoDetail.maximumSubscription < _amount) revert Amount_greater_Than_Maximum_Subscription();
        if(ifoDetail.publicShare == 0) revert MaxCapReached();

        uint256 xRate = ifoDetail.exchangeRate;
        uint256 amount_bought = _amount/10**10 * xRate; //for 18 decimal remove /10**10
        ifoDetail.publicShare = ifoDetail.publicShare - amount_bought;
        ifoDetail.publicshareBalance = ifoDetail.publicshareBalance + amount_bought;
        Amount_per_subscriber[msg.sender][_id] = Amount_per_subscriber[msg.sender][_id] + amount_bought;
        
        ifoDetail.totalAmountRaised = ifoDetail.totalAmountRaised + _amount;
        GlobaltotalAmountRaised = GlobaltotalAmountRaised + _amount;
        
        ifoDetail.totalBuyers += 1;

        emit BuyPresale(_id, msg.sender, _amount);
    }

    function buyPresaleRef(uint32 _id, address payable _referral) external payable {
        uint _amount = msg.value;
        address payable _target = _referral;

        IFODetail storage ifoDetail = IFODetails_ID[_id];
        require(_target != msg.sender, "Referral address should be different");
        require(_amount > 0.1 ether, "Amount must be greater than 0.1 BNB");
        // require(_amount > 0, "Amount must be greater than zero");
        if(ifoDetail.hasStarted == false) revert IFO_Not_In_Session();
        if(_amount < ifoDetail.minimumSubscription ) revert Amount_less_Than_Minimum_Subscription();
        if(ifoDetail.maximumSubscription < _amount) revert Amount_greater_Than_Maximum_Subscription();
        if(ifoDetail.publicShare == 0) revert MaxCapReached();

        uint256 xRate = ifoDetail.exchangeRate;
        uint256 amount_bought = _amount/10**10 * xRate; //for 18 decimal remove /10**10
        ifoDetail.publicShare = ifoDetail.publicShare - amount_bought;
        ifoDetail.publicshareBalance = ifoDetail.publicshareBalance + amount_bought;
        Amount_per_subscriber[msg.sender][_id] = Amount_per_subscriber[msg.sender][_id] + amount_bought;
        
        //Send 1% to the referral if user buy more than 0.1 bnb

        _target.transfer(_amount/100); 


        ifoDetail.totalAmountDistributed = ifoDetail.totalAmountDistributed + _amount*1/100;
        GlobaltotalAmountDistributed = GlobaltotalAmountDistributed + _amount*1/100;

        ifoDetail.totalAmountRaised = ifoDetail.totalAmountRaised + _amount*99/100;
        GlobaltotalAmountRaised = GlobaltotalAmountRaised + _amount*99/100;

        ifoDetail.totalBuyers += 1;

        emit BuyPresale2(_id, msg.sender, _amount);
    }

    function endICO(uint32 _id) external {
        IFODetail storage ifoDetail = IFODetails_ID[_id];
        require(msg.sender == Controller, "only owner can end ICO");
        if (ifoDetail.hasStarted == false) revert IFO_Not_In_Session();
        if (ifoDetail.id == 0) revert IFO_Details_Not_Found();

        ifoDetail.hasStarted = false;

        // ifoDetail.MaxCap = 0;
        // ifoDetail.minimumSubscription = 0;
        // ifoDetail.maximumSubscription = 0;

        // ifoDetail.exchangeRate = 0;
        // ifoDetail.tokenName = "";
        // ifoDetail.tokenSymbol = "";
        // ifoDetail.maxCapReached = false;
        emit ICO_Ended(_id);
    }

    function claimToken(uint32 _id) external {
        IFODetail storage ifoDetail = IFODetails_ID[_id];
        require(Amount_per_subscriber[msg.sender][_id] > 0, "No record found");
        if(ifoDetail.hasStarted == true) revert IFO_still_in_progress();

        uint256 _amount = Amount_per_subscriber[msg.sender][_id];
        if(_amount > ifoDetail.publicshareBalance) revert Insufficient_Funds();
        ifoDetail.publicshareBalance = ifoDetail.publicshareBalance - _amount;
       Amount_per_subscriber[msg.sender][_id] = 0;
       IERC20(ifoDetail.token).transfer(msg.sender, _amount);

       emit Claim_Token(_id, msg.sender, _amount);
    }

    function withdrawToken(address _to,uint32 _id, uint256 _amount) external  {
        require(msg.sender == Controller, "only owner can withdraw");
        IFODetail storage ifoDetail = IFODetails_ID[_id];
        if(_to == address(0)) revert Invalid_Address();
        
        IERC20(ifoDetail.token).transfer(_to, _amount);
    }

    function withdrawEther(uint256 _amount, address _to) external {
        require(msg.sender == Controller, "only owner can withdraw");
        if(_amount > address(this).balance) revert Insufficient_Funds();
        if(_to == address(0)) revert Invalid_Address();

        (bool success, ) = payable(_to).call{ value: _amount}("");
        require(success, "Failed to send Ether");
    }


    function getTotalEthRaised() external view returns(uint256){
        return GlobaltotalAmountRaised;
    }

    function getTotalEthDistributed() external view returns(uint256){
        return GlobaltotalAmountDistributed;
    }

    function getStatus(uint32 _id) external view returns(bool){
        IFODetail storage ifoDetail = IFODetails_ID[_id];
        return ifoDetail.hasStarted;
    }

    function getParticipants(uint32 _id) external view returns(uint32){
        IFODetail storage ifoDetail = IFODetails_ID[_id];
        return ifoDetail.totalBuyers;
    }

    function getPublicBalance(uint32 _id) external view returns(uint256){
        IFODetail storage ifoDetail = IFODetails_ID[_id];
        return ifoDetail.publicshareBalance;
    }

    function getAmountPerSubscriber(address _user, uint32 _id) external view returns(uint256) {
        return Amount_per_subscriber[_user][_id];
    }


    receive() payable external {}
    fallback() payable external {}

}