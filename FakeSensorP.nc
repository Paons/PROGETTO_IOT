/**
 *  Source file for implementation of module Middleware
 *  which provides the main logic for middleware message management
 *
 *  @author Luca Pietro Borsani
 */
 
generic module FakeSensorP() {

	provides interface Read<sensor_status_t>;
	
	uses interface Random;
	uses interface Timer<TMilli> as Timer0;

} implementation {
	sensor_status_t sensor_status;



	//***************** Boot interface ********************//
	command error_t Read.read(){
		call Timer0.startOneShot( 10 );
		return SUCCESS;
	}

	//***************** Timer0 interface ********************//
	event void Timer0.fired() {
	//uint16_t x = 38946875;
	//uint16_t y = 16641260;
	
	uint32_t x = call Random.rand16() % 300;
	uint32_t y = call Random.rand16() % 300;
	
	sensor_status.x = x + 38946875;
	sensor_status.y = y + 16641260;
	
	switch (call Random.rand16()%10){
	
	//prob 0,1
	case 0:
	//signal Read.readDone( SUCCESS, 4 );
	sensor_status.status = 4;
	break;
	
	//prob 0,3
	case 1: 
	//signal Read.readDone( SUCCESS, 1 );
	sensor_status.status = 1;
	break;
	case 2: 
	//signal Read.readDone( SUCCESS, 1 );
	sensor_status.status = 1;
	break;
	case 3: 
	//signal Read.readDone( SUCCESS, 1 );
	sensor_status.status = 1;
	break;
	
	//prob 0,3
	case 4:
	//signal Read.readDone( SUCCESS, 2 );
	sensor_status.status = 2;
	break;
	case 5: 
	//signal Read.readDone( SUCCESS, 2 );
	sensor_status.status = 2;
	break;
	case 6: 
	//signal Read.readDone( SUCCESS, 2 );
	sensor_status.status = 2;
	break;
	
	//prob 0,3
	case 7: 
	//signal Read.readDone( SUCCESS, 3 );
	sensor_status.status = 3;
	break;
	case 8: 
	//signal Read.readDone( SUCCESS, 3 );
	sensor_status.status = 3;
	break;
	default: 
	//signal Read.readDone( SUCCESS, 3 );
	sensor_status.status = 3;
	break;
		
	}
	signal Read.readDone( SUCCESS, sensor_status);
	
	
		
	}
}
