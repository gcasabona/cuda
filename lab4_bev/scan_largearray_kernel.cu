#ifndef _PRESCAN_CU_
#define _PRESCAN_CU_

// includes, kernels
#include <assert.h>


#define NUM_BANKS 32
#define LOG_NUM_BANKS 5
// Lab4: You can use any other block size you wish.
#define BLOCK_SIZE 256

// Lab4: Host Helper Functions (allocate your own data structure...)

__global__ void scan(float *g_odata, float *g_idata, const int n);
void prescanArray(float *outArray, float *inArray, int numElements);

// Lab4: Device Functions


// Lab4: Kernel Functions
// n: block size. one thread can handle two elements
__global__ void scan(float *g_odata, float *g_idata, const int n)
{





 	extern __shared__ float temp[]; // allocated on invocation: only needs to be as big as num threads in block

	int thid = threadIdx.x;	//thread id in block
	int gid = blockIdx.x*blockDim.x + thid;	//global id
	
	int offset = 1;


	
	//Loop all elements partitioned to a block in input array
		



	
	//Every thread handles two elements
	temp[2*thid] = g_idata[2*thid]; // load input into shared memory
        temp[2*thid+1] = g_idata[2*thid+1];

	// load input into shared memory.
 	// This is exclusive scan, so shift right by one and set first element to 0

	for (int d = n>>1; d > 0; d >>= 1) // build sum in place up the tree
 	{
 		__syncthreads();
 		if (thid < d)
 		{
			int ai = offset*(2*thid+1)-1;
 			int bi = offset*(2*thid+2)-1;
 			temp[bi] += temp[ai];
 		}
 		offset *= 2;
 	}
 	if (thid == 0) { temp[n - 1] = 0; } // clear the last element
 	for (int d = 1; d < n; d *= 2) // traverse down tree & build scan
 	{
 		offset >>= 1;
 		__syncthreads();
		 if (thid < d)
 		{
			int ai = offset*(2*thid+1)-1;
 			int bi = offset*(2*thid+2)-1;
 			float t = temp[ai];
 			temp[ai] = temp[bi];
 			temp[bi] += t;
 		}
 	}
 	__syncthreads();
 	g_odata[2*thid] = temp[2*thid]; // write results to device memory
 	g_odata[2*thid+1] = temp[2*thid+1];


}


	
	

// **===-------- Lab4: Modify the body of this function -----------===**
// You may need to make multiple kernel calls, make your own kernel
// function in this file, and then call them from here.
void prescanArray(float *outArray, float *inArray, int numElements)
{
	// Divide input array into blocks
	// Remember that each thread can handle two elements
	// BLOCK_SIZE is set above as a constnt
//	int numBlocks = ceil(numElements/BLOCK_SIZE);
	
	// Allocate global device memory for arrays to communicate sum data
//	cudaMalloc(


//	int nepb = num_elements/gridDim.x; //assuming input array is a power of 2 already
	

	dim3 dimGrid(1);
	dim3 dimBlock(BLOCK_SIZE);
	
	//BEV: added all below this point
	//dim3 dimGrid(numBlocks);
	//dim3 dimBlock(BLOCK_SIZE);
    	scan<<<dimGrid, dimBlock, 2*sizeof(float)*numElements+1>>>(outArray, inArray, numElements);
	//scan<<<dimGrid, dimBlock, 2*sizeof(float)*numElements+1>>>(outArray, inArray, BLOCK_SIZE); 
    
}
// **===-----------------------------------------------------------===**


#endif // _PRESCAN_CU_
