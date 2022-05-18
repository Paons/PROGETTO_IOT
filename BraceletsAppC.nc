/**
 *  Configuration file for wiring of sendAckC module to other common 
 *  components needed for proper functioning
 *
 *  @author Luca Pietro Borsani
 */

#include "Bracelets.h"

configuration BraceletsAppC {}

implementation {


/****** COMPONENTS *****/
  components MainC, BraceletsC as App;
  //add the other components here
  
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components new TimerMilliC();
  components new FakeSensorC();
  components ActiveMessageC;

/****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;

  /****** Wire the other interfaces down here *****/
  
  
  
  //Send and Receive interfaces
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  
  //Radio Control
  //App.AMControl -> ActiveMessageC;
  App.PacketAcknowledgements -> ActiveMessageC;
  App.SplitControl -> ActiveMessageC;
  
  //Interfaces to access package fields
  App.Packet -> AMSenderC;
  
  //Timer interface
  App.MilliTimer -> TimerMilliC;
  
  //Fake Sensor read
  App.Read -> FakeSensorC;

}

