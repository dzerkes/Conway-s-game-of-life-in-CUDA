
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <stdlib.h>
#include <time.h>


__global__ void t(int* world, int* state, int worldX, int worldY, int* a)
{
	int col = blockIdx.x*blockDim.x + threadIdx.x;
	int row = blockIdx.y*blockDim.y + threadIdx.y;


	if (row < worldY && col < worldX){
		int pos = row * worldX + col;
		int tmp = 0;

		for (int off_row = row - 5; off_row <= row + 5; off_row++){
			for (int off_col = col - 5; off_col <= col + 5; off_col++)
				if (!(off_row < 0 || off_row >= worldY || off_col < 0 || off_col >= worldX || (off_row == row && off_col == col))) //or substract itself
					tmp += world[off_row*worldX + off_col];//tmp = tmp;				
		}

		//cout << world[row * worldX + col] << " | ";

		if (tmp >= 34 && tmp <= 58){
			if (tmp <= 45 && state[pos] == 0){
				state[pos] = 1;
				atomicAdd(a, 1);
			}
		}
		else {
			if (state[pos] == 1){
				state[pos] = 0;
				atomicSub(a, 1);
			}
		}

		
	}
}

int main()
{
    
	int worldX;
	int worldY;
	int alive = 0;
	int* d_alive;

	printf("Please enter the width of the array : ");
	scanf("%d", &worldX);

	printf("Please enter the height of the array : ");
	scanf("%d", &worldY);

	printf("worldX : %d, worldY : %d\n", worldX, worldY);


    // Add vectors in parallel.
	//cudaError_t cudaStatus;
    //if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "addWithCuda failed!");
    //    return 1;
    //}

	int population = worldX * worldY;
	int* world = (int*)malloc(sizeof(int*) * population);

	srand(time(NULL));
	for (int i = 0; i < worldX; i++)
	{
		for (int j = 0; j < worldY; j++)
		{
			if ((i + j) % 2 == 0) {
				world[i*worldX + j] = 1;
			}
			else {
				world[i*worldX + j] = 0;
			}
			//printf("%d ", c[i*arraySizex + j]);
			if (world[i*worldX + j] == 1)
			{
				alive++;
			}
		}
		//printf("\n");
	}

	printf("%d", alive);
	printf("\n");


	//for (int row = 0; row < worldY; row++){
	//	printf("| ");
	//	for (int col = 0; col < worldX; col++){
	//		printf("%d | ", world[row * worldX + col]);

	//	}
	//	printf("\n ");
	//}

	printf("\n");

	cudaMalloc((void**)&d_alive, sizeof(int));
	cudaMemcpy(d_alive, &alive, sizeof(int), cudaMemcpyHostToDevice);

	int gridx = 16;
	int gridy = 16;
	dim3 grid((worldX / gridx) + 1, (worldY / gridy) + 1);
	dim3 blockSize(gridx, gridy);

	int* d_world;
	int* state;
	size_t size = sizeof(int*) * population;
	cudaMalloc(&d_world, size);
	cudaMemcpy(d_world, world, size, cudaMemcpyHostToDevice);
	cudaMalloc(&state, size);
	cudaMemcpy(state, world, size, cudaMemcpyHostToDevice);

	while (alive > 0)
	{
		t << < grid, blockSize >> >(d_world, state, worldX, worldY, d_alive);
		cudaMemcpy(world, state, size, cudaMemcpyDeviceToHost);
		cudaMemcpy(d_world, state, size, cudaMemcpyDeviceToDevice);
		cudaMemcpy(&alive, d_alive, sizeof(int), cudaMemcpyDeviceToHost);
		cudaDeviceSynchronize();

		//for (int row = 0; row < worldY; row++){
		//	printf("| ");
		//	for (int col = 0; col < worldX; col++){
		//		printf("%d | ", test[row * worldX + col]);

		//	}
		//	printf("\n ");
		//}

		printf("%d\n", alive);
	}
	
	cudaFree(d_world);
	free(world);
	return 0;
}
