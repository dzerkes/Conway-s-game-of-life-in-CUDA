
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <iostream>
using namespace std;



void find_alive(){

}


int main(){

	int worldX, worldY;

	printf("Please enter the width of the array : ");
	scanf("%d", &worldX);

	printf("Please enter the height of the array : ");
	scanf("%d", &worldY);

	int population = worldX * worldY;
	int* world = (int*)malloc(sizeof(int*) * population);
	int* count = (int*)malloc(sizeof(int*) * population);
	int* state = (int*)malloc(sizeof(int*) * population);
	int alive = 0;

	// Random initial polulation
	srand(time(NULL));
	for (int row = 0; row < worldY; row++)
		for (int col = 0; col < worldX; col++){
			int rand_val = rand() % 2;
			world[row*worldX + col] = rand_val;
			if (rand_val) alive += 1;
		}
			
	cout << alive;
	memcpy(state, world, sizeof(int*) * population);
	int lowest = INT_MAX;
	while (alive > 0){
		
		// Calculate alive neighbours and print polulation
		for (int row = 0; row < worldY; row++){
			//cout << "| ";
			int tmp = 0;
			for (int col = 0; col < worldX; col++){

				for (int off_row = row - 5; off_row <= row + 5; off_row++){
					for (int off_col = col - 5; off_col <= col + 5; off_col++)
						if (!(off_row < 0 || off_row >= worldY || off_col < 0 || off_col >= worldX || (off_row == row && off_col == col))) //or substract itself
							tmp += world[off_row*worldX + off_col];//tmp = tmp;				
				}

				//cout << world[row * worldX + col] << " | ";
				count[row * worldX + col] = tmp;
				if (tmp >= 34 && tmp <= 58){
					if (tmp <= 45 && state[row * worldX + col] == 0){
						state[row * worldX + col] = 1;
						alive += 1;
					}

				}
				else {
					if (state[row * worldX + col] == 1){
						state[row * worldX + col] = 0;
						alive -= 1;
					}
					
				}
				tmp = 0;
			}

			//cout << "\n";
		}

		//cout << "\n\n\n";

		//for (int row = 0; row < worldY; row++){
		//	cout << "| ";
		//	for (int col = 0; col < worldX; col++){
		//		cout << count[row * worldX + col] << " | ";
		//	}
		//	cout << "\n";
		//}


		//cout << "\n\n\n";

		memcpy(world, state, sizeof(int*) * population);
		//for (int row = 0; row < worldY; row++){
		//	cout << "| ";
		//	for (int col = 0; col < worldX; col++){
		//		cout << world[row * worldX + col] << " | ";

		//	}
		//	cout << "\n";
		//}
		if (alive < lowest){
			cout << '\n' << alive;
			lowest = alive;
		}
	}

	
	
	






	return 0;
}
