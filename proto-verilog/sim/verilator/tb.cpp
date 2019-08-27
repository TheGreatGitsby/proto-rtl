#include <stdlib.h>
#include "addressbook.pb-c.h"
#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char **argv)
{
   Verilated::commandArgs(argc, argv);

   Vtop * tb = new Vtop;

   Verilated::traceEverOn(true);
   VerilatedVcdC * trace = new VerilatedVcdC;
   tb->trace(trace, 99);
   trace->open("sim.vcd");

   uint32_t edge_cnt = 0;

   /*protobuf byte stream generation */

  Tutorial__Person person_1 = TUTORIAL__PERSON__INIT;
  person_1.name = "Bob";
  person_1.id = 10;
  person_1.n_phones = 0;
  Tutorial__Person person_2 = TUTORIAL__PERSON__INIT;
  person_2.name = "Peter";
  person_2.id = 20;
  person_2.n_phones = 0;

  _Tutorial__AddressBook msg = TUTORIAL__ADDRESS_BOOK__INIT; 
  msg.n_people = 2;
  Tutorial__Person *people[2] = {&person_1, &person_2};
  msg.people = people;

  unsigned len = tutorial__address_book__get_packed_size(&msg);
  
  void * buf = malloc(len);
  tutorial__address_book__pack(&msg,(uint8_t*)buf);
  
  fprintf(stderr,"Writing %d serialized bytes\n",len); // See the length of message
  
  uint32_t byte_count = 0;

   while(!Verilated::gotFinish())
   {

      tb->clk_i = 1;
      tb->eval();
      edge_cnt++;

      //do some rising edge stuff
         //default rising edge signals
      tb->protoStream_valid_i = 0;
      tb->protoStream_i = 0;

      if ((edge_cnt >= 5) && (byte_count < len))
      {
         tb->protoStream_valid_i = 1;
         tb->protoStream_i = ((uint8_t*)buf)[byte_count++];
      }
      

      if(edge_cnt < 1000)
         trace->dump(edge_cnt);

      tb->clk_i = 0;
      tb->eval();
      edge_cnt++;

      //do some falling edge stuff


      if(edge_cnt < 1000)
         trace->dump(edge_cnt);
      else
      {
         trace->close();
         exit(EXIT_SUCCESS); 
      }

   }

  free(buf); // Free the allocated serialized buffer

  exit(EXIT_SUCCESS); 
}
