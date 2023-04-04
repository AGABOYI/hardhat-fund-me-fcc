//Note: For .solhint.json file
//solhint is known as a solidity linter , that we can use to lint our code
//Linting is a process of running a program that will analyse a code for potential errors

///////////////////////////////////////////////////////////////////////////

// What we want to do in this contract ?
// 1- Get funds from users
// 2- Withdraw funds
// 3- Set a minimun funding value in USD

//SPDX-License-Identifier:MIT
//pragma
pragma solidity ^0.8.8;

//Imports
import "./PriceConverter.sol";

// Customized error
error FundMe_NotOwner();

// Interface , Libraries , contracts

/**
 * @title A contract for crowd funding
 * @author Franck Herouane
 * @notice this contract is to demo a sample funding contract
 * @dev This implement price feed as our library
 */
contract FundMe {
    // NB:
    // Well , when working with Contract, we know that state variable cost a lot because they are store in Storage
    // SLOAD(Storage Load word from the storage) take 800 gas, SSTORE (Save word to storage) take 20000 gas
    // So as a developper there is conversion when writing contract for saying that we know that we are working
    // with storage variable and that they will cost us a lot of gas , is to append an s_ right before them s => storage variable

    // memory variable , constant variable and immutable variable do not go in Storage .
    // Also making state variable private is always a good thing to do if our project logic does not really require them
    // to be public beacuse it allow us to save some gas , that's why in this project we have put some variable private and
    // then created some get function() ( scroll down to see)

    using PriceConverter for uint256;
    // gas sans constant key word : 915528
    // gas avec constant key word : 775069
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    // gas sans immutable key word : 751490
    // gas avec immutable key word : 731490
    address private immutable i_owner;
    AggregatorV3Interface public s_priceFeed;

    modifier onlyOwner() {
        // Au lieu d'utiliser require ici on peut utiliser the customize error NotOwner() qui lui nous permet de
        // save some gas

        // require(msg.sender == i_owner, "sender is not i_owner!!!"); or

        if (msg.sender != i_owner) {
            revert FundMe_NotOwner();
        }

        // Veut dire execute mtn le code dans la function qui a onlyOwner
        _;
    }

    // C'est comme init en swift
    constructor(address pricefeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(pricefeedAddress);
    }

    function fund() public payable {
        // We want to be able to set a minimun fund amount in USD
        // How do we send ETH to this contract ?

        require(
            msg.value.getConversionRate(s_priceFeed) >= 1e18,
            "Did not send enough!!!"
        ); // 1e18 == 1 * 10 **(means raise to the ) 18 == 1000000000000000000
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        /* starting index, ending index, step amount */
        /* funderInder++ veut dire funderIndex = funderIndex + 1 */
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the funders array
        s_funders = new address[](0);
        // actually withdraw the funds

        /* 
        To send ETH or any blockchain currency , there are actually 3 ways of doing it :

        transfer : it automatically revert the transaction if the transfert fails!
        payable (msg.sender).transfer(address(this).balance);

        send : it will only revert the transaction if we add "require" and if the trx fails!
        bool sendSuccess = payable (msg.sender).send(address(this).balance);
        require (sendSuccess, "send failed!!!");
        */

        //call : We can use it to call virtually any function in all the ethereum, without even having the ABI
        // And this call function returns 2 variables
        (bool callSuccess /*bytes memory dataReturned*/, ) = payable(msg.sender)
            .call{value: address(this).balance}("");
        require(callSuccess, "Call failed!!");
    }

    // This function will take what we learn on the withdraw function but will more more gas sufficient
    function cheaperWithdraw() public payable onlyOwner {
        // NB: MAPPING CAN NOT BE IN MEMORY , OOPS!!
        // Save our storage variable s_funders into a memory variable
        address[] memory funders = s_funders;

        // Now that we have saved our storage variable into a memory variable,
        // We can now read and write from this memory variable much more cheaper
        // and update storage when we are done

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess /*bytes memory dataReturned*/, ) = payable(msg.sender)
            .call{value: address(this).balance}("");
        require(callSuccess, "Call failed!!");
    }

    // View and pure functions
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(
        address funder
    ) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    // What happens if someone sends this contract ETH without calling  the fund function?
    // Bon je comprends ca ici comme si le gar sends the monney directement par metaMask

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
