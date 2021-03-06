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
	interface Timer<TMilli> as Timer0;
	interface Timer<TMilli> as Timer1;
	interface Timer<TMilli> as Timer2;
	
	interface Read<sensor_status_t>;
  }

} implementation {

  uint32_t last_x;
  uint32_t last_y;
  uint8_t phase = PARING;
  uint8_t sendAddress;
  uint8_t locked = 0;
  
  message_t packet;

  void sendKey(uint8_t type);
  void alert(uint8_t type);
  
  void alert(uint8_t type){
  	//per essere carino** se viene chiamato l'alert facciamo stoppare il timer per evitare i messaggi di missing continui 
  	//facciamo qualcosa di speciale tipo accendere i led o display di un messaggio speciale
  	//tanto una volta che riceviamo l'info message il timer riprende quindi siamo a posto (questo vuol dire che il bambino si è rialzato o è rientrato nel range)
  	if(type == MISSING){
  		dbg("radio_send", "MISSING ALERT!!! Last seen at: %d, %d\n", last_x, last_y);
  		call Timer1.stop();
  	}
  	
  	if(type == FALLING){
  		dbg("radio_send", "FALLING ALERT!!! Position: %d, %d\n", last_x, last_y);
  	}
  }
 
  
  void sendKey(uint8_t type){
  
  if(!locked){
  	
	  my_msg_key_t* msg = (my_msg_key_t*)(call Packet.getPayload(&packet, sizeof(my_msg_key_t)));
	  if (msg == NULL) {
		return;
	  }
	   
	  //saving the address of the mote
	  msg->sendAddress = TOS_NODE_ID;
	  
	  msg->type = type;

	  //first couple of bracelets
	  if (TOS_NODE_ID == 1 || TOS_NODE_ID == 2){
	  	strcpy((char*)msg->key, RK1);

	  }
	  //second couple of bracelets
	  else{
	  	strcpy((char*)msg->key, RK2);
	  }
	  
	  //call PacketAcknowledgements.requestAck( &packet );
	  if(type == PARING){
	  
	  if(call AMSend.send(AM_BROADCAST_ADDR, &packet,sizeof(my_msg_key_t)) == SUCCESS){
	     //dbg("radio_send", "Packet for pairing passed to lower layer successfully!\n"); 
	     locked = 1;
  	  }	
  	  
  	  }
  	  else{
  	  
  	  call PacketAcknowledgements.requestAck( &packet );
	  if(call AMSend.send(sendAddress, &packet,sizeof(my_msg_key_t)) == SUCCESS){
	     //dbg("radio_send", "Packet for next step passed to lower layer successfully!\n"); 
	     locked = 1;
  	  }	
  	  
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
    	call Timer0.startPeriodic( 1000 );	//call timer for paring
    }
    else{
	dbg("radio", "Radio error!\n");
	call SplitControl.start();
    }
  }
  
  event void SplitControl.stopDone(error_t err){

  }


  event void Timer0.fired() {

	 dbg("timer","Pairing timer fired at %s.\n", sim_time_string());
	 sendKey(PARING);
  }
  
  event void Timer1.fired() { //parent timer --> when fired ALERT MISSING

	 dbg("timer","Missing timer fired at %s.\n", sim_time_string());
	 alert(MISSING);
	
  }
  
  
  event void Timer2.fired() { //child timer --> when fired take the values from sensors

	 dbg("timer","Child timer fired at %s.\n", sim_time_string());
	 call Read.read();

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
      
      if(phase == NEXTSTEP) { //if we send the nextstep message and we received the ack
      	phase = OPERATING;
      	if(TOS_NODE_ID %2 == 0)	call Timer2.startPeriodic( 10000 ); //10 sec 
      	else call Timer1.startPeriodic( 60000 ); // 60 sec 
      	dbg("radio_send", "Special packet acked! Passing to next step...\n");
      }
      else{ //phase can be only operating
      	//dbg("radio_send", "infomessage acked!\n");
      }      

      }
    else{
  
      if(phase == NEXTSTEP){
      	dbgerror("radio_ack", "ACK not received! Sending the special packet again...\n");
      	sendKey(NEXTSTEP); //#comment mettere una sleep prima di procedere per non inviare troppi pacchetti waste energy
      }
      else if(phase == OPERATING){
      
      dbgerror("radio_ack", "info message ACK not received!\n"); //we send an other info message when timer fires again
      //call Read.read();
      }
      }
      
  }
	 
  

  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
		
    
    if (len == sizeof(my_msg_key_t)){ //#comment può essere sia broadcast o unicast (PARING || NEXTSTEP) 
    	
    	my_msg_key_t* msg = (my_msg_key_t*)payload;
    	
    	 //#comment riceviamo un messaggio di tipo paring c'è solo un caso se siamo in paring mode ok se siamo in next mode non ci serve siamo a posto
    	
    		if(((TOS_NODE_ID == 1 || TOS_NODE_ID == 2) && !strcmp((char*)msg->key, RK1) ) || ((TOS_NODE_ID == 3 || TOS_NODE_ID == 4) && !strcmp((char*)msg->key, RK2) ) ){ //#comment il check delle chievi è sempre vitale 
			
				
				 
				
				if(phase == PARING){ //se siamo in paring qualsiasi tipo di messaggio ci arriva andiamo in next
				dbg("radio_send", "Device succesfully paired with %d\n", msg->sendAddress); 
				phase = NEXTSTEP;//next phase
				sendAddress = msg->sendAddress; //storing the address of the sending mote	
				call Timer0.stop(); //we can stop here the first timer because if the message is not acked it remain in the loop of function sendnextstep and senddone
				sendKey(NEXTSTEP);
    	
    			}
   			 	else if(phase==NEXTSTEP && msg->type == NEXTSTEP){ //#comment se siamo in next step e riceviamo un nextstep andiamo in operating viceversa se riceviamo l'ack e siamo in nextstep 		
   			 	dbg("radio_send", "Received special packet! Passing to next step\n"); 
   			 	phase = OPERATING;
   			 	if(TOS_NODE_ID %2 == 0)	call Timer2.startPeriodic( 10000 ); //10 sec
   			 	else call Timer1.startPeriodic( 60000 ); // 60 sec 
    	
  			  	}
  			  	else if (phase == OPERATING && msg->type == PARING)  //when the child bracelet return into the range
  			  		sendKey(NEXTSTEP); 	
				
			}
			else{ // #comment caso anormale perché ci sono +4 nodi
				//dbg("radio_send", "Pairing error\n"); 
			}
    	}
 
   else if (len == sizeof(my_info_msg_t)){ //#comment se riceviamo un messaggio di tipo info controlliamo se contiene falling chiamiamo una funzione alert(FALLING) che fa qualcosa se no facciamo il display normale dello stato?
		
		my_info_msg_t* msg = (my_info_msg_t*)payload;
		
		if(TOS_NODE_ID%2 != 0){
		last_x=msg->x;
  		last_y=msg->y;
  		call Timer1.startPeriodic( 60000 ); //#comment in teoria richiamandolo dovrebbe resettarsi (fa il replace) 
  		if(msg->status == FALLING) {
  			dbg("radio_rec", "Received INFO: %d, %d, FALLING\n", last_x, last_y);
  			alert(FALLING);
  		}
  		
		//dbg("radio_rec", "Received INFO: %d, %d, %d\n", last_x, last_y, msg->status);
		if(msg->status == STANDING) dbg("radio_rec", "Received INFO: %d, %d, STANDING\n", last_x, last_y);
		if(msg->status == WALKING) dbg("radio_rec", "Received INFO: %d, %d, WALKING\n", last_x, last_y);
		if(msg->status == RUNNING) dbg("radio_rec", "Received INFO: %d, %d, RUNNING\n", last_x, last_y);
		}
    	
    	}
    
    else{
    	dbgerror("radio_rec", "Receiving error \n");
	}
	return buf;
    
  }

  event void Read.readDone(error_t result, sensor_status_t data) {

	  my_info_msg_t* msg = (my_info_msg_t*)(call Packet.getPayload(&packet, sizeof(my_info_msg_t)));
	  if (msg == NULL || result != SUCCESS) {
		return;
	  }
	   
	  //msg->x = 38946875;
	  msg->x = data.x;
	  //msg->y = 16641260;
	  msg->y = data.y;
	  msg->status = data.status;
	  
	  call PacketAcknowledgements.requestAck(&packet);
	  
	  if(call AMSend.send(sendAddress, &packet,sizeof(my_info_msg_t)) == SUCCESS){
	     //dbg("radio_send", "Packet passed to lower layer successfully!\n");
	     //dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	     //dbg_clear("radio_pack","\t Payload Sent\n" );
		 //dbg_clear("radio_pack", "\t\t type: %hhu \n ", msg->type);
		 //dbg_clear("radio_pack", "\t\t data: %hhu \n", msg->data);
		 //dbg_clear("radio_pack", "\t\t counter: %hhu \n", msg->counter);
		 
  	}	 
}
}

