/**
 *
 *  @authors Devan Stoka, Angelo Paone
 */

#include "Bracelets.h"
#include "Timer.h"
#include "string.h"

module BraceletsC {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
	interface SplitControl;
	interface Packet;
    interface AMSend;
    interface Receive;
    interface PacketAcknowledgements;

    interface Timer<TMilli> as MilliTimer;
	
	interface Read<uint16_t>;
  }

} implementation {

  uint8_t counter=0;
  uint8_t phase = 0;
  uint8_t sendAddress;
  uint8_t locked = 0;
  
  message_t packet;

  void sendReq();
  void sendResp();
  
  void sendKey();
  void sendNextStep();
  
  void sendKey(){
  
  if(!locked){
  	
	  my_msg_key* msg = (my_msg_key*)(call Packet.getPayload(&packet, sizeof(my_msg_key)));
	  if (msg == NULL) {
		return;
	  }
	   
	  //saving the address of the mote
	  msg->sendAddress = TOS_NODE_ID;
	  
	  

	  //first couple of bracelets
	  if (TOS_NODE_ID == 1 || TOS_NODE_ID == 2){
	  	strcpy((char*)msg->key, RK1);

	  }
	  //second couple of bracelets
	  else{
	  	strcpy((char*)msg->key, RK2);
	  }
	  
	  //call PacketAcknowledgements.requestAck( &packet );
	  
	  if(call AMSend.send(AM_BROADCAST_ADDR, &packet,sizeof(my_msg_key)) == SUCCESS){
	     dbg("radio_send", "Packet for pairing passed to lower layer successfully!\n"); 
	     locked = 1;
  	  }	  	 
  	  } 
  }
  
  void sendNextStep(){
  
  	if(!locked){

	  my_msg_next* msg = (my_msg_next*)(call Packet.getPayload(&packet, sizeof(my_msg_next)));
	  if (msg == NULL) {
		return;
	  }
	  
	  msg->next = 1;
	  
	  call PacketAcknowledgements.requestAck( &packet );
	  
	  if(call AMSend.send(sendAddress, &packet,sizeof(my_msg_next)) == SUCCESS){
	     dbg("radio_send", "Packet for next step passed to lower layer successfully!\n"); 
	     locked = 1;
  	  }	 
  	  
  	  }
	  
  }
         


  event void Boot.booted() {
	dbg("boot","Application booted.\n");

	call SplitControl.start();
  }


  event void SplitControl.startDone(error_t err){

    if(err == SUCCESS) {
    	dbg("radio", "Radio on!\n");
    	call MilliTimer.startPeriodic( 1000 );
  		//sendKey();
    }
    else{
	dbg("radio", "Radio error!\n");
	call SplitControl.start();
    }
  }
  
  event void SplitControl.stopDone(error_t err){

  }


  event void MilliTimer.fired() {

	 dbg("timer","Timer fired at %s.\n", sim_time_string());
	 
	 if(phase == 0) sendKey();
	 //if(phase == 1) sendNextStep();
  }
  


  event void AMSend.sendDone(message_t* buf,error_t err) {

    if (&packet == buf && err == SUCCESS) {
      dbg("radio_send", "Packet sent...");
      locked = 0;
      dbg_clear("radio_send", " at time %s \n", sim_time_string());
    }
    else{
      dbgerror("radio_send", "Send done error!");
    }
    
    if(call PacketAcknowledgements.wasAcked(&packet)){  //check if ack received
      //dbg("radio_ack", "ACK received \n");
      if(phase == 1) {
      	phase = 2;
      	dbgerror("radio_send", "Special packet acked!\n");
      	call MilliTimer.stop();
      }
      
      

      }
    else{
      
      if(phase == 0){
      	//nothing, will be sent again when timer fires
      	//sendKey();
      }
      if(phase == 1){
      	dbgerror("radio_ack", "ACK not received! Sending the special packet again...\n");
      	sendNextStep();
      }

      }
      
  }
	 
  

  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
		
	my_msg_key* msg = (my_msg_key*)payload;
	
	//PAIRING PHASE
	if(phase == 0 && TOS_NODE_ID != msg->sendAddress){
		
		if (len == sizeof(my_msg_key)) {
			
			//dbg("radio_rec", "Received pairing packet from %d\n", msg->sendAddress);
			
			//check if received key is same as stored one
			if( ((TOS_NODE_ID == 1 || TOS_NODE_ID == 2) && !strcmp((char*)msg->key, RK1) ) || ((TOS_NODE_ID == 3 || TOS_NODE_ID == 4) && !strcmp((char*)msg->key, RK2) ) ){
			
				dbg("radio_send", "Device succesfully paired with %d! Passing to next step\n", msg->sendAddress); 
				phase = 1; //next phase
				sendAddress = msg->sendAddress; //storing the address of the sending mote
				//call MilliTimer.stop();
				sendNextStep();
			}

			else{
				//dbg("radio_send", "Pairing error\n"); 
			}
		
			return buf;
		}
		}
		
		//phase where we need to receive the special message
		if((phase == 0 || phase == 1 || phase == 2) && len == sizeof(my_msg_next)){
			dbg("radio_send", "Received special message! Passing to next phase\n"); 
			phase = 2;
			call MilliTimer.stop();
			return buf;
		}

    /*
    dbg("radio_rec", "Received packet at time %s\n", sim_time_string());
    dbg("radio_pack"," Payload length %hhu \n", call Packet.payloadLength( buf ));
    dbg("radio_pack", ">>>Pack \n");
    dbg_clear("radio_pack","\t\t Payload Received\n" );
    dbg_clear("radio_pack", "\t\t type: %hhu \n ", msg->type);
    dbg_clear("radio_pack", "\t\t counter: %hhu \n", msg->counter);
	dbg_clear("radio_pack", "\t\t data: %hhu \n", msg->data);    
    */
    
    else{
    	return buf;
    }
    {
      dbgerror("radio_rec", "Receiving error \n");
    }	 
  }

  event void Read.readDone(error_t result, uint16_t data) {

	  my_msg_t* msg = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
	  if (msg == NULL || result != SUCCESS) {
		return;
	  }
	  msg->type = 1; //this means it is a RESP
	  msg->data = data;
	  msg->counter = counter;
	  dbg("radio_pack","Preparing the response with counter = %d \n", counter);
	  
	  call PacketAcknowledgements.requestAck(&packet);
	  
	  if(call AMSend.send(1, &packet,sizeof(my_msg_t)) == SUCCESS){
	     dbg("radio_send", "Packet passed to lower layer successfully!\n");
	     //dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	     //dbg_clear("radio_pack","\t Payload Sent\n" );
		 //dbg_clear("radio_pack", "\t\t type: %hhu \n ", msg->type);
		 //dbg_clear("radio_pack", "\t\t data: %hhu \n", msg->data);
		 //dbg_clear("radio_pack", "\t\t counter: %hhu \n", msg->counter);
		 
  	}	 
}
}

