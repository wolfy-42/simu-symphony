#include "axi4_sqrt.hpp"
#include<string.h>
#include<math.h>

#define SIZE 100

void axi4_sqrt(float *in,float *out,int len)
{
#pragma HLS INTERFACE s_axilite port=return bundle=sqrt
#pragma HLS INTERFACE s_axilite port=len bundle=sqrt
#pragma HLS INTERFACE m_axi depth=100 port=out offset=slave bundle=output
#pragma HLS INTERFACE m_axi depth=100 port=in offset=slave bundle=input

	float buff[SIZE];
	memcpy(buff,(const float*)in,len*sizeof(float));
	for(int i=0;i<len;i++)
		buff[i]=sqrt(buff[i]);

	memcpy(out,(const float*)buff,len*sizeof(float));
}
