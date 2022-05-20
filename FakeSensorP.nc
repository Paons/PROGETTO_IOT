/**
 *  Source file for implementation of module Middleware
 *  which provides the main logic for middleware message management
 *
 *  @author Luca Pietro Borsani
 */
 
generic module FakeSensorP() {

	provides interface Read<uint16_t>;
	
	uses interface Random;
	uses interface Timer<TMilli> as Timer0;

} implementation {

	//***************** Boot interface ********************//
	command error_t Read.read(){
		call Timer0.startOneShot( 10 );
		return SUCCESS;
	}

	//***************** Timer0 interface ********************//
	event void Timer0.fired() {
	
	switch (call Random.rand16()%10){
	
	//prob 0,1
	case 0:
	signal Read.readDone( SUCCESS, 4 );
	break;
	
	//prob 0,3
	case 1: 
	signal Read.readDone( SUCCESS, 1 );
	break;
	case 2: 
	signal Read.readDone( SUCCESS, 1 );
	break;
	case 3: 
	signal Read.readDone( SUCCESS, 1 );
	break;
	
	//prob 0,3
	case 4:
	signal Read.readDone( SUCCESS, 2 );
	break;
	case 5: 
	signal Read.readDone( SUCCESS, 2 );
	break;
	case 6: 
	signal Read.readDone( SUCCESS, 2 );
	break;
	
	//prob 0,3
	case 7: 
	signal Read.readDone( SUCCESS, 3 );
	break;
	case 8: 
	signal Read.readDone( SUCCESS, 3 );
	break;
	default: 
	signal Read.readDone( SUCCESS, 3 );
	break;
		
	}
	
	
		
	}
}
