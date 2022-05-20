#ifndef BRACELET_H
#define BRACELET_H

//info messagge contain state coord x coord y
typedef nx_struct my_info_msg {
	nx_uint32_t x;
	nx_uint32_t y;
	nx_uint8_t status;
} my_info_msg_t;


typedef nx_struct my_msg_key {
	nx_uint8_t type;	
	nx_uint8_t sendAddress;
	nx_uint8_t key[21];
} my_msg_key_t;


//statuts of child
#define STANDING 1
#define WALKING 2
#define RUNNING 3
#define FALLING 4
//operating mode
#define PARING 0
#define NEXTSTEP 1
#define OPERATING 2

#define MISSING 5

enum{
AM_MY_MSG = 6,
};

  const char RK2[21] = "zbXlGndrOTvn9gGRCfj6";
  const char RK1[21] = "UhwZntvjzOEET7zG5D7M";

#endif
