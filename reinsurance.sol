pragma solidity ^0.4.2;
contract Insurance { function getState(uint state); }

contract Reinsurance {

	//premium is what you pay to subscribe the policy
	uint    public premium;

	//oracle are the insurance contracts watched by this contract
	address public contract1;
	address public contract2;
	address public contract3;

	//protection is the financial protection provided by the contract
	uint    public protection;

	//insurer is the one who locks his money to fund the protection
	address public insurer;

	//subscriber is who wants the insurance protection
	address public subscriber;

	//contractCreator is who deploys the contract for profit
	address contractCreator;

	//the contract goes through many states
	uint public state;
	uint CREATED=0;
	uint VALID=1;
	uint SUBSCRIBED=2;
	uint ACTIVE=3;
	uint CLAIMED=4;
	uint PAID=5;
	uint REJECTED=6;


	//duration, a contract cannot last for ever
	uint public duration;

	//expireTime is when the contract expires
	uint public expireTime;

	function Insurance(){
		// this function use no args because of Truffle limitation
		contractCreator = msg.sender;
		state = CREATED;

	}


	function init(address contract1,address contract2,address contract3,uint aPremium,uint prot,uint ttl) {


		if(state!=CREATED) throw;

		contractwatched1 = contract1
		contractwatched2 = contract2
		contractwatched3 = contract3
		premium = aPremium * 1 ether;
		protection = prot * 1 ether;


		bool valid;
		//let's check all the var are set
		valid = oracle !=0 && premium !=0 && protection!=0 && duration!=0;
		if (!valid) throw;
        state = VALID;
	}


	function subscribe() payable {
		//is in the proper state?
		if(state != VALID) throw;

		//can't be both subscriber and oracle
		if(msg.sender == oracle) throw;

		//must pay the exact sum
		if(msg.value==premium){
			subscriber=msg.sender;
			state = SUBSCRIBED;
		}
		else throw;
	}

	function back() payable{
	    //check proper state
		if(state != SUBSCRIBED) throw;

		//can't be both backer and oracle
		if(msg.sender == oracle) throw;

		//must lock the exact sum for protection
		if(msg.value==protection){
			insurer=msg.sender;
      	state = ACTIVE;
			//insurer gets his net gain
			if(!insurer.send(premium)) throw; //this prevents re-entrant code

		}
		else throw;
	}

	function checkContractsStates(){
		//if two contracts out of three are triggered then give protection to subscriber
		if(contractwatched1.getState() = 6 && contractwatched2.getState() = 6){
			state = PAID;
			if(!subscriber.send(protection))throw;
		}

		if(contractwatched3.getState() = 6 && contractwatched2.getState() = 6){
			state = PAID;
			if(!subscriber.send(protection))throw;
		}

		if(contractwatched1.getState() = 6 && contractwatched3.getState() = 6){
			state = PAID;
			if(!subscriber.send(protection))throw;
		}

		else{ //else give the money to the insurer
			state = REJECTED;
			if(!insurer.send(protection))throw;
		}

		//check if state is ACTIVE
		if(state!=ACTIVE)throw;

	}

	function getState() returns(uint){
		return state;
	}
}