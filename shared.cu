
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <iostream>
#include <algorithm>
cudaError_t addWithCuda(int *c, int width, int height, int size, int alive);

__global__ void addKernel(int* c, int* n, int width, int height, int* alive)
{
	int col = blockIdx.x*blockDim.x + threadIdx.x;
	int row = blockIdx.y*blockDim.y + threadIdx.y;
	if (row < width && col < width)
	{
		//Shared
		const int block = 42;
		__shared__ int temp[block][block];

		int x = threadIdx.y;
		int y = threadIdx.x;

		if (x < 32 && y < 32) {
			temp[x + 5][y + 5] = c[row*width + col];
			//gemisma shared
			if (x < 5)
			{
				if (row >= 5)
				{
					temp[x][y + 5] = c[(row - 5) * width + col];
				}
				else 
				{
					temp[x][y + 5] = 0;
				}
				if (y < 5  )
				{
					if ((row >= 5 && col >= 5))
					{
						temp[x][y] = c[(row - 5) * width + (col - 5)];
					}
					else 
					{
						temp[x][y] =0;
					}

				}
				else if (y >= 27)
				{
					if (row >= 5 && (col + 5) < width)
					{
						temp[x][y + 10] = c[(row - 5)* width + (col + 5)];
					}
					else {
						temp[x][y + 10] = 0;
					}

				}

			}
			else if (x >= 27 )
			{
				if ((row + 5) < width)
				{
					temp[x + 10][y + 5] = c[(row + 5) * width + col];
				}
				else {
					temp[x + 10][y + 5] = 0;
				}
				if (y < 5)
				{
					if (col >= 5 && row + 5 < width)
					{
						temp[x + 10][y] = c[(row + 5) * width + (col - 5)];
					}
					else {
						temp[x + 10][y] = 0;
					}

				}
				else if (y >= 27)
				{
					if (row + 5 < width && (col + 5) < width)
					{
						temp[x + 10][y + 10] = c[(row + 5) * width + (col + 5)];
					}
					else {
						temp[x + 10][y + 10] = 0;
					}

				}


			}

			if (y < 5 )
			{
				if (col >= 5) {
					temp[x + 5][y] = c[row*width + (col - 5)];
				}
				else {
					temp[x + 5][y] = 0;
				}
			}
			else if (y >= 27 )
			{
				if (col + 5 < width)
				{
					temp[x + 5][y + 10] = c[row*width + (col + 5)];
				}
				else {
					temp[x + 5][y + 10] = 0;
				}
			}


			//telos gemismatos
			__syncthreads();
			int alive_n = 0;
			int posx = x + 5;
			int posy = y + 5;
			for (int i = posx - 5; i <= posx + 5; i++)
			{
				for (int j = posy - 5; j <= posy + 5; j++)
				{
					if (i >= 0 && i < block && j >= 0 && j < block && !(i == posx && j == posy))
					{
						alive_n += temp[i][j];
					}
				}
			}
			if (alive_n >= 34 && alive_n <= 58)
			{
				if (alive_n <= 45 && temp[posx][posy] == 0)
				{
					n[row*width + col] = 1;
					atomicAdd(alive, 1);
				}
			}
			else
			{
				if (temp[posx][posy] == 1)
				{
					n[row*width + col] = 0;
					atomicSub(alive, 1);
				}
			}
		}
	}
}
int main()
{

	int arraySizex = 1024;
	int arraySizey = 1024;
	int alive = 0;
	int size = arraySizex * arraySizey;
	int* c = (int*)malloc(sizeof(int*) * size);

	for (int i = 0; i < arraySizex; i++)
	{
		for (int j = 0; j < arraySizey; j++)
		{
			if ((i + j) % 2 == 0) {
				c[i*arraySizex + j] = 1;
			}
			else {
				c[i*arraySizex + j] = 0;
			}
			//printf("%d ", c[i*arraySizex + j]);
			if (c[i*arraySizex + j] == 1)
			{
				alive++;
			}
		}
		//printf("\n");
	}
	printf("1 generation alive :%d and dead :%d \n", alive, size - alive);

	cudaError_t cudaStatus = addWithCuda(c, arraySizex, arraySizey, size, alive);
	cudaStatus = cudaDeviceReset();
	printf("Press Any Key to Continue\n");
	getchar();
	free(c);
	return 0;
}


cudaError_t addWithCuda(int *c, int width, int height, int size, int alive)
{
	clock_t tic = clock();
	dim3 threadsPerBlock(32, 32);
	dim3 numBlocks(width / threadsPerBlock.x, height / threadsPerBlock.y);
	cudaError_t cudaStatus;

	int* dev_c;
	int* dev_n;
	int* dev_alive;

	cudaStatus = cudaSetDevice(0);
	cudaStatus = cudaMalloc((void**)&dev_alive, sizeof(int));
	cudaStatus = cudaMemcpy(dev_alive, &alive, sizeof(int), cudaMemcpyHostToDevice);
	cudaStatus = cudaMalloc(&dev_c, size * sizeof(int));
	cudaStatus = cudaMemcpy(dev_c, c, size * sizeof(int), cudaMemcpyHostToDevice);
	cudaStatus = cudaMalloc(&dev_n, size * sizeof(int));
	cudaStatus = cudaMemcpy(dev_n, c, size * sizeof(int), cudaMemcpyHostToDevice);

	
	
	int generation = 2;
	int next_alive = 0;
	while (alive > 0 && (next_alive != alive))
	{
		next_alive = alive;
		addKernel << < numBlocks, threadsPerBlock >> > (dev_c, dev_n, width, height, dev_alive);
		cudaStatus = cudaMemcpy(&alive, dev_alive, sizeof(int), cudaMemcpyDeviceToHost);
		cudaStatus = cudaMemcpy(c, dev_n, size * sizeof(int), cudaMemcpyDeviceToHost);
		cudaStatus = cudaMemcpy(dev_c, c, size * sizeof(int), cudaMemcpyHostToDevice);
		cudaStatus = cudaDeviceSynchronize();


		//printf("%d generation : \n",generation);
		//for (int row = 0; row < width; row++){
		//for (int col = 0; col < height; col++){
		//printf("%d ", c[row * width + col]);

		//}
		//printf("\n");
		//}

		printf("%d generation alive :%d and dead:%d \n", generation, alive, size - alive);
		generation++;

	}
	clock_t toc = clock();

	printf("%d generations time elapsed: %f seconds\n",generation-1, (double)(toc - tic) / CLOCKS_PER_SEC);
	cudaFree(dev_c);
	cudaFree(dev_n);
	cudaFree(dev_alive);
	return cudaStatus;
}
