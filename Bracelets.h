/**
 *  @author Luca Pietro Borsani
 */

#ifndef SENDACK_H
#define SENDACK_H

//payload of the msg
typedef nx_struct my_msg {
	nx_uint8_t type;
	nx_uint16_t data;
	nx_uint8_t counter;
} my_msg_t;


typedef nx_struct my_msg_keyt {
	nx_uint8_t sendAddress;
	nx_uint8_t key[21];
} my_msg_key;


typedef nx_struct my_msg_nextt {
	nx_uint8_t next;
} my_msg_next;

#define REQ 1
#define RESP 2 

enum{
AM_MY_MSG = 6,
};

  const char RK2[21] = "zbXlGndrOTvn9gGRCfj6";
  const char RK1[21] = "UhwZntvjzOEET7zG5D7M";

#endif
