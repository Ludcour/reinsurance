pragma solidity ^0.4.2;

contract Insurance {

	//premium is what you pay to subscribe the policy
	uint    public premium;

	//oracle is the 3rp party in charge of stating if a claim is legit
	address public oracle;

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
	uint EXPIRED=5;
	uint PAID=6;
	uint REJECTED=7;


	//duration, a contract cannot last for ever
	uint public duration;

	//expireTime is when the contract expires
	uint public expireTime;

	function Insurance(){
		// this function use no args because of Truffle limitation
		contractCreator = msg.sender;
		state = CREATED;

	}


	function init(address anOracle,uint aPremium,uint prot,uint ttl) {


		if(state!=CREATED) throw;

		oracle = anOracle;
		premium = aPremium * 1 ether;
		protection = prot * 1 ether;
		duration = ttl * 1 seconds;

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

			expireTime = now + duration;
		}
		else throw;
	}

	function claim(){
		//if expired unlock sum to insurer and destroy contract
		if(now > expireTime){
			state = EXPIRED;
			if(!insurer.send(protection))throw;
		}

		//check if state is ACTIVE
		if(state!=ACTIVE)throw;

		//are you the subscriber?
		if(msg.sender != subscriber)throw;

		//ok, claim registered
		state=CLAIMED;
	}

	function oracleDeclareClaim(bool isTrue){

		//is claimed?
		if(state != CLAIMED)throw;

		//are you the oracle?
		if(msg.sender!=oracle)throw;

		//if claim is legit then send money to subscriber
		if(isTrue){
			state = PAID;
			if(!subscriber.send(protection))throw;

		}else{
			state = REJECTED;
			if(!insurer.send(protection))throw;

		}
	}

	function getState() returns(uint){
		return state;
	}
}