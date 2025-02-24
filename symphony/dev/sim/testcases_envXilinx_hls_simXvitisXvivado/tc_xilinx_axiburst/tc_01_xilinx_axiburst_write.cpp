#include "axi4_sqrt.hpp"
#include<iostream>
#include "sim_management_pkg.h"

SimManagementPkg s;
static const std::string ENTITY_STR =  "tc_01_xilinx_axiburst_write.cpp";
static int NUM_TEST = 3;
int test_err = 0;

int main()
{
    float in[50],out[50];
    int ct=0;
    int length=30;
    for(int i=0;i<length;i++)
        in[i]=(float)(i*i);
    axi4_sqrt(in,out,30);
    for(int i=0;i<length;i++)
    {
        if(out[i]==(float)i)
            ct++;
    }
    if(ct==length)
        std::cout<<"PASS 00"<<std::endl;
    else
        std::cout<<"FAIL"<<std::endl;


    // example pass/fail/etc. messages
    s.fPrintPass(ENTITY_STR, "pass message = %u", NUM_TEST);
    s.fPrintError(ENTITY_STR, "error message = %u", NUM_TEST);
    s.fPrintWarning(ENTITY_STR, "warning messahe = %u", NUM_TEST);
    s.fPrintMessage(ENTITY_STR, "just a messahe = %u", NUM_TEST);

    // end of TC, doens't break the compile flow
    s.fTestComplete();
    return 0; 

    // // uncomment if you want the error to break the compile flow, return 1 if there are errors in the TC
    // if (s.fTestComplete() == 0 )  { 
    //     return 0;         
    // } else {
    //     return 1;
    // }

}
