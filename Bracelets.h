#ifndef BRACELET_H
#define BRACELET_H

//info messagge contain state coord x coord y
typedef nx_struct info_msg {
	double x;
	double y;
	nx_uint8_t status;
} info_msg_t;


typedef nx_struct my_msg_keyt {
	nx_uint8_t sendAddress;
	nx_uint8_t key[21];
} my_msg_key;


typedef nx_struct my_msg_nextt {
	nx_uint8_t next;
} my_msg_next;

 
#define STANDING 1
#define WALKING 2
#define RUNNING 3
#define FALLING 4

enum{
AM_MY_MSG = 6,
};

  const char RK2[21] = "zbXlGndrOTvn9gGRCfj6";
  const char RK1[21] = "UhwZntvjzOEET7zG5D7M";

#endif
